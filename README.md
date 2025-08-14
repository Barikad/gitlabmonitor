# GitLab Public Repository Monitor

[![License: AGPLv3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Shell Script](https://img.shields.io/badge/Language-Shell-green.svg)](https://www.gnu.org/lang/shell)
[![Version](https://img.shields.io/badge/Version-1.0-blue.svg)](https://gitlab.villejuif.fr/depots-public/gitlabmonitor)

Un script shell robuste pour surveiller automatiquement l'apparition de nouveaux dépôts publics sur une instance GitLab et envoyer des notifications par email lors de leur première détection.

**[English version below](#english-version)**

---

## 📋 Fonctionnalités

- **Surveillance automatique** : Détecte les nouveaux dépôts publics sur GitLab
- **Notification unique** : Envoie un email seulement lors de la première détection
- **Support bilingue** : Messages en français ou anglais selon la configuration
- **Informations détaillées** : Collecte automatiquement les métadonnées des dépôts
- **Template personnalisable** : Message email configurable en Markdown
- **Suivi persistent** : Mémorise les dépôts déjà traités
- **Logging complet** : Journalisation détaillée des opérations
- **Mode test** : Option dry-run pour tester sans envoyer d'emails
- **Portable** : Compatible avec la plupart des distributions Linux

## 🚀 Installation

### Prérequis

Le script nécessite les outils suivants :

```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install curl sendmail

# CentOS/RHEL/Rocky
sudo yum install curl sendmail

# Alpine Linux
sudo apk add curl ssmtp
```

### Installation du script

1. **Clonez ou téléchargez le script** :
```bash
wget https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/main/gitlab-public-repo-monitor.sh
chmod +x gitlab-public-repo-monitor.sh
```

2. **Copiez le fichier de configuration** :
```bash
cp config.conf.example config.conf
```

3. **Éditez la configuration** :
```bash
nano config.conf
```

## ⚙️ Configuration

### Paramètres obligatoires

Éditez le fichier `config.conf` et configurez au minimum :

| Paramètre | Description | Exemple |
|-----------|-------------|---------|
| `GITLAB_URL` | URL de votre instance GitLab | `https://gitlab.example.com` |
| `NOTIFICATION_LANGUAGE` | Langue des notifications (FR ou EN) | `FR` |
| `EMAIL_TO` | Adresse de destination | `admin@example.com` |
| `EMAIL_FROM` | Adresse d'expéditeur | `gitlab-monitor@example.com` |

### Accès aux dépôts publics

Le script utilise l'interface web standard de GitLab (`/explore/projects`) pour découvrir les dépôts publics. **Aucun token d'authentification n'est nécessaire** car il accède uniquement aux informations publiquement disponibles.

### Template email

Le script supporte deux langues pour les notifications. Le template email supporte les variables suivantes :

| Variable | Description |
|----------|-------------|
| `$REPONAME` | Nom du dépôt |
| `$REPODEV` | Dernier développeur (dernier commit) |
| `$REPOURL` | URL web du dépôt |
| `$URLLICENSE` | Présence d'un fichier LICENSE (✅/❌) |
| `$URLREADME` | Présence d'un fichier README.md (✅/❌) |
| `$URLCONTRIBUTING` | Présence d'un fichier CONTRIBUTING.md (✅/❌) |

**Configuration de la langue :**
```bash
# Dans config.conf
NOTIFICATION_LANGUAGE="FR"  # ou "EN" pour anglais
```

## 🖥️ Utilisation

### Exécution manuelle

```bash
# Exécution normale
./gitlab-public-repo-monitor.sh

# Mode test (pas d'envoi d'email)
./gitlab-public-repo-monitor.sh --dry-run

# Avec fichier de config personnalisé
./gitlab-public-repo-monitor.sh --config /path/to/custom-config.conf

# Afficher l'aide
./gitlab-public-repo-monitor.sh --help
```

### Planification avec Cron

Pour une surveillance automatique, ajoutez une entrée cron :

```bash
# Éditer la crontab
crontab -e

# Exécuter tous les jours à 9h00
0 9 * * * /path/to/gitlab-public-repo-monitor.sh >/dev/null 2>&1

# Exécuter toutes les heures
0 * * * * /path/to/gitlab-public-repo-monitor.sh >/dev/null 2>&1

# Exécuter tous les lundi à 8h30 avec logs
30 8 * * 1 /path/to/gitlab-public-repo-monitor.sh >> /var/log/gitlab-monitor-cron.log 2>&1
```

### Exemple de planification avancée

```bash
# Fichier: /etc/cron.d/gitlab-monitor
# Surveillance quotidienne avec rotation des logs
0 9 * * * root /opt/scripts/gitlab-public-repo-monitor.sh && logrotate /etc/logrotate.d/gitlab-monitor
```

## 📁 Structure des fichiers

```
gitlab-public-repo-monitor/
├── gitlab-public-repo-monitor.sh    # Script principal
├── config.conf                      # Configuration (à créer)
├── config.conf.example              # Exemple de configuration
├── tracked_repos.txt                # Liste des dépôts traités (auto-généré)
├── gitlab-monitor.log               # Fichier de log (auto-généré)
├── README.md                        # Cette documentation
└── CONTRIBUTING.md                  # Guide de contribution
```

## 🔍 Monitoring et Logs

### Fichiers de log

- **gitlab-monitor.log** : Log principal avec horodatage et niveaux
- **tracked_repos.txt** : Liste des IDs de dépôts déjà traités

### Niveaux de log

```bash
2025-01-15 09:00:01 [INFO] === Début de l'exécution du monitoring GitLab ===
2025-01-15 09:00:02 [INFO] Trouvé 15 projets publics
2025-01-15 09:00:03 [INFO] Nouveau dépôt détecté: 42
2025-01-15 09:00:04 [SUCCESS] Email envoyé avec succès pour le dépôt
2025-01-15 09:00:05 [INFO] === Fin de l'exécution du monitoring GitLab ===
```

### Surveillance des logs

```bash
# Suivre les logs en temps réel
tail -f gitlab-monitor.log

# Filtrer les erreurs
grep ERROR gitlab-monitor.log

# Statistiques
grep "nouveaux dépôts" gitlab-monitor.log | tail -10
```

## 🛠️ Dépannage

### Problèmes courants

#### 1. Problème de connexion à GitLab
```bash
# Tester l'accès à la page d'exploration
curl -s https://gitlab.example.com/explore/projects | head -20

# Réponse attendue : contenu HTML de la page
```

#### 2. Échec d'envoi d'email
```bash
# Tester sendmail
echo "Test" | sendmail -v votre@email.com

# Vérifier la configuration SMTP
sudo systemctl status sendmail
```

#### 3. Dépendances manquantes
```bash
# Vérifier les dépendances
./gitlab-public-repo-monitor.sh --help

# Installer manuellement
sudo apt-get install curl sendmail-bin
```

### Débogage

```bash
# Test d'accès à GitLab
curl -v https://gitlab.example.com/explore/projects

# Test avec un projet spécifique
# Vérifiez manuellement qu'un projet est accessible

# Vérification de la configuration
bash -n gitlab-public-repo-monitor.sh  # Vérification syntaxique
```

## 🔒 Sécurité

### Bonnes pratiques

1. **Permissions de fichiers** :
```bash
chmod 600 config.conf          # Config lisible par propriétaire uniquement
chmod 755 gitlab-public-repo-monitor.sh  # Script exécutable
```

2. **Token GitLab** :
   - Le script n'utilise pas de token (accès aux dépôts publics uniquement)
   - Aucune authentification nécessaire

3. **Logs** :
   - Vérifiez que les logs ne contiennent pas d'informations sensibles
   - Configurez une rotation des logs appropriée

### Considérations de sécurité

- Le script ne stocke aucun secret en dur dans le code
- Les appels HTTP utilisent HTTPS
- Aucune authentification nécessaire (dépôts publics uniquement)
- Aucune donnée sensible n'est loggée

## 📊 Exemples d'email généré

Voici un aperçu du type d'email généré :

**Sujet :** ⚠️ Nouveau dépôt public détecté: MyProject

Le message contient automatiquement toutes les informations du dépôt dans le format configuré, avec les avertissements de sécurité appropriés.

---

# English Version

# GitLab Public Repository Monitor

A robust shell script to automatically monitor the appearance of new public repositories on a GitLab instance and send email notifications upon their first detection.

## 📋 Features

- **Automatic monitoring**: Detects new public repositories on GitLab
- **Unique notification**: Sends email only on first detection
- **Bilingual support**: Messages in French or English according to configuration
- **Detailed information**: Automatically collects repository metadata
- **Customizable template**: Configurable email message in Markdown
- **Persistent tracking**: Remembers already processed repositories
- **Complete logging**: Detailed operation logging
- **Test mode**: Dry-run option to test without sending emails
- **Portable**: Compatible with most Linux distributions

## 🚀 Installation

### Prerequisites

The script requires the following tools:

```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install curl sendmail

# CentOS/RHEL/Rocky
sudo yum install curl sendmail

# Alpine Linux
sudo apk add curl ssmtp
```

### Script Installation

1. **Clone or download the script**:
```bash
wget https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/main/gitlab-public-repo-monitor.sh
chmod +x gitlab-public-repo-monitor.sh
```

2. **Copy the configuration file**:
```bash
cp config.conf.example config.conf
```

3. **Edit the configuration**:
```bash
nano config.conf
```

## ⚙️ Configuration

### Required Parameters

Edit the `config.conf` file and configure at minimum:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `GITLAB_URL` | Your GitLab instance URL | `https://gitlab.example.com` |
| `NOTIFICATION_LANGUAGE` | Notification language (FR or EN) | `EN` |
| `EMAIL_TO` | Destination address | `admin@example.com` |
| `EMAIL_FROM` | Sender address | `gitlab-monitor@example.com` |

### Public Repository Access

The script uses GitLab's standard web interface (`/explore/projects`) to discover public repositories. **No authentication token is required** as it only accesses publicly available information.

### Email Template

The script supports two languages for notifications. The email template supports the following variables:

| Variable | Description |
|----------|-------------|
| `$REPONAME` | Repository name |
| `$REPODEV` | Last developer (last commit) |
| `$REPOURL` | Repository web URL |
| `$URLLICENSE` | LICENSE file presence (✅/❌) |
| `$URLREADME` | README.md file presence (✅/❌) |
| `$URLCONTRIBUTING` | CONTRIBUTING.md file presence (✅/❌) |

**Language Configuration:**
```bash
# In config.conf
NOTIFICATION_LANGUAGE="EN"  # or "FR" for French
```

## 🖥️ Usage

### Manual Execution

```bash
# Normal execution
./gitlab-public-repo-monitor.sh

# Test mode (no email sending)
./gitlab-public-repo-monitor.sh --dry-run

# With custom config file
./gitlab-public-repo-monitor.sh --config /path/to/custom-config.conf

# Show help
./gitlab-public-repo-monitor.sh --help
```

### Cron Scheduling

For automatic monitoring, add a cron entry:

```bash
# Edit crontab
crontab -e

# Run daily at 9:00 AM
0 9 * * * /path/to/gitlab-public-repo-monitor.sh >/dev/null 2>&1

# Run every hour
0 * * * * /path/to/gitlab-public-repo-monitor.sh >/dev/null 2>&1

# Run every Monday at 8:30 AM with logs
30 8 * * 1 /path/to/gitlab-public-repo-monitor.sh >> /var/log/gitlab-monitor-cron.log 2>&1
```

### Advanced Scheduling Example

```bash
# File: /etc/cron.d/gitlab-monitor
# Daily monitoring with log rotation
0 9 * * * root /opt/scripts/gitlab-public-repo-monitor.sh && logrotate /etc/logrotate.d/gitlab-monitor
```

## 📁 File Structure

```
gitlab-public-repo-monitor/
├── gitlab-public-repo-monitor.sh    # Main script
├── config.conf                      # Configuration (to create)
├── config.conf.example              # Configuration example
├── tracked_repos.txt                # Processed repositories list (auto-generated)
├── gitlab-monitor.log               # Log file (auto-generated)
├── README.md                        # This documentation
└── CONTRIBUTING.md                  # Contribution guide
```

## 🔍 Monitoring and Logs

### Log Files

- **gitlab-monitor.log**: Main log with timestamps and levels
- **tracked_repos.txt**: List of already processed repository IDs

### Log Levels

```bash
2025-01-15 09:00:01 [INFO] === GitLab monitoring execution start ===
2025-01-15 09:00:02 [INFO] Found 15 public projects
2025-01-15 09:00:03 [INFO] New repository detected: 42
2025-01-15 09:00:04 [SUCCESS] Email sent successfully for repository
2025-01-15 09:00:05 [INFO] === GitLab monitoring execution end ===
```

### Log Monitoring

```bash
# Follow logs in real time
tail -f gitlab-monitor.log

# Filter errors
grep ERROR gitlab-monitor.log

# Statistics
grep "new repositories" gitlab-monitor.log | tail -10
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. GitLab Connection Error
```bash
# Test access to exploration page
curl -s https://gitlab.example.com/explore/projects | head -20

# Expected response: HTML content of the page
```

#### 2. Email Sending Failure
```bash
# Test sendmail
echo "Test" | sendmail -v your@email.com

# Check SMTP configuration
sudo systemctl status sendmail
```

#### 3. Missing Dependencies
```bash
# Check dependencies
./gitlab-public-repo-monitor.sh --help

# Install manually
sudo apt-get install curl sendmail-bin
```

### Debugging

```bash
# Test GitLab access
curl -v https://gitlab.example.com/explore/projects

# Test with specific project
# Manually check that a project is accessible

# Configuration verification
bash -n gitlab-public-repo-monitor.sh  # Syntax check
```

## 🔒 Security

### Best Practices

1. **File Permissions**:
```bash
chmod 600 config.conf          # Config readable by owner only
chmod 755 gitlab-public-repo-monitor.sh  # Executable script
```

2. **GitLab Token**:
   - The script doesn't use tokens (public repositories access only)
   - No authentication required

3. **Logs**:
   - Verify logs don't contain sensitive information
   - Configure appropriate log rotation

### Security Considerations

- The script stores no hardcoded secrets in code
- HTTP calls use HTTPS
- No authentication required (public repositories only)
- No sensitive data is logged

## 📊 Generated Email Example

Here's a preview of the type of email generated:

**Subject:** ⚠️ New public repository detected: MyProject

The message automatically contains all repository information in the configured format, with appropriate security warnings.⚠️