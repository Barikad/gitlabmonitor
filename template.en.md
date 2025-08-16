### ⚠️ Important Warning Regarding Public Repositories

For repositories accessible publicly on the Internet, it is **imperative** to adhere to the following rules before any publication on our GitLab platform:

1.  **No Sensitive or Organization-Specific Information**:
    *   Published scripts must not contain **any information specific to our organization**. This includes, but is not limited to:
        *   Active Directory/LDAP group names, usernames, machine names, internal domain names.
        *   Internal IP addresses, server names, specific network file paths, schemas.
        *   **Absolutely no secrets**: passwords, API keys, certificates, credentials, tokens, etc.
    *   Any information that could identify our infrastructure or internal practices must be **abstracted, generalized, or removed**.
    *   To detect the presence of secrets, you can use solutions like [Gitleaks](https://github.com/gitleaks/gitleaks) or, for a lighter option, [FindSecretLeak](https://gitlab.villejuif.fr/depots-public/findsecretsleak).
2.  **Eligibility Requirements for Publication**:
    *   Only **general-purpose and reusable** scripts/code that can be used in any similar environment are eligible for public release.
    *   Scripts must be designed not to depend on configurations specific to our environment. If configurations are necessary, they must be externalized (e.g., config files, script parameters) and documented generically.
3.  **AGPLv3 License**:
    *   All publicly published projects will automatically be licensed under the **GNU Affero General Public License v3.0 (AGPLv3)**. Ensure that your code is compatible with this license.
4.  **Contribution File**:
    *   Each published project must contain a `CONTRIBUTING.md` file at its root. This document must clearly explain what contributions are desired and in what form.
5.  **Quality Documentation (`README.md`)**:
    *   The `README.md` must be **complete, clear, and useful**. It should include a description of the objective, how it works, installation instructions, a parameter table, and usage examples. Adding badges or a bilingual version (French/English) can be a plus.

Failure to comply with these rules may lead to major security risks and the immediate deletion of the published content.