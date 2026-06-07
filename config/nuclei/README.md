# Nuclei Templates Configuration

## Overview

This directory contains nuclei template configuration for bug bounty
hunting. Nuclei is used for template-based vulnerability scanning across
discovered endpoints.

## Directory Structure

```
config/nuclei/
├── templates/             # Custom nuclei templates
│   ├── low-severity/      # Low severity findings
│   ├── medium-severity/   # Medium severity findings
│   ├── high-severity/     # High severity findings
│   └── critical/          # Critical severity (RCE, SQLi, Auth bypass)
└── .nuclei-config.yml     # Nuclei configuration
```

## Official Templates (Download)

```bash
# Clone official nuclei templates
git clone https://github.com/projectdiscovery/nuclei-templates.git \
  ~/tools/nuclei-templates

# Update templates
cd ~/tools/nuclei-templates && git pull
```

## Custom Template Categories

### Critical (P0) — High Impact
- CVE critical templates
- SQL injection templates
- RCE / command injection templates
- Auth bypass templates

### High (P1)
- IDOR templates
- Stored XSS templates
- SSRF templates
- Auth bypass (low privilege)

### Medium (P2)
- Reflected XSS
- CSRF
- Open redirect
- Information disclosure

### Low (P3)
- Best practice violations
- Missing security headers
- Debug endpoints exposed

## Nuclei Commands Reference

### Basic Scanning

```bash
# Scan target list with all templates
nuclei -l targets.txt -t ~/tools/nuclei-templates/ \
  -o results.txt

# Critical only
nuclei -l targets.txt \
  -t ~/tools/nuclei-templates/cves/ \
  -t ~/tools/nuclei-templates/critical/ \
  -severity critical \
  -o critical-findings.txt

# HTTP specific
nuclei -l targets.txt \
  -t ~/tools/nuclei-templates/vulnerabilities/ \
  -o vuln-findings.txt
```

### Custom Template Scanning

```bash
# Scan with custom templates only
nuclei -l targets.txt \
  -t config/nuclei/templates/ \
  -o custom-results.txt

# Combine official + custom
nuclei -l targets.txt \
  -t ~/tools/nuclei-templates/ \
  -t config/nuclei/templates/ \
  -o full-results.txt
```

### Rate Limiting

```bash
# Conservative (bug bounty safe)
nuclei -l targets.txt -t ~/tools/nuclei-templates/ \
  -rate-limit 10 \
  -timeout 5 \
  -o results.txt

# Aggressive (authorized testing only)
nuclei -l targets.txt -t ~/tools/nuclei-templates/ \
  -rate-limit 50 \
  -bulk-size 25 \
  -o results.txt
```

## Bug Bounty Safe Configuration

```yaml
# .nuclei-config.yml
# Safe settings for bug bounty hunting

# Rate limiting (be respectful)
rate-limit: 10
bulk-size: 10
timeout: 10

# Retention
max-host-error: 30
retries: 2

# Output
verbose: true
json: false
silent: false

# Templates
tags:
  - xss
  - sqli
  - rce
  - idor
  - ssrf
  - auth-bypass
```

## Integration with /hunt

When running `/hunt`, nuclei is called automatically:

```bash
nuclei -l programs/{target}/recon/live-hosts.txt \
  -t ~/tools/nuclei-templates \
  -o programs/{target}/vulns/nuclei-results.txt
```

## Updating Templates

```bash
# Update official templates
cd ~/tools/nuclei-templates
git pull origin master

# Check for new critical templates
nuclei -t ~/tools/nuclei-templates/critical/ \
  -t ~/tools/nuclei-templates/cves/critical/ \
  -validate
```

## Quick Reference

| Command | Use Case |
|---|---|
| `nuclei -l hosts.txt -t templates/` | Standard scan |
| `nuclei -l hosts.txt -severity critical` | Critical only |
| `nuclei -l hosts.txt -t cves/` | CVE focused |
| `nuclei -update` | Update nuclei engine |
| `nuclei -ut` | Update templates |
