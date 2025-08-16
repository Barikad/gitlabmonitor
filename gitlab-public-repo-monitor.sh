#!/bin/bash
#
#==============================================================================
# GitLab Public Repository Monitor
#
# Auteur:   Joachim COQBLIN + un peu de LLM
# Licence:  AGPLv3
# Version:  2.7.0
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

#===[ Bilingual Messages ]===#
MSG_KNOWN_REPO_FR="Dépôt connu (ID: %s), on ne fait rien : %s"
MSG_KNOWN_REPO_EN="Known repository (ID: %s), skipping: %s"
MSG_MAILING_TO_FR="Envoi de lEmail à: %s"
MSG_MAILING_TO_EN="Mailing to: %s"

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
    log_info "Récupération des projets publics via lAPI..."
    local api_url="${GITLAB_URL}/api/v4/projects?visibility=public&order_by=last_activity_at&sort=desc&per_page=100"
    local response
    response=$(curl -s --connect-timeout "${API_TIMEOUT:-30}" "$api_url")
    if ! echo "$response" | jq empty 2>/dev/null; then
        log_error "Réponse de lAPI invalide."
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
    
    # Return both name and email, separated by a newline
    if echo "$response" | jq -e '.[0].author_name' > /dev/null 2>&1; then
        echo "$response" | jq -r '.[0].author_name'
        echo "$response" | jq -r '.[0].author_email'
    else
        echo "N/A"
        echo "" # Empty email
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
    local repo_dev_email="$8"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY-RUN: Notification pour '$repo_name' non envoyée."
        return 0
    fi

    local recipients="$EMAIL_TO"
    if [[ "${CC_COMMIT_AUTHOR:-false}" == "true" && -n "$repo_dev_email" ]]; then
        recipients="$recipients,$repo_dev_email"
    fi

    local msg_var="MSG_MAILING_TO_${NOTIFICATION_LANGUAGE}"
    log_info "$(printf "${!msg_var}" "$recipients")"

    local lang_code="${NOTIFICATION_LANGUAGE,,}"
    local template_file="${SCRIPT_DIR}/template.${lang_code}.md"
    if [[ ! -f "$template_file" ]]; then
        log_error "Template file not found: $template_file"
        return 1
    fi
    local email_body_content; email_body_content=$(cat "$template_file")

    # Replace placeholders
    email_body_content="${email_body_content//\$REPONAME/$repo_name}"
    email_body_content="${email_body_content//\$REPODEV/$repo_dev}"
    email_body_content="${email_body_content//\$REPOURL/$repo_url}"
    email_body_content="${email_body_content//\$HAS_LICENSE/$has_license}"
    email_body_content="${email_body_content//\$HAS_README/$has_readme}"
    email_body_content="${email_body_content//\$HAS_CONTRIBUTING/$has_contributing}"

    # Construct the full HTML body
    local email_body
    email_body=$(cat <<EOF
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
    li { margin-bottom: 10px; }
    code { background-color: #eee; padding: 2px 4px; border-radius: 3px; }
    .footer { margin-top: 20px; padding-top: 10px; border-top: 1px solid #eee; font-size: 0.9em; color: #777; }
</style>
</head>
<body>
${email_body_content}
<div class="footer">
    Email généré par <a href="https://gitlab.villejuif.fr/depots-public/gitlabmonitor">GitLabMonitor</a>.
</div>
</body>
</html>
EOF
)

    local encoded_subject="=?UTF-8?B?$(echo -n "$subject" | base64 -w 0)?="
    
    local email_headers
    email_headers=$(cat <<EOF
To: $EMAIL_TO
From: $EMAIL_FROM
Subject: $encoded_subject
Content-Type: text/html; charset=UTF-8
MIME-Version: 1.0
EOF
)
    if [[ "${CC_COMMIT_AUTHOR:-false}" == "true" && -n "$repo_dev_email" ]]; then
        email_headers+=$'\n''Cc: '$repo_dev_email
    fi

    local email_content="${email_headers}"$''$''\n\n"${email_body}"

    if [[ -n "${SMTP_SERVER:-}" ]]; then
        log_info "Utilisation du serveur SMTP ($SMTP_SERVER)..."
        local curl_recipients=()
        curl_recipients+=("--mail-rcpt" "$EMAIL_TO")
        if [[ "${CC_COMMIT_AUTHOR:-false}" == "true" && -n "$repo_dev_email" ]]; then
            curl_recipients+=("--mail-rcpt" "$repo_dev_email")
        fi
        echo -e "$email_content" | curl -s --url "smtp://${SMTP_SERVER}:${SMTP_PORT:-25}" \
            --mail-from "$EMAIL_FROM" \
            "${curl_recipients[@]}" \
            --upload-file -
    else
        log_info "Utilisation de sendmail..."
        echo -e "$email_content" | sendmail -t
    fi

    if [[ $? -eq 0 ]]; then log_success "Email envoyé pour '$repo_name'."; return 0;
    else log_error "Échec de lEnvoi de lEmail pour '$repo_name'."; return 1; fi
}



#==============================================================================
# Main Logic
#==============================================================================

process_project() {
    local project_json="$1"
    local repo_id; repo_id=$(echo "$project_json" | jq -r '.id')

    if is_repo_tracked "$repo_id"; then
        local msg_var="MSG_KNOWN_REPO_${NOTIFICATION_LANGUAGE}"
        log_info "$(printf "${!msg_var}" "$repo_id" "$(echo "$project_json" | jq -r '.name')")"
        return 0 # Not a new repo, success.
    fi

    log_info "Nouveau dépôt détecté: $(echo "$project_json" | jq -r '.name')"
    
    local repo_name; repo_name=$(echo "$project_json" | jq -r '.name')
    local repo_url; repo_url=$(echo "$project_json" | jq -r '.web_url')
    local repo_http_url; repo_http_url=$(echo "$project_json" | jq -r '.http_url_to_repo')
    
    # Read committer info into separate variables
    local committer_info; committer_info=$(get_last_committer "$repo_id")
    local repo_dev; repo_dev=$(echo "$committer_info" | head -n 1)
    local repo_dev_email; repo_dev_email=$(echo "$committer_info" | tail -n 1)

    # Check for files using git clone
    local file_statuses; file_statuses=$(check_files_via_git_clone "$repo_http_url")
    read -r has_license has_readme has_contributing <<< "$file_statuses"
    
    # Prepare subject
    local subject_template_var="EMAIL_SUBJECT_${NOTIFICATION_LANGUAGE}"
    local subject_template="${!subject_template_var}"
    local subject="${subject_template//\$REPONAME/$repo_name}"
    
    if send_email "$subject" "$repo_name" "$repo_dev" "$repo_url" "$has_license" "$has_readme" "$has_contributing" "$repo_dev_email"; then
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