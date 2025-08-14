#!/bin/bash
#
#==============================================================================
# GitLab Public Repository Monitor
#
# Auteur:   Joachim COQBLIN + un peu de LLM
# Licence:  AGPLv3
# Version:  1.4.1
# URL:      https://gitlab.villejuif.fr/depots-public/gitlabmonitor
#
# Description (FR):
# Ce script surveille une instance GitLab pour détecter les nouveaux dépôts
# publics. Il envoie une notification par email lors de la première
# détection, en utilisant soit sendmail, soit un serveur SMTP externe.
#
# Description (EN):
# This script monitors a GitLab instance for new public repositories.
# It sends an email notification upon first detection, using either
# sendmail or an external SMTP server.
#
#==============================================================================

set -euo pipefail

#===[ Global Variables ]===#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.conf"
TRACKING_FILE="${SCRIPT_DIR}/tracked_repos.txt"
LOG_FILE="${SCRIPT_DIR}/gitlab-monitor.log"

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
# Prerequisite Checks
#==============================================================================

check_dependencies() {
    local deps=("curl" "sendmail")
    if [[ -n "${SMTP_SERVER:-}" ]]; then
        deps=("curl")
    fi

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Dépendance manquante / Missing dependency: ${dep}"
            exit 1
        fi
    done
}

#==============================================================================
# Load Configuration
#==============================================================================

load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Fichier de configuration introuvable: $CONFIG_FILE"
        exit 1
    fi
    source "$CONFIG_FILE"
    local required_vars=("GITLAB_URL" "EMAIL_TO" "EMAIL_FROM" "NOTIFICATION_LANGUAGE")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Variable de configuration manquante: $var"
            exit 1
        fi
    done
}

#==============================================================================
# GitLab Functions (via Scraping)
#==============================================================================

