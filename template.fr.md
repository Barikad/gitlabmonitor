Bonjour, nous avons détecté la présence d'un dépôt Gitlab accessible publiquement.

C'est la première détection de ce dépôt et **vous ne serez plus notifié à l'avenir.**

| **Nom du dépôt:** $REPONAME | **Dernier commit par:** $REPODEV |
|---|---|
| **Publié à l'adresse:** $REPOURL | |
| **Présence d'une licence:** $URLLICENSE | |
| **Présence d'une documentation:** $URLREADME | **Présence d'un guide de contribution:** $URLCONTRIBUTING |

---

### ⚠️ Avertissement Important concernant les Dépôts Publics

Pour les dépôts accessible publiquement sur Internet, il est **impératif** de respecter les règles suivantes avant toute publication sur notre plateforme Gitlab:

1.  **Aucune Information Sensible ou Spécifique à notre organisation** :
    *   Les scripts publiés ne doivent contenir **aucune information spécifique à notre organisation**. Cela inclut, sans s'y limiter :
        *   Noms de groupes Active Directory/LDAP, noms d'utilisateurs, noms de machines, noms de domaines internes.
        *   Adresses IP internes, noms de serveurs, chemins de fichiers réseau spécifiques, schémas,
        *   **Absolument aucun secret** : mots de passe, clés API, certificats, identifiants, tokens, etc.
    *   Toute information qui pourrait identifier notre infrastructure ou nos pratiques internes doit être **abstraite, généralisée ou supprimée**.
    *   Afin de détecter la présence de secret, vous pouvez utiliser des solutions comme [FindSecretLeak](https://gitlab.villejuif.fr/depots-public/findsecretsleak).
2.  **Conditions d'Éligibilité à la Publication** :
    *   Seuls les scripts/codes **généralistes et réutilisables** dans n'importe quel environnement similaire sont éligibles à la publication publique.
    *   Les scripts doivent être conçus de manière à ne pas dépendre de configurations spécifiques à notre environnement. Si des configurations sont nécessaires, elles doivent être externalisées (ex: fichiers de configuration, paramètres de script) et documentées de manière générique.
3.  **Licence AGPLv3** :
    *   Tous les projets publiés publiquement seront automatiquement placés sous la **licence GNU Affero General Public License v3.0 (AGPLv3)**. Assurez-vous que votre code est compatible avec cette licence.
4.  **Fichier de Contribution** :
    *   Chaque projet publié doit contenir un fichier `CONTRIBUTING.md` à sa racine. Ce document doit expliquer clairement quelles sont les contribution souhaitées et sous quelles formes.
5.  **Documentation de Qualité (`README.md`)** :
    *   Le `README.md` doit être **complet, clair et utile**. Il doit inclure une description de l'objectif, le fonctionnement, les instructions d'installation, un tableau des paramètres, et des exemples d'utilisation. L'adjonction de badges ou d'une version bilingue (Francais/Anglais) peut être un plus.

Le non-respect de ces règles peut entraîner des risques de sécurité majeurs et la suppression immédiate du contenu publié.
