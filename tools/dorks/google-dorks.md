# Google Dorks for Bug Bounty Recon

Curated Google dorks for finding exposed assets, sensitive files, and
misconfigured services on in-scope targets only.

---

## Legal Scope Reminder

> **Use only against targets explicitly listed in the bug bounty program's
> published scope.** Dorking third-party services that a target happens to
> use is out of scope and grounds for a permanent ban. When in doubt,
> re-read `programs/{target}/scope.md` and the program policy page before
> running any of these queries.

Each dork is paired with a short note describing what it surfaces. The
target placeholder is `{target}` — substitute the in-scope root domain.

---

## 1. Exposed Files

Configuration and source control files that should never be web-accessible
are often left over from deployments, CI artifacts, or backups.

```text
# .env files (environment variables, API keys, DB creds)
site:{target} filetype:env OR intext:"DB_PASSWORD" | "API_KEY" | "SECRET_KEY"

# wp-config.php (WordPress database credentials)
site:{target} inurl:wp-config.php -github

# .git directory exposure (full source code disclosure)
site:{target} inurl:".git" ext:git OR intitle:"index of" ".git"

# Backup files (sql, tar, zip, bak)
site:{target} (ext:sql | ext:bak | ext:tar | ext:gz | ext:zip | ext:7z) inurl:backup

# Database dumps left on web root
site:{target} inurl:dump.sql OR inurl:database.sql OR inurl:db.sql

# IDE and editor temp files
site:{target} inurl:".idea" OR inurl:".vscode" OR inurl:".swp" OR inurl:".DS_Store"

# Vim swap files (leak file contents)
site:{target} inurl:".swp" OR inurl:"~" filetype:swp
```

---

## 2. Login Pages and Admin Panels

The fastest path to an auth bypass is finding a panel that was supposed to
be on an internal network but ended up exposed.

```text
# Generic admin login pages
site:{target} inurl:admin | inurl:administrator | inurl:login | inurl:portal intitle:login

# Admin panel titles
site:{target} intitle:"Admin Panel" | intitle:"Dashboard" | intitle:"Control Panel" -demo

# WordPress admin
site:{target} inurl:wp-admin | inurl:wp-login.php

# Tomcat / JBoss / GlassFish management consoles
site:{target} intitle:"Tomcat" intitle:"Manager"
site:{target} inurl:manager/html intitle:"Tomcat"

# Grafana / Kibana / Jenkins login pages
site:{target} intitle:"Grafana" inurl:login
site:{target} intitle:"Kibana"
site:{target} intitle:"Jenkins" inurl:login

# VPN / SSO / IdP login
site:{target} intitle:"Sign In" inurl:auth | inurl:sso | inurl:vpn | inurl:okta

# Default credentials pages
site:{target} intitle:"default password" OR intext:"admin/admin" filetype:html
```

---

## 3. API Endpoints and Documentation

OpenAPI, Swagger, GraphiQL, and similar interfaces often expose the full
attack surface — including unauthenticated and admin-only routes.

```text
# Swagger / OpenAPI docs
site:{target} inurl:swagger | inurl:swagger-ui | inurl:openapi | inurl:api-docs

# GraphQL playground and introspection
site:{target} inurl:graphql | inurl:graphiql | inurl:/playground

# API documentation landing pages
site:{target} intitle:"API" intitle:"Reference" | intitle:"API Documentation"

# Postman collections leaked on the site
site:{target} inurl:postman | inurl:collection.json | inurl:postman_collection

# Webhook testing pages (often unauthenticated)
site:{target} inurl:webhook | inurl:callback

# Internal API paths hinted in JS
site:{target} inurl:/api/v1 | inurl:/api/v2 | inurl:/v1/ | inurl:/v2/ intext:json
```

---

## 4. Error Messages Leaking Information

Verbose error pages often disclose stack traces, file paths, framework
versions, and database schemas.

```text
# Stack traces
site:{target} intext:"Stack trace" | intext:"Traceback (most recent call last)"
site:{target} intext:"at System." OR intext:"at java." OR intext:"at org.springframework"

# PHP fatal errors
site:{target} intext:"Fatal error" | intext:"Parse error" | intext:"Warning:" filetype:php

# Database error messages
site:{target} intext:"You have an error in your SQL syntax" | intext:"PG::SyntaxError" | intext:"ORA-"
site:{target} intext:"SQLSTATE[" | intext:"SQLite3::"

# Debug pages and dumps
site:{target} intitle:"Laravel" intext:"Whoops" OR intext:"Exception"
site:{target} intitle:"Django" intext:"OperationalError" OR intext:"DEBUG = True"
site:{target} intitle:"Flask" intext:"Traceback"

# Framework version disclosure in error pages
site:{target} intext:"Server: Apache" intext:"PHP/" OR intext:"X-Powered-By:"
```

