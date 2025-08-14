#!/bin/bash
#
#==============================================================================
# GitLab Public Repository Monitor
#
# Auteur:   Joachim COQBLIN + un peu de LLM
# Licence:  AGPLv3
# Version:  2.3.0
# URL:      https://gitlab.villejuif.fr/depots-public/gitlabmonitor
#
# Description (FR):
# Ce script utilise l'API GitLab pour surveiller les nouveaux dépôts publics
# et envoie une notification par email au format HTML propre.
#
# Description (EN):
# This script uses the GitLab API to monitor for new public repositories
# and sends a clean HTML-formatted email notification.
#
#==============================================================================

set -euo pipefail

#===[ Global Variables ]===#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.conf"
TRACKING_FILE="${SCRIPT_DIR}/tracked_repos.txt"
LOG_FILE="${SCRIPT_DIR}/gitlab-monitor.log"
DRY_RUN=false

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
    echo -e "${timestamp} [${level}] ${message}" | tee -a "${LOG_FILE}"
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
    log_info >&2 "Récupération des projets publics via l'API..."
    local api_url="${GITLAB_URL}/api/v4/projects?visibility=public&order_by=last_activity_at&sort=desc&per_page=100"
    local response
    response=$(curl -s --connect-timeout "${API_TIMEOUT:-30}" "$api_url")
    if ! echo "$response" | jq empty 2>/dev/null; then
        log_error >&2 "Réponse de l'API invalide."
        echo "[]"
    else
        log_info >&2 "Trouvé $(echo "$response" | jq 'length') projets publics."
        echo "$response"
    fi
}

get_last_committer() {
    local project_id="$1"
    local api_url="${GITLAB_URL}/api/v4/projects/${project_id}/repository/commits?per_page=1"
    local response
    response=$(curl -s --connect-timeout "${API_TIMEOUT:-30}" "$api_url")
    if echo "$response" | jq -e '.[0].author_name' > /dev/null; then
        echo "$response" | jq -r '.[0].author_name'
    else
        echo "N/A"
    fi
}

