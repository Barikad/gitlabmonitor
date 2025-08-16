<p>Bonjour, nous avons détecté la présence d'un dépôt Gitlab accessible publiquement.</p>
<p>C'est la première détection de ce dépôt et <strong>vous ne serez plus notifié à l'avenir.</strong></p>
<table>
    <tr><th>Nom du dépôt:</th><td>$REPONAME</td></tr>
    <tr><th>Dernier commit par:</th><td>$REPODEV</td></tr>
    <tr><th>Publié à l'adresse:</th><td><a href="$REPOURL">$REPOURL</a></td></tr>
    <tr><th>Présence d'une licence:</th><td>$HAS_LICENSE</td></tr>
    <tr><th>Présence d'une documentation:</th><td>$HAS_README</td></tr>
    <tr><th>Présence d'un guide de contribution:</th><td>$HAS_CONTRIBUTING</td></tr>
</table>
<hr>
<h3>⚠️ Avertissement Important concernant les Dépôts Publics</h3>
<p>Pour les dépôts accessible publiquement sur Internet, il est <strong>impératif</strong> de respecter les règles suivantes avant toute publication sur notre plateforme Gitlab:</p>
<ol>
    <li><strong>Aucune Information Sensible ou Spécifique à notre organisation</strong> :
        <ul>
            <li>Les scripts publiés ne doivent contenir <strong>aucune information spécifique à notre organisation</strong>. Cela inclut, sans s'y limiter :
                <ul>
                    <li>Noms de groupes Active Directory/LDAP, noms d'utilisateurs, noms de machines, noms de domaines internes.</li>
                    <li>Adresses IP internes, noms de serveurs, chemins de fichiers réseau spécifiques, schémas.</li>
                    <li><strong>Absolument aucun secret</strong> : mots de passe, clés API, certificats, identifiants, tokens, etc.</li>
                </ul>
            </li>
            <li>Toute information qui pourrait identifier notre infrastructure ou nos pratiques internes doit être <strong>abstraite, généralisée ou supprimée</strong>.</li>
            <li>Afin de détecter la présence de secret, vous pouvez utiliser des solutions comme <a href="https://github.com/gitleaks/gitleaks">GitLeak</a> ou, en plus léger, <a href="https://gitlab.villejuif.fr/depots-public/findsecretsleak">FindSecretLeak</a>.</li>
        </ul>
    </li>
    <li><strong>Conditions d'Éligibilité à la Publication</strong> :
        <ul>
            <li>Seuls les scripts/codes <strong>généralistes et réutilisables</strong> dans n'importe quel environnement similaire sont éligibles à la publication publique.</li>
            <li>Les scripts doivent être conçus de manière à ne pas dépendre de configurations spécifiques à notre environnement. Si des configurations sont nécessaires, elles doivent être externalisées (ex: fichiers de configuration, paramètres de script) et documentées de manière générique.</li>
        </ul>
    </li>
    <li><strong>Licence AGPLv3</strong> :
        <ul>
            <li>Tous les projets publiés publiquement seront automatiquement placés sous la <strong>licence GNU Affero General Public License v3.0 (AGPLv3)</strong>. Assurez-vous que votre code est compatible avec cette licence.</li>
        </ul>
    </li>
    <li><strong>Fichier de Contribution</strong> :
        <ul>
            <li>Chaque projet publié doit contenir un fichier <code>CONTRIBUTING.md</code> à sa racine. Ce document doit expliquer clairement quels sont les contribution souhaitées et sous quelles formes.</li>
        </ul>
    </li>
    <li><strong>Documentation de Qualité (<code>README.md</code>)</strong> :
        <ul>
            <li>Le <code>README.md</code> doit être <strong>complet, clair et utile</strong>. Il doit inclure une description de l'objectif, le fonctionnement, les instructions d'installation, un tableau des paramètres, et des exemples d'utilisation. L'adjonction de badges ou d'une version bilingue (Francais/Anglais) peut être un plus.</li>
        </ul>
    </li>
</ol>
<p>Le non-respect de ces règles peut entraîner des risques de sécurité majeurs et la suppression immédiate du contenu publié.</p>