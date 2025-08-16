<p>Hello, we have detected a publicly accessible GitLab repository.</p>
<p>This is the first time this repository has been detected, and <strong>you will not be notified again in the future.</strong></p>
<table>
    <tr><th>Repository Name:</th><td>$REPONAME</td></tr>
    <tr><th>Last commit by:</th><td>$REPODEV</td></tr>
    <tr><th>Published at:</th><td><a href="$REPOURL">$REPOURL</a></td></tr>
    <tr><th>License file present:</th><td>$HAS_LICENSE</td></tr>
    <tr><th>Documentation present:</th><td>$HAS_README</td></tr>
    <tr><th>Contribution guide present:</th><td>$HAS_CONTRIBUTING</td></tr>
</table>
<hr>
<h3>⚠️ Important Warning Regarding Public Repositories</h3>
<p>For repositories accessible to the public on the Internet, it is <strong>imperative</strong> to adhere to the following rules before any publication on our GitLab platform:</p>
<ol>
    <li><strong>No Sensitive or Organization-Specific Information</strong>:
        <ul>
            <li>Published scripts must not contain <strong>any information specific to our organization</strong>. This includes, but is not limited to:
                <ul>
                    <li>Active Directory/LDAP group names, usernames, machine names, internal domain names.</li>
                    <li>Internal IP addresses, server names, specific network file paths, schemas.</li>
                    <li><strong>Absolutely no secrets</strong>: passwords, API keys, certificates, credentials, tokens, etc.</li>
                </ul>
            </li>
            <li>Any information that could identify our infrastructure or internal practices must be <strong>abstracted, generalized, or removed</strong>.</li>
            <li>To detect the presence of secrets, you can use solutions like <a href="https://github.com/gitleaks/gitleaks">GitLeak</a> or, for a lighter option, <a href="https://gitlab.villejuif.fr/depots-public/findsecretsleak">FindSecretLeak</a>.</li>
        </ul>
    </li>
    <li><strong>Eligibility for Publication</strong>:
        <ul>
            <li>Only <strong>general-purpose and reusable</strong> scripts/code that can be used in any similar environment are eligible for public release.</li>
            <li>Scripts must be designed not to depend on configurations specific to our environment. If configurations are necessary, they must be externalized (e.g., config files, script parameters) and documented generically.</li>
        </ul>
    </li>
    <li><strong>AGPLv3 License</strong>:
        <ul>
            <li>All publicly published projects will automatically be licensed under the <strong>GNU Affero General Public License v3.0 (AGPLv3)</strong>. Ensure your code is compatible with this license.</li>
        </ul>
    </li>
    <li><strong>Contribution File</strong>:
        <ul>
            <li>Each published project must contain a <code>CONTRIBUTING.md</code> file at its root. This document must clearly explain what contributions are desired and in what form.</li>
        </ul>
    </li>
    <li><strong>Quality Documentation (<code>README.md</code>)</strong>:
        <ul>
            <li>The <code>README.md</code> must be <strong>complete, clear, and useful</strong>. It should include a description of the objective, how it works, installation instructions, a parameter table, and usage examples. Adding badges or a bilingual version (French/English) can be a plus.</li>
        </ul>
    </li>
</ol>
<p>Failure to comply with these rules can lead to major security risks and the immediate removal of the published content.</p>