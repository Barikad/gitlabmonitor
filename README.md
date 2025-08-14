# GitLab Public Repository Monitor

[![License: AGPLv3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Shell Script](https://img.shields.io/badge/Language-Shell-green.svg)](https://www.gnu.org/lang/shell)
[![Version](https://img.shields.io/badge/Version-1.4-blue.svg)](https://gitlab.villejuif.fr/depots-public/gitlabmonitor)

Un script shell robuste pour surveiller l'apparition de nouveaux dépôts publics sur GitLab et envoyer des notifications par email.

**[English version below](#english-version)**

---

## 📋 Fonctionnalités

- **Surveillance automatique** : Détecte les nouveaux dépôts publics via scraping (sans token).
- **Notification unique** : Envoie un email seulement lors de la première détection.
- **Templates d'email externes** : Le contenu des emails est géré dans des fichiers `template.fr.md` et `template.en.md` faciles à modifier.
- **Deux modes d'envoi d'email** : Utilise `sendmail` (par défaut) ou un serveur **SMTP** externe.
- **Support bilingue** : Messages en français ou anglais.
- **Logging complet** et **Mode test**.

## 🚀 Installation

1.  **Téléchargez les fichiers** :
    ```bash
    # Script principal
    wget https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/main/gitlab-public-repo-monitor.sh
    # Fichier d'exemple de configuration
    wget https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/main/config.conf.example
    # Templates d'email
    wget https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/main/template.fr.md
    wget https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/main/template.en.md
    
    chmod +x gitlab-public-repo-monitor.sh
    ```

2.  **Créez votre configuration** :
    ```bash
    cp config.conf.example config.conf
    nano config.conf
    ```
    Adaptez au minimum `GITLAB_URL`, `EMAIL_TO` et `EMAIL_FROM`.

## ⚙️ Configuration

La configuration se fait dans `config.conf`. Les templates d'email sont dans les fichiers `template.fr.md` et `template.en.md`.

## 🖥️ Utilisation

```bash
# Exécution normale
./gitlab-public-repo-monitor.sh

# Mode test (n'envoie pas d'email)
./gitlab-public-repo-monitor.sh --dry-run
```

## 📊 Exemple de Notification

#### Version Française
![Exemple de rapport en français](exemple_rapport.svg)

#### Version Anglaise
![Example of an English report](example_report.svg)

---

# English Version

A robust shell script to monitor for new public repositories on a GitLab instance and send email notifications.

## 📋 Features

- **Automatic monitoring**: Detects new public repositories via scraping (no token required).
- **Unique notification**: Sends an email only upon first detection.
- **External email templates**: Email content is managed in easy-to-edit `template.fr.md` and `template.en.md` files.
- **Dual email sending modes**: Uses `sendmail` (default) or an external **SMTP** server.
- **Bilingual support**: Messages in French or English.
- **Complete logging** and **Dry-run mode**.

## 🚀 Installation

1.  **Download the files**:
    ```bash
    # Main script
    wget https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/main/gitlab-public-repo-monitor.sh
    # Example configuration file
    wget https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/main/config.conf.example
    # Email templates
    wget https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/main/template.fr.md
    wget https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/main/template.en.md
    
    chmod +x gitlab-public-repo-monitor.sh
    ```

2.  **Create your configuration**:
    ```bash
    cp config.conf.example config.conf
    nano config.conf
    ```
    At a minimum, adapt `GITLAB_URL`, `EMAIL_TO`, and `EMAIL_FROM`.

## ⚙️ Configuration

Configuration is handled in `config.conf`. Email templates are in the `template.fr.md` and `template.en.md` files.

## 🖥️ Usage

```bash
# Normal execution
./gitlab-public-repo-monitor.sh

# Dry-run mode (does not send emails)
./gitlab-public-repo-monitor.sh --dry-run
```
