# GitLab Public Repository Monitor

[![pipeline status](https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/badges/main/pipeline.svg)](https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/commit/main)
[![latest release](https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/badges/release.svg)](https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/releases)
[![License: AGPLv3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg?style=for-the-badge)](https://www.gnu.org/licenses/agpl-3.0)
[![Shell Script](https://img.shields.io/badge/Language-Shell-green.svg?style=for-the-badge)](https://www.gnu.org/lang/shell)
[![Platform: GitLab](https://img.shields.io/badge/Platform-GitLab-orange.svg?style=for-the-badge)](https://gitlab.com)

> **Note sur le Dépôt Officiel**
>
> Ce projet est maintenu sur le [GitLab de la Mairie de Villejuif](https://gitlab.villejuif.fr/depots-public/gitlabmonitor). Des miroirs en lecture seule peuvent exister sur d'autres plateformes (GitHub, etc.), mais cette instance est la seule source officielle. Toutes les contributions (tickets, requêtes de fusion) doivent y être soumises.
>
> ---
>
> **Note on the Official Repository**
>
> This project is maintained on the [Mairie de Villejuif's GitLab](https://gitlab.villejuif.fr/depots-public/gitlabmonitor). Read-only mirrors may exist on other platforms (GitHub, etc.), but this instance is the single source of truth. All contributions (issues, merge requests) must be submitted here.

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
- **Notification CC optionnelle** : Peut mettre en copie l'auteur du dernier commit.
- **Sortie améliorée** : Affiche des informations claires sur les dépôts traités, ignorés et les destinataires des emails.

## 🚀 Installation

### Méthode Rapide (Recommandée)
Exécutez la commande suivante pour télécharger et installer la dernière version dans un répertoire `gitlabmonitor` :
```bash
curl -sSL https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/main/install.sh | sh
```

### Autres Méthodes

<details>
<summary>Afficher les méthodes d'installation alternatives (Git, téléchargement manuel)</summary>

#### Cloner le dépôt (pour les développeurs)
```bash
git clone https://gitlab.villejuif.fr/depots-public/gitlabmonitor.git
cd gitlabmonitor
chmod +x gitlab-public-repo-monitor.sh
```

#### Téléchargement Manuel
Vous pouvez télécharger la dernière archive `.tar.gz` directement :

[![Download Latest](https://img.shields.io/badge/Télécharger-Dernière%20Version-blue?style=for-the-badge)](https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/releases/permalink/latest/downloads/gitlab-monitor-latest.tar.gz)

L'historique complet des versions est aussi disponible sur la [page des Releases](https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/releases).
</details>

### Configuration
Après l'installation, créez votre fichier de configuration :
```bash
cd gitlabmonitor
cp config.conf.example config.conf
```
Ensuite, éditez `config.conf` pour ajuster les variables à vos besoins.

| Variable | Description | Défaut |
|---|---|---|
| `GITLAB_URL` | URL de votre instance GitLab. | `"https://gitlab.example.com"` |
| `NOTIFICATION_LANGUAGE` | Langue des notifications (`FR` ou `EN`). | `"FR"` |
| `EMAIL_TO` | Destinataire principal des alertes. | `"admin@example.com"` |
| `EMAIL_FROM` | Expéditeur des alertes. | `"gitlab-monitor@example.com"` |
| `EMAIL_SUBJECT_FR` / `_EN` | Sujet des emails (utilise `$REPONAME`). | `...` |
| `SMTP_SERVER` | (Optionnel) Serveur SMTP pour l'envoi. | `""` |
| `SMTP_PORT` | (Optionnel) Port du serveur SMTP. | `"25"` |
| `SMTP_USER` | (Optionnel) Utilisateur pour l'authentification SMTP. | `""` |
| `SMTP_PASS` | (Optionnel) Mot de passe pour l'authentification SMTP. | `""` |
| `SMTP_TLS` | (Optionnel) Mettre à `"true"` pour utiliser SMTPS. | `""` |
| `CC_COMMIT_AUTHOR` | Mettre à `true` pour mettre en copie l'auteur du dernier commit. | `false` |
| `API_TIMEOUT` | Timeout en secondes pour les appels API. | `30` |
| `LOG_LEVEL` | Niveau de log (`DEBUG`, `INFO`, `WARN`, `ERROR`). | `"INFO"` |


## 🔄 Mise à jour

Pour mettre à jour le script vers la dernière version, exécutez la commande suivante depuis le répertoire d'installation :
```bash
./gitlab-public-repo-monitor.sh --upgrade
```
Le script vous guidera à travers le processus de mise à jour de manière interactive et sécurisée, en préservant vos fichiers `config.conf` et vos templates personnalisés.

## 🖥️ Utilisation

### Exécution Manuelle
```bash
# Exécution normale
./gitlab-public-repo-monitor.sh

# Mode test (n'envoie pas d'email et ne met pas à jour le cache)
./gitlab-public-repo-monitor.sh --dry-run

# Lancer la procédure de mise à jour
./gitlab-public-repo-monitor.sh --upgrade
```

### Automatisation (Cron)

Pour exécuter le script automatiquement, vous pouvez ajouter une entrée à votre crontab (`crontab -e`).

**Exemple simple** : Exécution toutes les heures.
```crontab
0 * * * * /chemin/complet/vers/gitlab-public-repo-monitor.sh >> /var/log/gitlab-monitor-cron.log 2>&1
```

**Exemple avancé** : Exécution tous les jours à 7h00, en s'assurant que le script s'exécute depuis son propre répertoire pour une gestion correcte des logs et des fichiers templates.
```crontab
0 7 * * * cd /chemin/complet/vers/gitlab-public-repo-monitor/ && ./gitlab-public-repo-monitor.sh
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
- **Optional CC Notification**: Can CC the author of the last commit.
- **Enhanced Output**: Displays clear information about processed, skipped repositories and email recipients.

## 🚀 Installation

### Quick Install (Recommended)
Run the following command to download and install the latest version into a `gitlabmonitor` directory:
```bash
curl -sSL https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/main/install.sh | sh
```

### Other Methods

<details>
<summary>Show alternative installation methods (Git, manual download)</summary>

#### Clone the Repository (for developers)
```bash
git clone https://gitlab.villejuif.fr/depots-public/gitlabmonitor.git
cd gitlabmonitor
chmod +x gitlab-public-repo-monitor.sh
```

#### Manual Download
You can download the latest `.tar.gz` archive directly:

[![Download Latest](https://img.shields.io/badge/Download-Latest%20Version-blue?style=for-the-badge)](https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/releases/permalink/latest/downloads/gitlab-monitor-latest.tar.gz)

The full release history is also available on the [Releases page](https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/releases).
</details>

### Configuration
After installation, create your configuration file:
```bash
cd gitlabmonitor
cp config.conf.example config.conf
```
Then, edit `config.conf` to adjust the variables to your needs.

| Variable | Description | Default |
|---|---|---|
| `GITLAB_URL` | URL of your GitLab instance. | `"https://gitlab.example.com"` |
| `NOTIFICATION_LANGUAGE` | Notification language (`FR` or `EN`). | `"FR"` |
| `EMAIL_TO` | Primary recipient for alerts. | `"admin@example.com"` |
| `EMAIL_FROM` | Sender of the alerts. | `"gitlab-monitor@example.com"` |
| `EMAIL_SUBJECT_FR` / `_EN` | Email subject (uses `$REPONAME`). | `...` |
| `SMTP_SERVER` | (Optional) SMTP server for sending emails. | `""` |
| `SMTP_PORT` | (Optional) SMTP server port. | `"25"` |
| `SMTP_USER` | (Optional) User for SMTP authentication. | `""` |
| `SMTP_PASS` | (Optional) Password for SMTP authentication. | `""` |
| `SMTP_TLS` | (Optional) Set to `"true"` to use SMTPS. | `""` |
| `CC_COMMIT_AUTHOR` | Set to `true` to CC the last commit author. | `false` |
| `API_TIMEOUT` | Timeout in seconds for API calls. | `30` |
| `LOG_LEVEL` | Log level (`DEBUG`, `INFO`, `WARN`, `ERROR`). | `"INFO"` |


## 🔄 Updating

To update the script to the latest version, run the following command from within the installation directory:
```bash
./gitlab-public-repo-monitor.sh --upgrade
```
The script will guide you through a safe and interactive update process, preserving your `config.conf` and any custom templates.

## 🖥️ Usage

### Manual Execution
```bash
# Normal execution
./gitlab-public-repo-monitor.sh

# Dry-run mode (does not send emails or update the cache)
./gitlab-public-repo-monitor.sh --dry-run

# Run the upgrade procedure
./gitlab-public-repo-monitor.sh --upgrade
```

### Automation (Cron)

To run the script automatically, you can add an entry to your crontab (`crontab -e`).

**Simple Example**: Run every hour.
```crontab
0 * * * * /full/path/to/gitlab-public-repo-monitor.sh >> /var/log/gitlab-monitor-cron.log 2>&1
```

**Advanced Example**: Run every day at 7:00 AM, ensuring the script runs from its own directory for proper log and template file handling.
```crontab
0 7 * * * cd /full/path/to/gitlab-public-repo-monitor/ && ./gitlab-public-repo-monitor.sh
```