get_public_projects() {
    local page=1
    local all_projects=()
    log_info "Récupération des projets publics..."
    while true; do
        local projects_on_page
        projects_on_page=($(curl -s "${GITLAB_URL}/explore/projects?sort=latest_activity_desc&page=${page}" | grep -oP 'class="project-name".*?href="\K(/[^/]+/[^/]+)(?=")' | sort -u))
        if [[ ${#projects_on_page[@]} -eq 0 ]]; then break; fi
        all_projects+=("${projects_on_page[@]}")
        ((page++))
        if [[ $page -gt 50 ]]; then
            log_warn "Limite de 50 pages atteinte."
            break
        fi
    done
    log_info "Trouvé ${#all_projects[@]} projets publics."
    printf '%s\n' "${all_projects[@]}" | sort -u
}

get_project_details() {
    local project_path="$1"
    local project_url="${GITLAB_URL}${project_path}"
    local page_content
    page_content=$(curl -sL "$project_url")
    local repo_name
    repo_name=$(echo "$page_content" | grep -oP '<title>[^<]*' | sed 's/<title>//' | cut -d'·' -f1 | xargs)
    local repo_dev
    repo_dev=$(echo "$page_content" | grep -oP 'authored by <a[^>]*>([^<]+)</a>' | sed -e 's/.*>\(.*\)<.*/\1/' | xargs)
    [[ -z "$repo_name" ]] && repo_name="Unknown"
    [[ -z "$repo_dev" ]] && repo_dev="Unknown"
    echo "$repo_name|$repo_url|$repo_dev"
}

check_file_exists() {
    local project_path="$1"
    local file_path="$2"
    if curl -s --head --fail "${GITLAB_URL}${project_path}/-/blob/main/${file_path}" > /dev/null || curl -s --head --fail "${GITLAB_URL}${project_path}/-/blob/master/${file_path}" > /dev/null; then
        echo "✅"
    else
        echo "❌"
    fi
}

#==============================================================================
# Tracking Management
#==============================================================================

is_repo_tracked() {
    local repo_hash
    repo_hash=$(echo "$1" | sha256sum | cut -d' ' -f1)
    [[ -f "$TRACKING_FILE" ]] && grep -q "^${repo_hash}$" "$TRACKING_FILE"
}

add_to_tracking() {
    local repo_hash
    repo_hash=$(echo "$1" | sha256sum | cut -d' ' -f1)
    echo "$repo_hash" >> "$TRACKING_FILE"
}

#==============================================================================
# Email Sending
#==============================================================================

generate_email_body() {
    local repo_name="$1"; local repo_dev="$2"; local repo_url="$3"
    local has_license="$4"; local has_readme="$5"; local has_contributing="$6"
    
    local lang_code
    lang_code=$(echo "$NOTIFICATION_LANGUAGE" | tr '[:upper:]' '[:lower:]')
    local template_file="${SCRIPT_DIR}/template.${lang_code}.md"

    if [[ ! -f "$template_file" ]]; then
        log_error "Fichier de template introuvable: $template_file"
        return 1
    fi

    local email_template
    email_template=$(cat "$template_file")
    
    email_template="${email_template//\$REPONAME/$repo_name}"
    email_template="${email_template//\$REPODEV/$repo_dev}"
    email_template="${email_template//\$REPOURL/$repo_url}"
    email_template="${email_template//\$URLLICENSE/$has_license}"
    email_template="${email_template//\$URLREADME/$has_readme}"
    email_template="${email_template//\$URLCONTRIBUTING/$has_contributing}"
    
    echo "$email_template"
}

send_email() {
    local subject="$1"
    local body="$2"
    local html_body
    html_body=$(echo "$body" | sed -e 's/$/<br>/' -e 's/^### \(.*\)<br>/<h3>\1<\/h3>/' -e 's/^**\(.*\)**<br>/<strong>\1<\/strong><br>/' -e 's/`\(.*\)`/<code>\1<\/code>/g' -e 's|---|<hr>|')
    local email_content
    email_content=$(cat <<EOF
To: $EMAIL_TO
From: $EMAIL_FROM
Subject: $subject
Content-Type: text/html; charset=UTF-8
MIME-Version: 1.0

<!DOCTYPE html><html><head><meta charset="UTF-8"><style>body{font-family:sans-serif;line-height:1.6;margin:20px;color:#333}table{border-collapse:collapse;width:100%;margin-bottom:20px}th,td{border:1px solid #ddd;padding:12px;text-align:left}th{background-color:#f7f7f7}h3{color:#d9534f;border-bottom:2px solid #f0f0f0;padding-bottom:5px}hr{border:0;border-top:1px solid #eee;margin:20px 0}code{background-color:#f0f0f0;padding:2px 5px;border-radius:4px}</style></head><body>${html_body}</body></html>
EOF
)

    if [[ -n "${SMTP_SERVER:-}" ]]; then
        log_info "Utilisation du serveur SMTP ($SMTP_SERVER)..."
        local curl_opts=()
        local proto="smtp"
        if [[ "${SMTP_TLS:-}" == "true" ]]; then proto="smtps"; fi
        if [[ -n "${SMTP_USER:-}" ]] && [[ -n "${SMTP_PASS:-}" ]]; then
            curl_opts+=(--user "${SMTP_USER}:${SMTP_PASS}")
        fi
        if ! echo -e "$email_content" | curl -s --url "${proto}://${SMTP_SERVER}:${SMTP_PORT:-587}" --mail-from "$EMAIL_FROM" --mail-rcpt "$EMAIL_TO" "${curl_opts[@]}" --upload-file -; then
            log_error "Échec de l'envoi via SMTP."
            return 1
        fi
    else
        log_info "Utilisation de sendmail..."
        if ! echo -e "$email_content" | sendmail -t; then
            log_error "Échec de l'envoi via sendmail."
            return 1
        fi
    fi
    log_success "Email envoyé pour '$repo_name'."
    return 0
}

#==============================================================================
# Main Functions
#==============================================================================

process_repo() {
    local project_path="$1"
    log_info "Traitement du nouveau projet: $project_path"
    local project_details
    project_details=$(get_project_details "$project_path")
    IFS='|' read -r repo_name repo_url repo_dev <<< "$project_details"
    if [[ "$repo_name" == "Unknown" ]]; then
        log_warn "Détails introuvables pour $project_path."
        return
    fi
    local has_license; has_license=$(check_file_exists "$project_path" "LICENSE")
    local has_readme; has_readme=$(check_file_exists "$project_path" "README.md")
    local has_contributing; has_contributing=$(check_file_exists "$project_path" "CONTRIBUTING.md")
    log_info "Détails: Nom='$repo_name', Dev='$repo_dev'"
    local subject_template_var="EMAIL_SUBJECT_${NOTIFICATION_LANGUAGE}"
    local subject; subject=$(echo "${!subject_template_var}" | sed "s/\\$REPONAME/$repo_name/g")
    local body; body=$(generate_email_body "$repo_name" "$repo_dev" "$repo_url" "$has_license" "$has_readme" "$has_contributing")
    if [[ -n "$body" ]] && send_email "$subject" "$body"; then
        add_to_tracking "$project_path"
    fi
}

main() {
    log_info "=== Début du monitoring GitLab ==="
    load_config
    check_dependencies
    touch "$TRACKING_FILE"
    local public_projects; public_projects=($(get_public_projects))
    if [[ ${#public_projects[@]} -eq 0 ]]; then
        log_info "Aucun projet public trouvé."
        log_info "=== Fin du monitoring. ==="
        exit 0
    fi
    local new_repo_count=0
    log_info "Analyse de ${#public_projects[@]} projets..."
    for project_path in "${public_projects[@]}"; do
        if ! is_repo_tracked "$project_path"; then
            log_info "Nouveau dépôt détecté: $project_path"
            process_repo "$project_path"
            ((new_repo_count++))
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

if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << EOF
GitLab Public Repository Monitor v1.4
Usage: $0 [OPTIONS]
Monitors for new public repositories on GitLab and notifies via email.
Options:
  -h, --help     Display this help.
  --dry-run      Run without sending emails.
  --config FILE  Custom config path.
EOF
    exit 0
fi

if [[ "${1:-}" == "--dry-run" ]]; then
    log_warn "Mode DRY-RUN activé - Aucun email ne sera envoyé."
    send_email() {
        log_info "DRY-RUN: Notification pour '$repo_name' non envoyée."
        add_to_tracking "$project_path"
        return 0
    }
fi

main "$@"