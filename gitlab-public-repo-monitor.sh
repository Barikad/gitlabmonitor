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
        if [ -z "$(eval echo \$$var)" ]; then log_error "Variable de configuration manquante: $var"; exit 1; fi
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
    log_info "$(printf "$(eval echo \$$msg_var)" "$recipients")"

    lang_code=$(echo "$NOTIFICATION_LANGUAGE" | tr '[:upper:]' '[:lower:]')
    template_file="${SCRIPT_DIR}/template.${lang_code}.md"
    if [ ! -f "$template_file" ]; then
        log_error "Template file not found: $template_file"
        return 1
    fi
    email_body_content=$(cat "$template_file")

    # Replace placeholders
    email_body_content=$(echo "$email_body_content" | sed \
        -e "s/\\\$REPONAME/$repo_name/g" \
        -e "s/\\\$REPODEV/$repo_dev/g" \
        -e "s/\\\$REPOURL/$repo_url/g" \
        -e "s/\\\$HAS_LICENSE/$has_license/g" \
        -e "s/\\\$HAS_README/$has_readme/g" \
        -e "s/\\\$HAS_CONTRIBUTING/$has_contributing/g")

    # Construct the full HTML body
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

    encoded_subject="=?UTF-8?B?$(echo -n "$subject" | base64 -w 0)?="
    
    # Build headers line by line for robustness
    email_headers="To: $EMAIL_TO
"
    email_headers="${email_headers}From: $EMAIL_FROM
"
    email_headers="${email_headers}Subject: $encoded_subject
"
    if [ "${CC_COMMIT_AUTHOR:-false}" = "true" ] && [ -n "$repo_dev_email" ]; then
        email_headers="${email_headers}Cc: $repo_dev_email
"
    fi
    email_headers="${email_headers}Content-Type: text/html; charset=UTF-8
"
    email_headers="${email_headers}MIME-Version: 1.0"

    # The final email content requires a blank line between headers and body
    email_content="${email_headers}

${email_body}"

    if [ -n "${SMTP_SERVER:-}" ]; then
        log_info "Utilisation du serveur SMTP ($SMTP_SERVER)..."
        # sh compatible way to build recipient list
        recipients_cmd=""
        recipients_cmd="$recipients_cmd --mail-rcpt $EMAIL_TO"
        if [ "${CC_COMMIT_AUTHOR:-false}" = "true" ] && [ -n "$repo_dev_email" ]; then
            recipients_cmd="$recipients_cmd --mail-rcpt $repo_dev_email"
        fi
        echo "$email_content" | curl -s --url "smtp://${SMTP_SERVER}:${SMTP_PORT:-25}" \
            --mail-from "$EMAIL_FROM" \
            $recipients_cmd \
            --upload-file -
    else
        log_info "Utilisation de sendmail..."
        echo "$email_content" | sendmail -t
    fi

    if [ $? -eq 0 ]; then log_success "Email envoyé pour '$repo_name'."; return 0;
    else log_error "Échec de lEnvoi de lEmail pour '$repo_name'."; return 1; fi
}

#==============================================================================
# Upgrade Function
#==============================================================================