check_file_exists() {
    local project_path_with_namespace="$1"
    local file_path="$2"
    local encoded_project_path
    encoded_project_path=$(echo "$project_path_with_namespace" | jq -sRr @uri)
    local status_code
    status_code=$(curl -s -o /dev/null -w "%{{http_code}}" "${GITLAB_URL}/api/v4/projects/${encoded_project_path}/repository/files/${file_path}?ref=main")
    if [[ "$status_code" == "200" ]]; then echo "✅"; return; fi
    status_code=$(curl -s -o /dev/null -w "%{{http_code}}" "${GITLAB_URL}/api/v4/projects/${encoded_project_path}/repository/files/${file_path}?ref=master")
    if [[ "$status_code" == "200" ]]; then echo "✅"; else echo "❌"; fi
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

markdown_to_html() {
    local markdown_text="$1"
    local html=""
    local in_table=false

    while IFS= read -r line; do
        if [[ "$line" == *"|"* && "$in_table" == false ]]; then
            in_table=true
            html+="<table>\n"
            # Header row
            local header_line="<tr>"
            while IFS='|' read -ra cols; do
                for col in "${cols[@]}"; do
                    header_line+="<th>${col// /}</th>"
                done
            done <<< "$line"
            header_line+="</tr>\n"
            html+="$header_line"
        elif [[ "$line" == *"|---"* && "$in_table" == true ]]; then
            continue
        elif [[ "$line" == *"|"* && "$in_table" == true ]]; then
            # Data row
            local data_line="<tr>"
            while IFS='|' read -ra cols; do
                for col in "${cols[@]}"; do
                    data_line+="<td>${col// /}</td>"
                done
            done <<< "$line"
            data_line+="</tr>\n"
            html+="$data_line"
        elif [[ "$line" != *"|"* && "$in_table" == true ]]; then
            in_table=false
            html+="</table>\n"
            html+="${line}<br>\n"
        else
            line=$(echo "$line" | sed 's|### \(.*\)|\n<h3>\1</h3>|g' | sed 's|\*\*\([^*]*\)\*\*|<strong>\1</strong>|g' | sed 's|---| <hr>|g')
            html+="${line}<br>\n"
        fi
    done <<< "$markdown_text"

    if [[ "$in_table" == true ]]; then
        html+="</table>\n"
    fi
    echo "$html"
}

send_email() {
    local subject="$1"
    local body="$2"
    local repo_name="$3"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY-RUN: Notification pour '$repo_name' non envoyée."
        return 0
    fi

    local html_body; html_body=$(markdown_to_html "$body")
    local email_content; email_content=$(cat <<EOF
To: $EMAIL_TO
From: $EMAIL_FROM
Subject: $subject
Content-Type: text/html; charset=UTF-8
MIME-Version: 1.0

<!DOCTYPE html><html><head><meta charset="UTF-8"><style>body{font-family:sans-serif;line-height:1.6;margin:20px;color:#333}table{border-collapse:collapse;width:100%;margin-bottom:20px}th,td{border:1px solid #ddd;padding:8px;text-align:left}th{background-color:#f2f2f2}h3{color:#d9534f;border-bottom:1px solid #eee;padding-bottom:5px}hr{border:0;border-top:1px solid #eee;margin:20px 0}</style></head><body>${html_body}</body></html>
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

main() {
    log_info "=== Début du monitoring GitLab (v2.3.0 API) ==="
    load_config_and_check_deps
    touch "$TRACKING_FILE"
    
    local public_projects_json; public_projects_json=$(get_public_projects_from_api)
    local project_count; project_count=$(echo "$public_projects_json" | jq 'length')
    
    if [[ "$project_count" -eq 0 ]]; then log_info "Aucun projet public trouvé."; exit 0; fi
    
    log_info "Analyse de ${project_count} projets..."
    local new_repo_count=0
    
    # Boucle robuste avec process substitution pour éviter les problèmes de sous-shell
    while IFS= read -r project_json; do
        local repo_id; repo_id=$(echo "$project_json" | jq -r '.id')
        if ! is_repo_tracked "$repo_id"; then
            log_info "Nouveau dépôt détecté: $(echo "$project_json" | jq -r '.name')"
            
            local repo_name; repo_name=$(echo "$project_json" | jq -r '.name')
            local repo_url; repo_url=$(echo "$project_json" | jq -r '.web_url')
            local repo_path; repo_path=$(echo "$project_json" | jq -r '.path_with_namespace')
            local repo_dev; repo_dev=$(get_last_committer "$repo_id")

            local has_license; has_license=$(check_file_exists "$repo_path" "LICENSE")
            local has_readme; has_readme=$(check_file_exists "$repo_path" "README.md")
            local has_contributing; has_contributing=$(check_file_exists "$repo_path" "CONTRIBUTING.md")
            
            local subject_template_var="EMAIL_SUBJECT_${NOTIFICATION_LANGUAGE}"
            local subject; subject=$(echo "${!subject_template_var}" | sed "s/\\$REPONAME/$repo_name/g")
            
            local lang_code; lang_code=$(echo "$NOTIFICATION_LANGUAGE" | tr '[:upper:]' '[:lower:]')
            local template_file="${SCRIPT_DIR}/template.${lang_code}.md"
            if [[ ! -f "$template_file" ]]; then log_error "Template introuvable: $template_file"; continue; fi
            
            local body; body=$(cat "$template_file")
            body="${body//\$REPONAME/$repo_name}"
            body="${body//\$REPODEV/$repo_dev}"
            body="${body//\$REPOURL/$repo_url}"
            body="${body//\$URLLICENSE/$has_license}"
            body="${body//\$URLREADME/$has_readme}"
            body="${body//\$URLCONTRIBUTING/$has_contributing}"
            
            if send_email "$subject" "$body" "$repo_name"; then
                add_to_tracking "$repo_id"
            fi
            ((new_repo_count++))
        fi
    done < <(echo "$public_projects_json" | jq -c '.[]')

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

if [[ "${1:-}" == "--dry-run" ]]; then
    log_warn "Mode DRY-RUN activé - Aucun email ne sera envoyé."
    DRY_RUN=true
fi

main "$@"