#!/bin/bash
#
#==============================================================================
# GitLab Public Repository Monitor
#
# Auteur:   Joachim COQBLIN + un peu de LLM
# Licence:  AGPLv3
# Version:  2.5.9
#
#==============================================================================

# Exit on unset variables and pipeline errors, but not on individual command errors
set -uo pipefail

#===[ Global Variables ]===#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.conf"
TRACKING_FILE="${SCRIPT_DIR}/tracked_repos.txt"
LOG_FILE="${SCRIPT_DIR}/gitlab-monitor.log"
DRY_RUN=false
DEBUG_MODE=false

#===[ Colors for logs ]===#
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

#==============================================================================
# Utility Functions
#==============================================================================

log() {
    local level="$1"; shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    # ALWAYS log to stderr to not interfere with command substitutions
    # tee will still write to the log file.
    (echo -e "${timestamp} [${level}] ${message}" | tee -a "${LOG_FILE}") >&2
}

log_info() { log "${BLUE}INFO${NC}" "$@"; }
log_warn() { log "${YELLOW}WARN${NC}" "$@"; }
log_error() { log "${RED}ERROR${NC}" "$@"; }
log_success() { log "${GREEN}SUCCESS${NC}" "$@"; }

#==============================================================================
# Prerequisite Checks & Config Loading
#==============================================================================

load_config_and_check_deps() {
    if [[ ! -f "$CONFIG_FILE" ]]; then log_error "Fichier de configuration introuvable: $CONFIG_FILE"; exit 1; fi
    source "$CONFIG_FILE"
    
    local required_vars=("GITLAB_URL" "EMAIL_TO" "EMAIL_FROM" "NOTIFICATION_LANGUAGE")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then log_error "Variable de configuration manquante: $var"; exit 1; fi
    done

    local deps=("curl" "jq" "sendmail")
    if [[ -n "${SMTP_SERVER:-}" ]]; then deps=("curl" "jq"); fi
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then log_error "Dépendance manquante: ${dep}"; exit 1; fi
    done
}

#==============================================================================
# GitLab API Functions
#==============================================================================

get_public_projects_from_api() {
    log_info "Récupération des projets publics via l'API..."
    local api_url="${GITLAB_URL}/api/v4/projects?visibility=public&order_by=last_activity_at&sort=desc&per_page=100"
    local response
    response=$(curl -s --connect-timeout "${API_TIMEOUT:-30}" "$api_url")
    if ! echo "$response" | jq empty 2>/dev/null; then
        log_error "Réponse de l'API invalide."
        echo "[]" # Return empty JSON array on error
    else
        log_info "Trouvé $(echo "$response" | jq 'length') projets publics."
        echo "$response" # Return pure JSON on success
    fi
}

get_last_committer() {
    local project_id="$1"
    local api_url="${GITLAB_URL}/api/v4/projects/${project_id}/repository/commits?per_page=1"
    local response
    response=$(curl -s --connect-timeout "${API_TIMEOUT:-30}" "$api_url")
    if echo "$response" | jq -e '.[0].author_name' > /dev/null 2>&1; then
        echo "$response" | jq -r '.[0].author_name'
    else
        echo "N/A"
    fi
}

check_files_via_git_clone() {
    local repo_http_url="$1"
    local temp_dir; temp_dir=$(mktemp -d)
    
    log_info "Clonage superficiel de ${repo_http_url}..."
    if git clone --depth 1 --quiet "$repo_http_url" "$temp_dir"; then
        local license_status="❌"
        local readme_status="❌"
        local contributing_status="❌"
        
        if [[ -f "${temp_dir}/LICENSE" ]]; then license_status="✅"; fi
        if [[ -f "${temp_dir}/README.md" ]]; then readme_status="✅"; fi
        if [[ -f "${temp_dir}/CONTRIBUTING.md" ]]; then contributing_status="✅"; fi
        
        echo "$license_status $readme_status $contributing_status"
    else
        log_error "Échec du clonage de ${repo_http_url}"
        echo "❌ ❌ ❌"
    fi
    
    rm -rf "$temp_dir"
}

#==============================================================================
# Tracking Management
#==============================================================================

is_repo_tracked() {
    [[ -f "$TRACKING_FILE" ]] && grep -q "^$1$" "$TRACKING_FILE"
}

add_to_tracking() {
    echo "$1" >> "$TRACKING_FILE"
}

#==============================================================================
# Email Generation & Sending
#==============================================================================

