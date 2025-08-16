# GitLab Public Repository Monitor

[![License: AGPLv3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Shell Script](https://img.shields.io/badge/Language-Shell-green.svg)](https://www.gnu.org/lang/shell)
[![Version](https://img.shields.io/badge/Version-2.6.0-blue.svg)](https://gitlab.villejuif.fr/depots-public/gitlabmonitor)

Un script shell robuste qui utilise l'**API officielle de GitLab** pour surveiller l'apparition de nouveaux dépôts publics et envoyer des notifications par email.

**[English version below](#english-version)**

---

## 📋 Fonctionnalités

- **Robuste et fiable** : Utilise l'API JSON officielle de GitLab, éliminant les erreurs liées au scraping HTML.
- **Notification unique** : Envoie un email seulement lors de la première détection d'un dépôt (basé sur son ID).
- **Templates d'email externes** : Le contenu des emails est géré dans des fichiers `template.fr.md` et `template.en.md` faciles à modifier.
- **Deux modes d'envoi d'email** : Utilise `sendmail` (par défaut) ou un serveur **SMTP** externe.
- **Support bilingue** : Messages en français ou anglais.
- **Logging complet** et **Mode test** (`--dry-run`).

## 🚀 Installation

### 1. Prérequis

Le script nécessite `curl` et `jq`. `sendmail` est requis uniquement si vous n'utilisez pas de serveur SMTP externe.

```bash
# Pour Debian/Ubuntu
sudo apt-get update && sudo apt-get install curl jq sendmail

# Pour CentOS/RHEL
sudo yum install curl jq sendmail
```

### 2. Téléchargement

Téléchargez les 4 fichiers suivants depuis ce dépôt et placez-les dans un même répertoire :
- `gitlab-public-repo-monitor.sh`
- `config.conf.example`
- `template.fr.md`
- `template.en.md`

Rendez le script exécutable :
```bash
chmod +x gitlab-public-repo-monitor.sh
```

### 3. Configuration

Créez votre fichier de configuration personnel à partir de l'exemple fourni :
```bash
cp config.conf.example config.conf
nano config.conf
```
Adaptez au minimum les variables `GITLAB_URL`, `EMAIL_TO` et `EMAIL_FROM` à votre environnement.

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

A robust shell script that uses the **official GitLab API** to monitor for new public repositories and send email notifications.

## 📋 Features

- **Robust and Reliable**: Uses the official GitLab JSON API, eliminating errors from HTML scraping.
- **Unique Notification**: Sends an email only upon first detection (based on the repository's ID).
- **External Email Templates**: Email content is managed in easy-to-edit `template.fr.md` and `template.en.md` files.
- **Dual Email Sending Modes**: Uses `sendmail` (default) or an external **SMTP** server.
- **Bilingual Support**: Messages in French or English.
- **Complete Logging** and **Dry-run Mode** (`--dry-run`).

## 🚀 Installation

### 1. Prerequisites

The script requires `curl` and `jq`. `sendmail` is only required if you are not using an external SMTP server.

```bash
# For Debian/Ubuntu
sudo apt-get update && sudo apt-get install curl jq sendmail

# For CentOS/RHEL
sudo yum install curl jq sendmail
```

### 2. Download

Download the following 4 files from this repository and place them in the same directory:
- `gitlab-public-repo-monitor.sh`
- `config.conf.example`
- `template.fr.md`
- `template.en.md`

Make the script executable:
```bash
chmod +x gitlab-public-repo-monitor.sh
```

### 3. Configuration

Create your personal configuration file from the provided example:
```bash
cp config.conf.example config.conf
nano config.conf
```
At a minimum, adapt the `GITLAB_URL`, `EMAIL_TO`, and `EMAIL_FROM` variables to your environment.

## 🖥️ Usage

```bash
# Normal execution
./gitlab-public-repo-monitor.sh

# Dry-run mode (does not send emails)
./gitlab-public-repo-monitor.sh --dry-run
```
