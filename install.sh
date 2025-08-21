#!/bin/sh
#
#==============================================================================
# GitLab Public Repository Monitor - Installer
#
# Ce script télécharge et installe la dernière version de GitLabMonitor.
# Utilisation : curl -sSL <URL_VERS_CE_SCRIPT> | sh
#==============================================================================

set -e

# Variables
DOWNLOAD_URL="https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/releases/permalink/latest/downloads/gitlab-monitor-latest.tar.gz"
INSTALL_DIR="gitlabmonitor"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Détection de la langue
LANG=${LANG:-en_US.UTF-8}
IS_FRENCH=false
if echo "$LANG" | grep -q -E '^fr'; then
    IS_FRENCH=true
fi

# Messages bilingues
msg() {
    if [ "$IS_FRENCH" = true ]; then
        echo "$1"
    else
        echo "$2"
    fi
}

echo "--- Installation de GitLabMonitor ---"

# Vérification des dépendances
msg "Vérification des dépendances (curl, tar)..." "Checking dependencies (curl, tar)..."
if ! command -v curl >/dev/null 2>&1; then
    msg "ERREUR : 'curl' n'est pas installé. Veuillez l'installer avant de continuer." "ERROR: 'curl' is not installed. Please install it to continue." >&2
    exit 1
fi
if ! command -v tar >/dev/null 2>&1; then
    msg "ERREUR : 'tar' n'est pas installé. Veuillez l'installer avant de continuer." "ERROR: 'tar' is not installed. Please install it to continue." >&2
    exit 1
fi

# Gestion du répertoire existant
if [ -d "$INSTALL_DIR" ]; then
    msg "${YELLOW}Le répertoire '$INSTALL_DIR' existe déjà.${NC}" "${YELLOW}The directory '$INSTALL_DIR' already exists.${NC}"
    msg "Que souhaitez-vous faire ?" "What would you like to do?"
    msg "  1) Supprimer le répertoire existant (toutes les données seront perdues)" "  1) Delete the existing directory (all data will be lost)"
    msg "  2) Écraser les fichiers existants (le fichier 'config.conf' sera préservé)" "  2) Overwrite existing files ('config.conf' will be preserved)"
    msg "  3) Choisir un nouveau nom de répertoire" "  3) Choose a new directory name"
    
    read -p "$(msg 'Votre choix [1-3] : ' 'Your choice [1-3]: ')" choice

    case "$choice" in
        1)
            msg "Suppression du répertoire '$INSTALL_DIR'..." "Deleting directory '$INSTALL_DIR'..."
            rm -rf "$INSTALL_DIR"
            ;;
        2)
            msg "Écrasement des fichiers dans '$INSTALL_DIR'..." "Overwriting files in '$INSTALL_DIR'..."
            if [ -f "${INSTALL_DIR}/config.conf" ]; then
                mv "${INSTALL_DIR}/config.conf" "${INSTALL_DIR}/config.conf.bak"
                msg "Sauvegarde de votre 'config.conf' existant en 'config.conf.bak'." "Backed up your existing 'config.conf' to 'config.conf.bak'."
            fi
            ;;
        3)
            read -p "$(msg 'Entrez le nouveau nom du répertoire : ' 'Enter the new directory name: ')" NEW_INSTALL_DIR
            INSTALL_DIR="$NEW_INSTALL_DIR"
            ;;
        *)
            msg "Choix invalide. Abandon." "Invalid choice. Aborting." >&2
            exit 1
            ;;
    esac
fi

mkdir -p "$INSTALL_DIR"
msg "Installation dans le répertoire '$INSTALL_DIR'..." "Installing into directory '$INSTALL_DIR'..."

# Téléchargement et extraction
msg "Téléchargement de la dernière version..." "Downloading the latest version..."
curl -v -sSL "$DOWNLOAD_URL" | tar -xzv -C "$INSTALL_DIR" --strip-components=1

# Restaurer la configuration si elle a été sauvegardée
if [ -f "${INSTALL_DIR}/config.conf.bak" ]; then
    mv "${INSTALL_DIR}/config.conf.bak" "${INSTALL_DIR}/config.conf"
    msg "Restauration de votre 'config.conf'." "Restored your 'config.conf'."
fi

# Rendre le script principal exécutable
if [ -f "${INSTALL_DIR}/gitlab-public-repo-monitor.sh" ]; then
    chmod +x "${INSTALL_DIR}/gitlab-public-repo-monitor.sh"
    msg "Script principal rendu exécutable." "Main script made executable."
else
    msg "ERREUR : Le script principal n'a pas été trouvé après l'extraction." "ERROR: Main script not found after extraction." >&2
    exit 1
fi

echo ""
msg "${GREEN}Installation terminée avec succès !${NC}" "${GREEN}Installation completed successfully!${NC}"
echo ""
msg "Pour commencer :" "To get started:"
msg "1. Allez dans le répertoire : cd ${INSTALL_DIR}" "1. Go to the directory: cd ${INSTALL_DIR}"
msg "2. Si ce n'est pas déjà fait, copiez la configuration : cp config.conf.example config.conf" "2. If not already done, copy the configuration: cp config.conf.example config.conf"
msg "3. Modifiez le fichier 'config.conf' avec vos paramètres." "3. Edit the 'config.conf' file with your settings."
msg "4. Lancez le script : ./gitlab-public-repo-monitor.sh" "4. Run the script: ./gitlab-public-repo-monitor.sh"
echo ""