run_upgrade() {
    msg "Lancement de la procédure de mise à jour..." "Starting the upgrade procedure..."
    
    # 1. Préparation
    tmp_dir=$(mktemp -d)
    if [ ! -d "$tmp_dir" ]; then
        msg "${RED}ERREUR : Impossible de créer le répertoire temporaire.${NC}" "${RED}ERROR: Could not create temporary directory.${NC}" >&2
        return 1
    fi
    
    download_url=$(grep -m 1 '^# Download:' "$0" | awk '{print $3}')
    if [ -z "$download_url" ]; then
        msg "${RED}ERREUR : URL de téléchargement introuvable dans l'en-tête du script.${NC}" "${RED}ERROR: Download URL not found in the script header.${NC}" >&2
        rm -rf "$tmp_dir"
        return 1
    fi

    msg "Téléchargement de la dernière version depuis ${download_url}..." "Downloading the latest version from ${download_url}..."
    if ! curl -sSL "$download_url" | tar -xz -C "$tmp_dir"; then
        msg "${RED}ERREUR : Échec du téléchargement ou de l'extraction de la nouvelle version.${NC}" "${RED}ERROR: Failed to download or extract the new version.${NC}" >&2
        rm -rf "$tmp_dir"
        return 1
    fi

    # 2. Vérification de la version
    new_script_path="${tmp_dir}/gitlab-public-repo-monitor.sh"
    if [ ! -f "$new_script_path" ]; then
        msg "${RED}ERREUR : Script principal introuvable dans l'archive téléchargée.${NC}" "${RED}ERROR: Main script not found in the downloaded archive.${NC}" >&2
        rm -rf "$tmp_dir"
        return 1
    fi
    
    current_version=$(grep -m 1 '^# Version:' "$0" | awk '{print $3}')
    new_version=$(grep -m 1 '^# Version:' "$new_script_path" | awk '{print $3}')

    msg "Version actuelle : ${current_version}. Version distante : ${new_version}." "Current version: ${current_version}. Remote version: ${new_version}."
    if [ "$current_version" = "$new_version" ]; then
        msg "${GREEN}Vous avez déjà la dernière version.${NC}" "${GREEN}You already have the latest version.${NC}"
        rm -rf "$tmp_dir"
        return 0
    fi

    # 3. Analyse des différences
    msg "Analyse des différences..." "Analyzing differences..."
    new_config_vars=$(grep -oE '^\w+' "${tmp_dir}/config.conf.example" | sort -u)
    user_config_vars=$(grep -oE '^\w+' "${CONFIG_FILE}" | sort -u)
    
    # Create temp files for comm
    new_vars_file=$(mktemp)
    user_vars_file=$(mktemp)
    echo "$new_config_vars" > "$new_vars_file"
    echo "$user_config_vars" > "$user_vars_file"
    missing_vars=$(comm -13 "$user_vars_file" "$new_vars_file")
    rm "$new_vars_file" "$user_vars_file"

    templates_modified=false
    hash_file="${SCRIPT_DIR}/.template_hashes"
    for template in "${SCRIPT_DIR}/template."*.md; do
        lang_code=$(basename "$template" .md | cut -d. -f2)
        if [ -f "$template" ]; then
            current_hash=$(sha256sum "$template" | awk '{print $1}')
            stored_hash=""
            # Vérifier si le fichier de hashes existe avant de le lire
            if [ -f "$hash_file" ]; then
                stored_hash=$(grep "${lang_code}" "$hash_file" 2>/dev/null | awk '{print $2}' || echo "")
            fi
            if [ -z "$stored_hash" ] || [ "$current_hash" != "$stored_hash" ]; then
                templates_modified=true
                break
            fi
        fi
    done

    # 4. Rapport et Confirmation
    echo "-----------------------------------------------------"
    msg "${GREEN}Une nouvelle version (${new_version}) est disponible !${NC}" "${GREEN}A new version (${new_version}) is available!${NC}"
    if [ -n "$missing_vars" ]; then
        msg "${YELLOW}Les nouvelles variables de configuration suivantes ont été détectées :${NC}" "${YELLOW}The following new configuration variables were detected:${NC}"
        echo "$missing_vars" | while IFS= read -r var; do
            grep "^${var}" "${tmp_dir}/config.conf.example"
        done
        msg "${YELLOW}Vous devrez les ajouter manuellement à votre fichier '${CONFIG_FILE}'.${NC}" "${YELLOW}You will need to add them manually to your '${CONFIG_FILE}' file.${NC}"
    fi
    if [ "$templates_modified" = "true" ]; then
        msg "${YELLOW}Vos templates de mail ont été modifiés.${NC}" "${YELLOW}Your email templates have been modified.${NC}"
        msg "${YELLOW}Les nouveaux templates seront installés avec l'extension .new.${NC}" "${YELLOW}The new templates will be installed with the .new extension.${NC}"
    fi
    echo "-----------------------------------------------------"
    
    printf "%s" "$(msg 'Voulez-vous continuer la mise à jour ? [o/N] ' 'Do you want to continue with the update? [y/N] ')"
    read -r reply
    if [ "$reply" != "o" ] && [ "$reply" != "O" ] && [ "$reply" != "y" ] && [ "$reply" != "Y" ]; then
        msg "${RED}Mise à jour annulée.${NC}" "${RED}Update cancelled.${NC}"
        rm -rf "$tmp_dir"
        return 1
    fi

    # 5. Procédure de mise à jour
    msg "Mise à jour des fichiers..." "Updating files..."
    # Exclure les fichiers de configuration et les templates
    rsync -a --exclude='config.conf' --exclude='template.*.md' "${tmp_dir}/" "${SCRIPT_DIR}/"
    
    # Gérer les templates
    for new_template in "${tmp_dir}/template."*.md; do
        base_name=$(basename "$new_template")
        if [ "$templates_modified" = "true" ]; then
            msg "Installation du nouveau template : ${base_name}.new" "Installing new template: ${base_name}.new"
            cp "$new_template" "${SCRIPT_DIR}/${base_name}.new"
        else
            msg "Mise à jour du template : ${base_name}" "Updating template: ${base_name}"
            cp "$new_template" "${SCRIPT_DIR}/${base_name}"
        fi
    done

    chmod +x "${SCRIPT_DIR}/gitlab-public-repo-monitor.sh"
    
    # Mettre à jour les hashes
    msg "Mise à jour des hashes de référence des templates..." "Updating template reference hashes..."
    > "$hash_file"
    for template in "${tmp_dir}/template."*.md; do
        lang_code=$(basename "$template" .md | cut -d. -f2)
        sha256sum "$template" | awk -v lc="$lang_code" '{print lc " " $1}' >> "$hash_file"
    done

    msg "${GREEN}Mise à jour vers la version ${new_version} terminée !${NC}" "${GREEN}Upgrade to version ${new_version} complete!${NC}"
    msg "${YELLOW}N'oubliez pas de vérifier votre 'config.conf' et de fusionner les templates si nécessaire.${NC}" "${YELLOW}Remember to check your 'config.conf' and merge templates if necessary.${NC}"
    
    rm -rf "$tmp_dir"
    return 0
}


