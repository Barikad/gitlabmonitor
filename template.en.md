Hello, we have detected the presence of a publicly accessible GitLab repository.

This is the first detection of this repository and **you will not be notified again in the future.**

| **Repository name:** $REPONAME | **Last commit by:** $REPODEV |
|---|---|
| **Published at:** $REPOURL | |
| **License present:** $URLLICENSE | |
| **Documentation present:** $URLREADME | **Contribution guide present:** $URLCONTRIBUTING |

---

### ⚠️ Important Warning Regarding Public Repositories

For repositories publicly accessible on the Internet, it is **imperative** to follow these rules before any publication on our GitLab platform:

1.  **No Sensitive or Organization-Specific Information** :
    *   Published scripts must not contain **any organization-specific information**. This includes, but is not limited to:
        *   Active Directory/LDAP group names, usernames, machine names, internal domain names.
        *   Internal IP addresses, server names, specific network file paths, schemas,
        *   **Absolutely no secrets**: passwords, API keys, certificates, credentials, tokens, etc.
    *   Any information that could identify our infrastructure or internal practices must be **abstracted, generalized, or removed**.
    *   To detect the presence of secrets, you can use solutions like [FindSecretLeak](https://gitlab.villejuif.fr/depots-public/findsecretsleak).
2.  **Publication Eligibility Conditions** :
    *   Only **generic and reusable** scripts/code in any similar environment are eligible for public publication.
    *   Scripts must be designed not to depend on configurations specific to our environment. If configurations are necessary, they must be externalized (e.g., configuration files, script parameters) and documented generically.
3.  **AGPLv3 License** :
    *   All publicly published projects will be automatically placed under the **GNU Affero General Public License v3.0 (AGPLv3)**. Ensure your code is compatible with this license.
4.  **Contribution File** :
    *   Each published project must contain a `CONTRIBUTING.md` file at its root. This document must clearly explain what contributions are desired and in what forms.
5.  **Quality Documentation (`README.md`)** :
    *   The `README.md` must be **complete, clear, and useful**. It must include a description of the objective, operation, installation instructions, parameter table, and usage examples. Adding badges or a bilingual version (French/English) can be a plus.

Non-compliance with these rules can lead to major security risks and immediate removal of published content.
