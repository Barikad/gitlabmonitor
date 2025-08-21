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
NC='\033[0m'

echo "--- Installation de GitLabMonitor ---"

# Vérification des dépendances
echo "Vérification des dépendances (curl, tar)..."
if ! command -v curl >/dev/null 2>&1; then
    echo "ERREUR : 'curl' n'est pas installé. Veuillez l'installer avant de continuer." >&2
    exit 1
fi
if ! command -v tar >/dev/null 2>&1; then
    echo "ERREUR : 'tar' n'est pas installé. Veuillez l'installer avant de continuer." >&2
    exit 1
fi

# Création du répertoire d'installation
if [ -d "$INSTALL_DIR" ]; then
    echo "Le répertoire '$INSTALL_DIR' existe déjà. Veuillez le supprimer ou le renommer avant de continuer." >&2
    exit 1
fi
mkdir -p "$INSTALL_DIR"
echo "Répertoire '$INSTALL_DIR' créé."

# Téléchargement et extraction
echo "Téléchargement de la dernière version..."
curl -v -sSL "$DOWNLOAD_URL" | tar -xzv -C "$INSTALL_DIR" --strip-components=1

# Rendre le script principal exécutable
if [ -f "${INSTALL_DIR}/gitlab-public-repo-monitor.sh" ]; then
    chmod +x "${INSTALL_DIR}/gitlab-public-repo-monitor.sh"
    echo "Script principal rendu exécutable."
else
    echo "ERREUR : Le script principal n'a pas été trouvé après l'extraction." >&2
    exit 1
fi

echo ""
echo "${GREEN}Installation terminée avec succès !${NC}"
echo ""
echo "Pour commencer :"
echo "1. Allez dans le répertoire : cd ${INSTALL_DIR}"
echo "2. Copiez le fichier de configuration : cp config.conf.example config.conf"
echo "3. Modifiez le fichier 'config.conf' avec vos paramètres."
echo "4. Lancez le script : ./gitlab-public-repo-monitor.sh"
echo ""
