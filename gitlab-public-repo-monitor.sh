#!/bin/bash
#
#==============================================================================
# GitLab Public Repository Monitor
#
# Auteur:   Joachim COQBLIN + un peu de LLM
# Licence:  AGPLv3
# Version:  2.8
# Dépôt:    https://gitlab.villejuif.fr/depots-public/gitlabmonitor
# Download: https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/releases/permalink/latest/downloads/gitlab-monitor-latest.tar.gz
#
#==============================================================================

# Exit on unset variables and pipeline errors
set -eu

#===[ Global Variables ]===#
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
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
    level="$1"; shift
    message="$*"
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    (echo -e "${timestamp} [${level}] ${message}" | tee -a "${LOG_FILE}") >&2
}

log_info() { log "${BLUE}INFO${NC}" "$@"; }
log_warn() { log "${YELLOW}WARN${NC}" "$@"; }
log_error() { log "${RED}ERROR${NC}" "$@"; }
log_success() { log "${GREEN}SUCCESS${NC}" "$@"; }

# Détection de la langue pour les messages interactifs (Anglais par défaut)
LANG=${LANG:-en_US.UTF-8}
IS_FRENCH=false
if echo "$LANG" | grep -q -E '^fr'; then
    IS_FRENCH=true
fi

# Messages interactifs bilingues
msg() {
    if [ "$IS_FRENCH" = true ]; then
        echo -e "$1"
    else
        echo -e "$2"
    fi
}

#==============================================================================
# Prerequisite Checks & Config Loading
#==============================================================================

load_config_and_check_deps() {
    if [ ! -f "$CONFIG_FILE" ]; then log_error "Fichier de configuration introuvable: $CONFIG_FILE"; exit 1; fi
    . "$CONFIG_FILE"
    
    required_vars="GITLAB_URL EMAIL_TO EMAIL_FROM NOTIFICATION_LANGUAGE"
    for var in $required_vars; do
        if [ -z "$(eval echo \\\$$var)" ]; then log_error "Variable de configuration manquante: $var"; exit 1; fi
    done

    deps="curl jq sendmail"
    if [ -n "${SMTP_SERVER:-}" ]; then deps="curl jq"; fi
    for dep in $deps; do
        if ! command -v "$dep" >/dev/null 2>&1; then log_error "Dépendance manquante: ${dep}"; exit 1; fi
    done
}

#==============================================================================
# GitLab API Functions
#==============================================================================

get_public_projects_from_api() {
    log_info "Récupération des projets publics via lAPI..."
    api_url="${GITLAB_URL}/api/v4/projects?visibility=public&order_by=last_activity_at&sort=desc&per_page=100"
    response=$(curl -s --connect-timeout "${API_TIMEOUT:-30}" "$api_url")
    if ! echo "$response" | jq empty >/dev/null 2>&1; then
        log_error "Réponse de lAPI invalide."
        echo "[]"
    else
        log_info "Trouvé $(echo "$response" | jq 'length') projets publics."
        echo "$response"
    fi
}

get_last_committer() {
    project_id="$1"
    api_url="${GITLAB_URL}/api/v4/projects/${project_id}/repository/commits?per_page=1"
    response=$(curl -s --connect-timeout "${API_TIMEOUT:-30}" "$api_url")
    
    if echo "$response" | jq -e '.[0].author_name' > /dev/null 2>&1; then
        echo "$response" | jq -r '.[0].author_name'
        echo "$response" | jq -r '.[0].author_email'
    else
        echo "N/A"
        echo ""
    fi
}

check_files_via_git_clone() {
    repo_http_url="$1"
    temp_dir=$(mktemp -d)
    
    log_info "Clonage superficiel de ${repo_http_url}..."
    if git clone --depth 1 --quiet "$repo_http_url" "$temp_dir"; then
        license_status="❌"
        readme_status="❌"
        contributing_status="❌"
        
        if [ -f "${temp_dir}/LICENSE" ]; then license_status="✅"; fi
        if [ -f "${temp_dir}/README.md" ]; then readme_status="✅"; fi
        if [ -f "${temp_dir}/CONTRIBUTING.md" ]; then contributing_status="✅"; fi
        
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
    [ -f "$TRACKING_FILE" ] && grep -q "^$1$" "$TRACKING_FILE"
}

add_to_tracking() {
    echo "$1" >> "$TRACKING_FILE"
}

#==============================================================================
# Email Generation & Sending
#==============================================================================

send_email() {
    subject="$1"
    repo_name="$2"
    repo_dev="$3"
    repo_url="$4"
    has_license="$5"
    has_readme="$6"
    has_contributing="$7"
    repo_dev_email="$8"

    if [ "$DRY_RUN" = "true" ]; then
        log_info "DRY-RUN: Notification pour '$repo_name' non envoyée."
        return 0
    fi

    recipients="$EMAIL_TO"
    if [ "${CC_COMMIT_AUTHOR:-false}" = "true" ] && [ -n "$repo_dev_email" ]; then
        recipients="$recipients,$repo_dev_email"
    fi

    msg_var="MSG_MAILING_TO_${NOTIFICATION_LANGUAGE}"
    log_info "$(printf "$(eval echo \\