# GitHub Dorks for Bug Bounty Recon

Curated GitHub search queries for finding leaked secrets, credentials, and
internal documentation in the target's own public repositories and
organization.

---

## Legal Scope Reminder

> **Use only against the target organization's own public repos and
> members.** Searching private repos you don't have access to is
> unauthorized access. Searching unrelated organizations for the same
> secret type is a different bug — file it with the program that owns
> the secret, not with the program that owns the target.

For each dork below:

- `{org}` is the GitHub organization slug of the in-scope target
  (e.g. `acme-corp`).
- `{target}` is the root domain (e.g. `acme.com`).
- `{github_user}` is the username of a known engineer or the org handle.

Run from <https://github.com/search> or via the GitHub Search API
(`/search/code` and `/search/commits`).

---

## Authentication

GitHub code search requires authentication for higher rate limits and
better results. A personal access token (PAT) is mandatory for the search
API and gets you 30 req/min vs. 10 req/min unauthenticated.

```bash
# Quick PAT setup for the gh CLI
gh auth login
export GH_TOKEN=$(gh auth token)
```

For deep recon, use a fine-grained PAT with `Contents: Read` and
`Metadata: Read` on public repositories only.

---

## 1. API Keys

The most common find. Proving that a key is *active* and *privileged* is
what turns an Informational into a Critical (see
`rules/reporting.md` #5).

### AWS

```text
# AWS access key ID format
org:{org} "AKIA[0-9A-Z]{16}"

# AWS secret access key in assignment
org:{org} "aws_secret_access_key" OR "AWS_SECRET_ACCESS_KEY"

# Combined credentials block
org:{org} "aws_access_key_id" "aws_secret_access_key"
```

### Google Cloud

```text
org:{org} "AIza[0-9A-Za-z\-_]{35}"                # API key
org:{org} "type": "service_account"                # service account JSON
org:{org} "private_key_id"                         # GCP service account
org:{org} filename:*.json "client_email"           # exported service account
```

### Stripe

```text
org:{org} "sk_live_" OR "sk_test_"                 # Stripe secret key
org:{org} "pk_live_" OR "pk_test_"                 # publishable (lower value)
org:{org} "STRIPE_SECRET_KEY" OR "STRIPE_API_KEY"
org:{org} filename:.env "STRIPE"
```

### Slack

```text
org:{org} "xoxb-" OR "xoxp-" OR "xoxa-"            # Slack tokens
org:{org} "https://hooks.slack.com/services/"     # webhook URLs
org:{org} "SLACK_TOKEN" OR "SLACK_WEBHOOK"
```

### Other Common Services

```text
org:{org} "ghp_[0-9A-Za-z]{36}"                    # GitHub PAT
org:{org} "github_pat_[0-9A-Za-z_]{82}"            # fine-grained PAT
org:{org} "xoxb-"                                  # Slack bot
org:{org} "sk-" AND ("openai" OR "anthropic")      # LLM provider keys
org:{org} "SG."                                    # SendGrid
org:{org} "key-"                                   # Mailgun
org:{org} "https://hooks.slack.com/"
org:{org} "firebaseio.com"                         # Firebase DB URLs
org:{org} "AIza[0-9A-Za-z\-_]{35}"                # Google API key
org:{org} "ya29\."                                 # Google OAuth token
org:{org} "eyJ" filename:jwt.json                  # JWTs committed as files
```

---

## 2. Tokens

Tokens for registries, package managers, and CI providers.

```text
# npm
org:{org} "npm_token" OR "//registry.npmjs.org/:_authToken"

# PyPI
org:{org} "pypi" "password" OR "token" filename:.pypirc
org:{org} "pypi-AgEIcHlwaS5vcmc"                  # PyPI upload token

# Docker Hub
org:{org} "docker.io" "-password=" OR "DOCKER_PASSWORD"

# GitHub Actions
org:{org} path:.github/workflows "secrets." inurl:yaml
org:{org} "${{ secrets."                           # GH Actions secret refs
```

---

## 3. Credentials in Code

Hardcoded usernames, passwords, and connection strings.

```text
# Database connection strings
org:{org} "postgres://" OR "mysql://" OR "mongodb://" OR "redis://"
org:{org} "Server=" intext:"Password="             # MSSQL conn string
org:{org} "jdbc:" intext:"password"

# Generic credential assignment patterns
org:{org} "password" "=" inurl:.env
org:{org} "DB_PASSWORD" OR "DB_USER" OR "DATABASE_URL"
org:{org} "MAIL_PASSWORD" OR "SMTP_PASSWORD"

# PII in test fixtures or seed files
org:{org} "@{target}" intext:"password"            # emails with passwords
org:{org} "ssn" OR "social security" extension:csv
org:{org} "credit_card" OR "card_number" extension:csv
org:{org} filename:users.csv OR filename:customers.csv
```

---

## 4. Internal Documentation

Internal runbooks, architecture diagrams, and security policies often
make their way into public repos by accident.

```text
# Runbooks and oncall docs
org:{org} filename:RUNBOOK.md OR filename:ONCALL.md OR filename:INCIDENT.md
org:{org} "pagerduty" OR "pagerduty.com"           # oncall references

# Architecture and design docs
org:{org} filename:ARCHITECTURE.md OR filename:DESIGN.md
org:{org} "internal-" inurl:docs
org:{org} "wiki/" intext:"password" OR intext:"api key"

# Security policies and threat models
org:{org} filename:SECURITY.md OR filename:THREAT_MODEL.md
org:{org} "vulnerability" "disclosure" filetype:md
org:{org} "responsible disclosure"

# Internal Slack/Linear/Jira URLs
org:{org} "{target}.slack.com"
org:{org} "linear.app/{org}/"
org:{org} "atlassian.net" OR "jira.{target}"
```

---

## 5. `.env` Files and Dotfiles

The single highest-signal file to look for.

```text
# Direct .env file hits
org:{org} filename:.env
org:{org} filename:.env.local OR filename:.env.production OR filename:.env.prod
org:{org} filename:env.example                      # usually still has structure hints
org:{org} filename:.env.bak OR filename:env.backup

# Common secrets in env files
org:{org} filename:.env "SECRET" OR "KEY" OR "TOKEN" OR "PASSWORD"

# Docker and compose
org:{org} filename:docker-compose.yml "environment:"
org:{org} filename:docker-compose.yaml "env_file:"

# Kubernetes secrets
org:{org} filename:secret.yaml OR filename:secrets.yaml
org:{org} "kind: Secret" path:manifests
```

---

## 6. Private Keys

```text
# PEM-encoded private keys
org:{org} "-----BEGIN RSA PRIVATE KEY-----"
org:{org} "-----BEGIN PRIVATE KEY-----"
org:{org} "-----BEGIN EC PRIVATE KEY-----"
org:{org} "-----BEGIN OPENSSH PRIVATE KEY-----"
org:{org} "-----BEGIN DSA PRIVATE KEY-----"

# SSH keys in known locations
org:{org} filename:id_rsa OR filename:id_dsa OR filename:id_ecdsa
org:{org} filename:id_rsa.pub
org:{org} filename:*.pem OR filename:*.key
org:{org} filename:server.key OR filename:private.key

# PGP / GPG
org:{org} "-----BEGIN PGP PRIVATE KEY BLOCK-----"
```

---

## 7. Mobile and Build Artifacts

```text
# Hardcoded API keys in iOS / Android source
org:{org} "api_key" extension:swift OR extension:kt OR extension:java
org:{org} "API_KEY" extension:plist
org:{org} "google-services.json"
org:{org} "GoogleService-Info.plist"

# Webhook URLs and third-party integrations
org:{org} "stripe.com" "sk_"
org:{org} "twilio" "AC"                             # Twilio account SID
org:{org} "twilio" "auth_token"
```

---

## 8. Search by Author or Path

When you know the engineer or the monorepo layout, narrow the search.

```text
# Author-scoped (find a specific engineer's commits)
user:{github_user} "password" OR "api_key" OR "token"

# Path-scoped (find secrets in a known monorepo subdir)
org:{org} path:services/ filename:.env
org:{org} path:backend/ "DATABASE_URL"
org:{org} path:terraform/ "aws_access_key"
org:{org} path:k8s/ filename:secret.yaml

# File-extension-scoped
org:{org} extension:json "client_secret"
org:{org} extension:yaml "password:"
org:{org} extension:toml "secret"
```

---

## 9. Commit History Dorking

Secrets often appear in commits even after being removed from the current
tree. Use the GitHub Events API or tools like `trufflehog` and `gitleaks`
to walk history.

```text
# GitHub commit search
org:{org} "AKIA" inurl:commit
org:{org} "BEGIN RSA PRIVATE KEY" inurl:commit

# Tooling: gitleaks across the org
gitleaks detect --org {org} --no-banner -v

# Tooling: trufflehog across the org
trufflehog github --org={org} --only-verified
```

---

## Validation Workflow

Finding a secret is Informational. Proving it works is what pays.

```text
1. Read the secret. Note the service and key ID.
2. Call the *minimum* API the key supports.
   - AWS:    aws sts get-caller-identity
   - GCP:    gcloud auth activate-service-account --key-file=...
   - Stripe: curl https://api.stripe.com/v1/charges?limit=1 -u sk_live_...
   - Slack:  curl https://slack.com/api/auth.test -H "Authorization: Bearer xoxb-..."
3. Enumerate permissions and reachable resources.
4. Stop at the first proof of access. Do not exfiltrate data.
5. Document the call, the response, and the blast radius.
```

> **Rule of thumb:** a leaked key without a working call = N/A. A leaked
> key with a working call that touches user data = Medium to Critical
> depending on what it reaches.

---

## Quick Combos

Three queries to start every GitHub recon against an in-scope target.

```text
# Combo 1: Direct credential files
org:{org} (filename:.env OR filename:id_rsa OR "BEGIN PRIVATE KEY" OR "AKIA")

# Combo 2: All cloud-provider-style keys in code
org:{org} ("AKIA" OR "AIza" OR "sk_live_" OR "ghp_" OR "xoxb-")

# Combo 3: Internal docs and runbooks
org:{org} (filename:RUNBOOK.md OR filename:ARCHITECTURE.md OR "wiki/" OR "internal-")
```

---

## Safety Notes

- **Search only the in-scope org.** Searching other orgs that happen to
  mention `{target}` is a different engagement.
- **Do not clone private repos you don't have access to.** Public code
  search only.
- **Treat every secret as if it's already public.** Once indexed, it is.
- **Do not interact with leaked infra beyond minimum proof.** The
  program policy usually restricts this strictly.
- **Strip PII before reporting.** A leaked customer email in a
  screenshot is itself a problem; redact it.
