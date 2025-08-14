# GitLab Public Repository Monitor

[![License: AGPLv3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Shell Script](https://img.shields.io/badge/Language-Shell-green.svg)](https://www.gnu.org/lang/shell)
[![Version](https://img.shields.io/badge/Version-1.1-blue.svg)](https://gitlab.villejuif.fr/depots-public/gitlabmonitor)

Un script shell robuste pour surveiller automatiquement l'apparition de nouveaux dépôts publics sur une instance GitLab et envoyer des notifications par email lors de leur première détection.

**[English version below](#english-version)**

---

## 📋 Fonctionnalités

- **Surveillance automatique** : Détecte les nouveaux dépôts publics sur GitLab via scraping (sans token).
- **Notification unique** : Envoie un email seulement lors de la première détection d'un dépôt.
- **Deux modes d'envoi d'email** : Utilise `sendmail` (par défaut) ou un serveur **SMTP** externe.
- **Support bilingue** : Messages en français ou anglais selon la configuration.
- **Template personnalisable** : Message email configurable en Markdown.
- **Suivi persistent** : Mémorise les dépôts déjà traités pour éviter les doublons.
- **Logging complet** : Journalisation détaillée des opérations.
- **Mode test** : Option `--dry-run` pour tester sans envoyer d'emails.

## 🚀 Installation

### Prérequis

Le script nécessite `curl`. `sendmail` est requis uniquement si vous n'utilisez pas de serveur SMTP externe.

```bash
# Pour Debian/Ubuntu (si vous n'utilisez pas de SMTP externe)
sudo apt-get update && sudo apt-get install curl sendmail

# Pour CentOS/RHEL (si vous n'utilisez pas de SMTP externe)
sudo yum install curl sendmail
```

### Installation du script

1.  **Clonez ou téléchargez le script** :
    ```bash
    wget https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/main/gitlab-public-repo-monitor.sh
    chmod +x gitlab-public-repo-monitor.sh
    ```

2.  **Créez et éditez le fichier de configuration** :
    ```bash
    cp config.conf.example config.conf
    nano config.conf
    ```

## ⚙️ Configuration

### Paramètres de Configuration

Éditez le fichier `config.conf` pour l'adapter à votre environnement.

| Paramètre | Description | Exemple |
|---|---|---|
| `GITLAB_URL` | **(Obligatoire)** URL de votre instance GitLab. | `https://gitlab.example.com` |
| `NOTIFICATION_LANGUAGE` | **(Obligatoire)** Langue des notifications (`FR` ou `EN`). | `FR` |
| `EMAIL_TO` | **(Obligatoire)** Adresse email de destination. | `admin@example.com` |
| `EMAIL_FROM` | **(Obligatoire)** Adresse email d'expéditeur. | `gitlab-monitor@example.com` |
| `SMTP_SERVER` | (Optionnel) Adresse de votre serveur SMTP. | `smtp.example.com` |
| `SMTP_PORT` | (Optionnel) Port de votre serveur SMTP. | `587` |
| `SMTP_USER` | (Optionnel) Nom d'utilisateur pour l'authentification SMTP. | `user@example.com` |
| `SMTP_PASS` | (Optionnel) Mot de passe pour l'authentification SMTP. | `s3cr3t` |
| `SMTP_TLS` | (Optionnel) Mettre à `true` pour activer SMTPS. | `true` |

### Configuration SMTP (Optionnelle)

Si vous ne souhaitez pas utiliser `sendmail`, vous pouvez configurer le script pour qu'il envoie les emails via un serveur SMTP externe. Pour cela, décommentez et remplissez les variables `SMTP_*` dans votre fichier `config.conf`.

-   Si `SMTP_SERVER` et `SMTP_PORT` sont définis, le script utilisera `curl` pour envoyer les emails et `sendmail` ne sera plus nécessaire.
-   Il est fortement recommandé d'utiliser une connexion sécurisée (`SMTP_TLS="true"`).

## 🖥️ Utilisation

### Exécution manuelle

```bash
# Exécution normale
./gitlab-public-repo-monitor.sh

# Mode test (n'envoie pas d'email mais simule la détection)
./gitlab-public-repo-monitor.sh --dry-run

# Utiliser un fichier de configuration personnalisé
./gitlab-public-repo-monitor.sh --config /path/to/custom.conf

# Afficher l'aide
./gitlab-public-repo-monitor.sh --help
```

### Planification avec Cron

Pour une surveillance continue, ajoutez une entrée à votre crontab :

```bash
# Exécuter le script tous les jours à 8h00
0 8 * * * /path/to/gitlab-public-repo-monitor.sh >> /var/log/gitlab-monitor.log 2>&1
```

---

# English Version

## 📋 Features

- **Automatic monitoring**: Detects new public repositories on a GitLab instance via scraping (no token required).
- **Unique notification**: Sends an email only upon the first detection of a repository.
- **Two email sending modes**: Uses `sendmail` (default) or an external **SMTP** server.
- **Bilingual support**: Messages in French or English based on configuration.
- **Customizable template**: Email message configurable in Markdown.
- **Persistent tracking**: Remembers processed repositories to avoid duplicates.
- **Complete logging**: Detailed logging of operations.
- **Test mode**: `--dry-run` option to test without sending emails.

## 🚀 Installation

### Prerequisites

The script requires `curl`. `sendmail` is only required if you are not using an external SMTP server.

```bash
# For Debian/Ubuntu (if not using an external SMTP)
sudo apt-get update && sudo apt-get install curl sendmail

# For CentOS/RHEL (if not using an external SMTP)
sudo yum install curl sendmail
```

### Script Installation

1.  **Clone or download the script**:
    ```bash
    wget https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/main/gitlab-public-repo-monitor.sh
    chmod +x gitlab-public-repo-monitor.sh
    ```

2.  **Create and edit the configuration file**:
    ```bash
    cp config.conf.example config.conf
    nano config.conf
    ```

## ⚙️ Configuration

### Configuration Parameters

Edit the `config.conf` file to fit your environment.

| Parameter | Description | Example |
|---|---|---|
| `GITLAB_URL` | **(Required)** URL of your GitLab instance. | `https://gitlab.example.com` |
| `NOTIFICATION_LANGUAGE` | **(Required)** Notification language (`FR` or `EN`). | `EN` |
| `EMAIL_TO` | **(Required)** Destination email address. | `admin@example.com` |
| `EMAIL_FROM` | **(Required)** Sender email address. | `gitlab-monitor@example.com` |
| `SMTP_SERVER` | (Optional) Address of your SMTP server. | `smtp.example.com` |
| `SMTP_PORT` | (Optional) Port of your SMTP server. | `587` |
| `SMTP_USER` | (Optional) Username for SMTP authentication. | `user@example.com` |
| `SMTP_PASS` | (Optional) Password for SMTP authentication. | `s3cr3t` |
| `SMTP_TLS` | (Optional) Set to `true` to enable SMTPS. | `true` |

### SMTP Configuration (Optional)

If you do not want to use `sendmail`, you can configure the script to send emails via an external SMTP server. To do this, uncomment and fill in the `SMTP_*` variables in your `config.conf` file.

-   If `SMTP_SERVER` and `SMTP_PORT` are set, the script will use `curl` to send emails, and `sendmail` will no longer be necessary.
-   It is highly recommended to use a secure connection (`SMTP_TLS="true"`).

## 🖥️ Usage

### Manual Execution

```bash
# Normal execution
./gitlab-public-repo-monitor.sh

# Dry run mode (does not send emails but simulates detection)
./gitlab-public-repo-monitor.sh --dry-run

# Use a custom configuration file
./gitlab-public-repo-monitor.sh --config /path/to/custom.conf

# Display help
./gitlab-public-repo-monitor.sh --help
```

### Cron Scheduling

For continuous monitoring, add an entry to your crontab:

```bash
# Run the script every day at 8:00 AM
0 8 * * * /path/to/gitlab-public-repo-monitor.sh >> /var/log/gitlab-monitor.log 2>&1
```
