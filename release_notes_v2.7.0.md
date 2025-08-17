### 🎉 Release v2.7.0

Cette version majeure introduit plusieurs nouvelles fonctionnalités, des améliorations significatives de la documentation et des correctifs importants pour la génération des e-mails.

#### ✨ Nouvelles Fonctionnalités

*   **Mise en Copie de l'Auteur** : Une nouvelle variable `CC_COMMIT_AUTHOR` dans `config.conf` permet de mettre automatiquement en copie carbone l'auteur du dernier commit lors de l'envoi d'une notification.
*   **Templates d'Email Externes** : Le corps des e-mails est désormais géré via des fichiers templates HTML (`template.fr.md` et `template.en.md`), facilitant la personnalisation du contenu.

#### 🚀 Améliorations

*   **Documentation Complète** : Le `README.md` a été entièrement revu pour inclure une section de prérequis, des instructions d'installation via `git clone`, et des exemples d'utilisation avec `cron`.
*   **Tableau de Configuration** : La section de configuration dans le `README.md` a été remplacée par un tableau détaillé décrivant chaque paramètre.
*   **Sortie Améliorée** : Les logs et la sortie du script sont plus clairs, indiquant quels dépôts sont traités ou ignorés.

#### 🐛 Correctifs

*   **Encodage du Sujet** : Correction d'un bug majeur qui rendait le sujet des e-mails illisible pour les noms de dépôts longs. L'encodage MIME est désormais conforme au RFC 2047.
*   **Formatage du Corps HTML** : Correction d'un problème où la structure HTML de l'e-mail était incorrectement générée, ce qui pouvait altérer l'affichage.

---

### 🎉 Release v2.7.0

This major release introduces several new features, significant documentation improvements, and important fixes for email generation.

#### ✨ New Features

*   **CC Commit Author**: A new `CC_COMMIT_AUTHOR` variable in `config.conf` allows automatically CC'ing the author of the last commit when sending a notification.
*   **External Email Templates**: The email body is now managed via external HTML template files (`template.fr.md` and `template.en.md`), making content customization easier.

#### 🚀 Improvements

*   **Comprehensive Documentation**: The `README.md` has been completely overhauled to include a prerequisites section, installation instructions via `git clone`, and usage examples with `cron`.
*   **Configuration Table**: The configuration section in the `README.md` has been replaced with a detailed table describing each parameter.
*   **Enhanced Output**: The script's logs and output are clearer, indicating which repositories are being processed or skipped.

#### 🐛 Bug Fixes

*   **Subject Encoding**: Fixed a major bug that made email subjects unreadable for long repository names. MIME encoding is now compliant with RFC 2047.
*   **HTML Body Formatting**: Fixed an issue where the email's HTML structure was incorrectly generated, which could affect rendering.

---

### 📦 Fichiers de la Release

*   https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/v2.7.0/gitlab-public-repo-monitor.sh - gitlab-public-repo-monitor.sh
*   https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/v2.7.0/config.conf.example - config.conf.example
*   https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/v2.7.0/template.fr.md - template.fr.md
*   https://gitlab.villejuif.fr/depots-public/gitlabmonitor/-/raw/v2.7.0/template.en.md - template.en.md