send_email() {
    local subject="$1"
    local repo_name="$2"
    local repo_dev="$3"
    local repo_url="$4"
    local has_license="$5"
    local has_readme="$6"
    local has_contributing="$7"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY-RUN: Notification pour '$repo_name' non envoyée."
        return 0
    fi

    local email_content
    email_content=$(cat <<EOF
To: $EMAIL_TO
From: $EMAIL_FROM
Subject: =?UTF-8?B?$(echo -n "$subject" | base64 -w 0)?=
Content-Type: text/html; charset=UTF-8
MIME-Version: 1.0

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
    body { font-family: sans-serif; line-height: 1.6; margin: 20px; color: #333; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; font-weight: bold; }
    h3 { color: #d9534f; border-bottom: 1px solid #eee; padding-bottom: 5px; }
    hr { border: 0; border-top: 1px solid #eee; margin: 20px 0; }
    ul { padding-left: 20px; }
    li { margin-bottom: 5px; }
</style>
</head>
<body>
    <p>Bonjour, nous avons détecté la présence d'un dépôt Gitlab accessible publiquement.</p>
    <p>C'est la première détection de ce dépôt et <strong>vous ne serez plus notifié à l'avenir.</strong></p>
    <table>
        <tr><th>Nom du dépôt:</th><td>$repo_name</td></tr>
        <tr><th>Dernier commit par:</th><td>$repo_dev</td></tr>
        <tr><th>Publié à l'adresse:</th><td><a href="$repo_url">$repo_url</a></td></tr>
        <tr><th>Présence d'une licence:</th><td>$has_license</td></tr>
        <tr><th>Présence d'une documentation:</th><td>$has_readme</td></tr>
        <tr><th>Présence d'un guide de contribution:</th><td>$has_contributing</td></tr>
    </table>
    <hr>
    <h3>⚠️ Avertissement Important concernant les Dépôts Publics</h3>
    <p>Pour les dépôts accessible publiquement sur Internet, il est <strong>impératif</strong> de respecter les règles suivantes :</p>
    <ul>
        <li><strong>Aucune Information Sensible :</strong> Les scripts ne doivent contenir aucun nom, IP, secret ou information spécifique à notre organisation.</li>
        <li><strong>Code Générique :</strong> Seuls les scripts généralistes et réutilisables sont éligibles.</li>
        <li><strong>Licence AGPLv3 :</strong> Tout projet public doit être sous cette licence.</li>
        <li><strong>Fichiers de Contribution et Documentation :</strong> 
            <code>CONTRIBUTING.md</code> et 
            <code>README.md</code> doivent être présents et de qualité.</li>
    </ul>
    <p>Le non-respect de ces règles peut entraîner des risques de sécurité majeurs.</p>
</body>
</html>
EOF
)

    if [[ -n "${SMTP_SERVER:-}" ]]; then
        log_info "Utilisation du serveur SMTP ($SMTP_SERVER)..."
        echo -e "$email_content" | curl -s --url "smtp://${SMTP_SERVER}:${SMTP_PORT:-25}" --mail-from "$EMAIL_FROM" --mail-rcpt "$EMAIL_TO" --upload-file -
    else
        log_info "Utilisation de sendmail..."
        echo -e "$email_content" | sendmail -t
    fi

    if [[ $? -eq 0 ]]; then log_success "Email envoyé pour '$repo_name'."; return 0;
    else log_error "Échec de l'envoi de l'email pour '$repo_name'."; return 1; fi
}

#==============================================================================
# Main Logic
#==============================================================================

process_project() {
    local project_json="$1"
    local repo_id; repo_id=$(echo "$project_json" | jq -r '.id')

    if is_repo_tracked "$repo_id"; then
        return 0 # Not a new repo, success.
    fi

    log_info "Nouveau dépôt détecté: $(echo "$project_json" | jq -r '.name')"
    
    local repo_name; repo_name=$(echo "$project_json" | jq -r '.name')
    local repo_url; repo_url=$(echo "$project_json" | jq -r '.web_url')
    local repo_http_url; repo_http_url=$(echo "$project_json" | jq -r '.http_url_to_repo')
    local repo_dev; repo_dev=$(get_last_committer "$repo_id")

    # Check for files using git clone
    local file_statuses; file_statuses=$(check_files_via_git_clone "$repo_http_url")
    read -r has_license has_readme has_contributing <<< "$file_statuses"
    
    # Prepare subject
    local subject_template_var="EMAIL_SUBJECT_${NOTIFICATION_LANGUAGE}"
    local subject_template="${!subject_template_var}"
    local subject="${subject_template//\$REPONAME/$repo_name}"
    
    if send_email "$subject" "$repo_name" "$repo_dev" "$repo_url" "$has_license" "$has_readme" "$has_contributing"; then
        if [[ "$DRY_RUN" == "false" ]]; then
            add_to_tracking "$repo_id"
        fi
        return 0 # Success
    else
        return 1 # Failure
    fi
}

main() {
    log_info "=== Début du monitoring GitLab (v2.5.9 API) ==="
    load_config_and_check_deps
    touch "$TRACKING_FILE"
    
    local public_projects_json; public_projects_json=$(get_public_projects_from_api)
    local project_count; project_count=$(echo "$public_projects_json" | jq 'length')
    
    if [[ "$project_count" -eq 0 ]]; then log_info "Aucun projet public trouvé."; exit 0; fi
    
    log_info "Analyse de ${project_count} projets..."
    local new_repo_count=0
    
    for i in $(seq 0 $((project_count - 1))); do
        local project_data; project_data=$(echo "$public_projects_json" | jq -c ".[${i}]")
        if process_project "$project_data"; then
            # Only increment if it was a new, successfully processed repo
            if ! is_repo_tracked "$(echo "$project_data" | jq -r '.id')"; then
                 ((new_repo_count++))
            fi
        else
            log_warn "Échec du traitement pour le projet $(echo "$project_data" | jq -r .name). Passage au suivant."
        fi
    done

    if [[ $new_repo_count -eq 0 ]]; then
        log_info "Aucun nouveau dépôt à notifier."
    else
        log_success "$new_repo_count nouveaux dépôts traités."
    fi
    
    log_info "=== Fin du monitoring GitLab. ==="
}

#==============================================================================
# Entry Point
#==============================================================================

# Parse arguments after functions are defined
for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --debug)
      DEBUG_MODE=true
      LOG_FILE="${SCRIPT_DIR}/gitlab-monitor_$(date +%Y%m%d-%H%M%S).log"
      # Redirect stderr to a process substitution that tees to the log file
      exec 2> >(tee -a "${LOG_FILE}")
      set -x
      shift
      ;;
  esac
done

main