---

## 5. Cloud Storage

Misconfigured buckets are the highest-value asset class in public bounty
programs. Check for both AWS S3, Azure Blob, and GCP buckets.

```text
# AWS S3 bucket naming patterns (replace {target} with company name)
site:s3.amazonaws.com "{target}"
site:s3.amazonaws.com inurl:{target}
inurl:s3.amazonaws.com "{target}-backup" | "{target}-data" | "{target}-uploads"

# Azure Blob storage
site:blob.core.windows.net "{target}"
site:blob.core.windows.net inurl:{target}

# GCP Cloud Storage
site:storage.googleapis.com "{target}"
inurl:storage.googleapis.com "{target}"

# Public bucket indicators in indexed pages
intext:"Bucket: " intext:"{target}" -github -stackoverflow

# CloudFront and ELB origins (sometimes misconfigured)
site:cloudfront.net "{target}"
```

> **Note:** Google indexes bucket objects only if they're linked from a
> public page. Combine these dorks with bucket-name guessing
> (`{target}-backup`, `{target}-prod`, `{target}-assets`, etc.).

---

## 6. Configuration Files

Web server and framework configs frequently reveal internal paths,
database endpoints, and credentials.

```text
# Apache and Nginx config
site:{target} inurl:httpd.conf OR inurl:nginx.conf OR inurl:default.conf

# .htaccess (rewrite rules, password protection hints)
site:{target} inurl:.htaccess

# Docker / Kubernetes manifests
site:{target} inurl:docker-compose.yml | inurl:docker-compose.yaml | inurl:Chart.yaml
site:{target} inurl:deployment.yaml | inurl:ingress.yaml

# CI configs
site:{target} inurl:.gitlab-ci.yml | inurl:.travis.yml | inurl:circle.yml
site:{target} inurl:Jenkinsfile | inurl:bitbucket-pipelines.yml

# Web server status pages
site:{target} intitle:"Apache Status" | intitle:"server-status" | intitle:"server-info"
site:{target} inturl:nginx_status

# PHP info pages
site:{target} inurl:phpinfo.php intitle:"phpinfo()"
```

---

## 7. Directory Listings

Open directory listings make every other recon step faster — they expose
the full file tree.

```text
# Apache mod_autoindex enabled
site:{target} intitle:"Index of /"

# Apache with name column showing
site:{target} intitle:"Index of" intext:"Parent Directory"

# Nginx autoindex
site:{target} intitle:"Index of" "nginx"

# IIS directory listing
site:{target} intitle:"Index of" "IIS"

# Backup directories
site:{target} intitle:"Index of" inurl:backup | inurl:bak | inurl:old

# Logs and tmp directories
site:{target} intitle:"Index of" inurl:logs | inurl:tmp | inurl:temp

# GitHub Pages mirrors (should not exist for private repos)
site:{target} inurl:github.io
```

---

## Quick Dork Combos

When starting a new target, run these three against the in-scope root and
each top-level subdomain discovered during recon.

```text
# Combo 1: All common sensitive files in one query
site:{target} (filetype:env | filetype:sql | filetype:bak | inurl:".git" | inurl:wp-config | inurl:phpinfo | inurl:web.config)

# Combo 2: All open directories
site:{target} intitle:"Index of" intext:"Parent Directory"

# Combo 3: All common admin panels
site:{target} (inurl:admin | inurl:portal | inurl:login) intitle:login -demo -tutorial

# Combo 4: All API docs
site:{target} (inurl:swagger | inurl:openapi | inurl:graphql | inurl:api-docs) -github
```

---

## Safety Notes

- **Read `programs/{target}/scope.md` first.** Dorking a third-party SaaS
  the target uses is out of scope.
- **Don't submit findings to multiple programs.** If you find a leak on a
  shared service, it belongs to whichever program owns the asset, not
  every program that touches it.
- **Respect `robots.txt` and rate limits.** Aggressive dorking from a
  single IP can get your search quota throttled or your account
  flagged — and the target's WAF may block the rest of your recon.
- **Save raw output** to `programs/{target}/recon/google-dorks.txt` with
  the query and date for every finding you chase down.