#==============================================================================
# Main Logic
#==============================================================================

process_project() {
    project_json="$1"
    repo_id=$(echo "$project_json" | jq -r '.id')

    if is_repo_tracked "$repo_id"; then
        msg_var="MSG_KNOWN_REPO_${NOTIFICATION_LANGUAGE}"
        log_info "$(printf "$(eval echo \$$msg_var)" "$repo_id" "$(echo "$project_json" | jq -r '.name')")"
        return 0
    fi

    log_info "Nouveau dépôt détecté: $(echo "$project_json" | jq -r '.name')"
    
    repo_name=$(echo "$project_json" | jq -r '.name')
    repo_url=$(echo "$project_json" | jq -r '.web_url')
    repo_http_url=$(echo "$project_json" | jq -r '.http_url_to_repo')
    
    committer_info=$(get_last_committer "$repo_id")
    repo_dev=$(echo "$committer_info" | head -n 1)
    repo_dev_email=$(echo "$committer_info" | tail -n 1)

    file_statuses=$(check_files_via_git_clone "$repo_http_url")
    # POSIX-compliant read
    license_status=$(echo "$file_statuses" | awk '{print $1}')
    readme_status=$(echo "$file_statuses" | awk '{print $2}')
    contributing_status=$(echo "$file_statuses" | awk '{print $3}')
    
    subject_template_var="EMAIL_SUBJECT_${NOTIFICATION_LANGUAGE}"
    subject_template=$(eval echo \$$subject_template_var)
    subject=$(echo "$subject_template" | sed "s/\\\$REPONAME/$repo_name/g")
    
    if send_email "$subject" "$repo_name" "$repo_dev" "$repo_url" "$license_status" "$readme_status" "$contributing_status" "$repo_dev_email"; then
        if [ "$DRY_RUN" = "false" ]; then
            add_to_tracking "$repo_id"
        fi
        return 0
    else
        return 1
    fi
}

main() {
    log_info "=== Début du monitoring GitLab (v2.5.9 API) ==="
    load_config_and_check_deps
    touch "$TRACKING_FILE"
    
    public_projects_json=$(get_public_projects_from_api)
    project_count=$(echo "$public_projects_json" | jq 'length')
    
    if [ "$project_count" -eq 0 ]; then log_info "Aucun projet public trouvé."; exit 0; fi
    
    log_info "Analyse de ${project_count} projets..."
    new_repo_count=0
    
    i=0
    while [ $i -lt $project_count ]; do
        project_data=$(echo "$public_projects_json" | jq -c ".[${i}]")
        if process_project "$project_data"; then
            if ! is_repo_tracked "$(echo "$project_data" | jq -r '.id')"; then
                 new_repo_count=$((new_repo_count + 1))
            fi
        else
            log_warn "Échec du traitement pour le projet $(echo "$project_data" | jq -r .name). Passage au suivant."
        fi
        i=$((i + 1))
    done

    if [ $new_repo_count -eq 0 ]; then
        log_info "Aucun nouveau dépôt à notifier."
    else
        log_success "$new_repo_count nouveaux dépôts traités."
    fi
    
    log_info "=== Fin du monitoring GitLab. ==="
}

#==============================================================================
# Entry Point
#==============================================================================

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --debug)
      DEBUG_MODE=true
      LOG_FILE="${SCRIPT_DIR}/gitlab-monitor_$(date +%Y%m%d-%H%M%S).log"
      exec 2> >(tee -a "${LOG_FILE}")
      set -x
      shift
      ;;
    --upgrade)
      run_upgrade
      exit $?
      ;;
    *)
      # unknown option
      shift
      ;;
  esac
done

main
