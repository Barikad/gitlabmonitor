# Changelog

Toutes les modifications notables apportées à ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [2.8.0] - 2025-08-21

### Ajouté
- **Installation Automatisée :** Ajout d'un script `install.sh` pour une installation rapide avec `curl`.
- **Procédure de Mise à Jour :** Ajout d'une fonction `--upgrade` au script principal pour des mises à jour intelligentes et sécurisées.
- **Internationalisation :** Les scripts `install.sh` et `gitlab-public-repo-monitor.sh` sont maintenant entièrement bilingues (Français/Anglais) pour les interactions utilisateur.

### Modifié
- **CI/CD :** Le pipeline utilise maintenant `glab` (l'outil officiel) et un runner Docker pour créer les releases, améliorant la fiabilité.
- **Documentation :** Le `README.md` a été entièrement revu pour refléter les nouvelles procédures d'installation et de mise à jour.

### Corrigé
- **Compatibilité :** Le script principal est maintenant compatible avec `bash` et `sh`.
- **Fiabilité :** Nombreuses corrections dans le script d'installation pour gérer les cas où le répertoire existe déjà.

## [2.7.1] - 2025-08-17

### Documentation
- Ajout des notes de version pour la v2.7.1.

### CI/CD
- Ajout d'un pipeline GitLab CI/CD pour la création automatisée des releases.

## [2.7.0] - (Date approximative)

### Ajouté
- **Internationalisation :** Ajout de commentaires bilingues (FR/EN) dans le script et la configuration.
- **Documentation :** Ajout d'exemples visuels des rapports par email.
- **Templates :** Externalisation des templates d'email dans des fichiers `.md` séparés.
- **Mode Debug :** Ajout d'une option `--debug` pour un logging plus verbeux.
- **Notification Auteur :** Ajout d'une option `CC_COMMIT_AUTHOR` pour mettre en copie l'auteur du dernier commit.
- **Amélioration des logs :** Amélioration de la sortie terminal et des détails dans les logs.
- **Pied de page :** Ajout d'un pied de page dans l'email pour identifier le script.

### Modifié
- **Refactorisation Majeure :** Remplacement du "scraping" HTML par l'utilisation de l'**API GitLab officielle**, améliorant considérablement la fiabilité.
- **Refactorisation Email :** Amélioration majeure de la génération des emails, de la conversion en HTML et de la gestion des en-têtes MIME pour les sujets longs.
- **Fiabilité :** Nombreuses corrections pour rendre les boucles de traitement plus robustes, mieux gérer les erreurs `curl` et la substitution de variables.

### Corrigé
- **Logs :** Redirection des logs sur `stderr` pour ne pas corrompre la sortie JSON.
- **Parsing :** Utilisation d'une boucle `while-read` robuste pour le traitement du JSON.
- **Dry Run :** Correction de la logique du mode `--dry-run`.
- **Encodage :** Correction de l'encodage des sujets d'email en base64 sur une seule ligne.

## [2.6.0] - (Date approximative)

### Ajouté
- **Support SMTP :** Ajout de la possibilité d'envoyer des emails via un serveur SMTP externe.

### Documentation
- Mise à jour du badge de version à v2.6.0.
- Documentation de la fonctionnalité SMTP.

## [Versions Initiales]

### Ajouté
- Création initiale du projet.
- Préparation pour la publication en tant que dépôt public.