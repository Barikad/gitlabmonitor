# Changelog

Toutes les modifications notables apportées à ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [2.7.2] - 2025-08-21

### CI/CD
- **Correction Majeure :** Remplacement de `release-cli` (déprécié) par `glab` pour la création des releases.
- **Fiabilisation :** Le pipeline utilise maintenant un runner Docker (`VJUNIXINFRA`) et une authentification robuste pour `glab`.
- **URL Stable :** Le pipeline génère maintenant une archive `gitlab-monitor-latest.tar.gz` et le `README.md` pointe vers le lien de téléchargement permanent.

### Documentation
- **README :** Mise à jour du badge de version et ajout d'une commande `curl` pour le téléchargement direct.
- **Script :** Ajout des URLs du dépôt et du téléchargement dans l'en-tête du script.


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
