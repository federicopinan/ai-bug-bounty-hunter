---
name: bug-bounty-recon
description: >
  Deep reconnaissance skill for bug bounty hunting. Automates subdomain enumeration,
  port scanning, technology fingerprinting, and attack surface mapping.
  Trigger: When user says "recon", "reconnaissance", "enum", "footprinting", or starts a new bug bounty target.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Starting a new bug bounty program or target
- User says "recon", "enumerate", "footprinting", "侦查"
- Mapping attack surface for a new target
- Finding hidden endpoints, subdomains, or parameters
- Building a comprehensive target profile

## Critical Patterns

### Phase 1: Passive Recon (No direct interaction with target)

```bash
# Subdomain enumeration via certificate logs
curl -s "https://crt.sh/?q=%.{target}&output=json" | jq -r '.[].name_value' | sort -u

# Google dorking for subdomains
amass passive -d {target}

# GitHub subdomains
python3 -m github-subdomains -t {github_token} -d {target}

# Wayback machine for historical endpoints
curl -s "https://web.archive.org/web/*/{target}/*" | grep -oP 'https?://[^\s"'"'"'>]+' | sort -u
```

### Phase 2: Active Recon (Direct interaction — authorize first)

```bash
# Nmap scan for common bug bounty ports
nmap -p 22,80,443,8080,8443,3000,5000,9000,10000 --script vuln -oA recon/{target}-nmap {target}

# Subdomain enumeration with DNS bruteforce
 amass enum -brute -d {target} -o recon/{target}-subdomains.txt

# Technology detection with Wappalyzer
wappalyzer {target}

# WhatWeb for deep fingerprinting
whatweb -a 3 https://{target}
```

### Phase 3: Endpoint Discovery

```bash
# Param discovery with paramspider
python3 paramspider.py -d {target} -o recon/{target}-params.txt

# Directory enumeration with ffuf
ffuf -u https://{target}/FUZZ -w /usr/share/wordlists/dirb/common.txt -mc 200,301,302 -o recon/{target}-ffuf.json

# JavaScript file extraction
python3 -m jspscan https://{target} 2>/dev/null | grep -oP 'https?://[^\s"'"'"'>]+' | sort -u

# Waybackurls for historical endpoints
cat recon/{target}-subdomains.txt | waybackurls > recon/{target}-wayback.txt
```

### Phase 4: Technology Analysis

```bash
# BuiltWith for technology stack
curl -s "https://api.builtwith.com/v1/api/understand?url={target}&struct=1" | jq

# Retire.js for JavaScript vulnerabilities
retire.js --path . --jsounds | grep -v "npm" | head -50

# Secret scanning in JS files
curl -s {target}/assets/app.js | grep -iE "api[_-]?key|secret|token|password|aws[_-]?key"
```

## Commands Reference

| Command | Purpose |
|---------|---------|
| `amass enum -brute -d {target}` | DNS bruteforce subdomains |
| `nmap -p- -sV {target}` | Full port scan with version detection |
| `ffuf -w wordlist -u https://{target}/FUZZ` | Directory fuzzing |
| `paramspider -d {target}` | Parameter discovery |
| `sqlmap -m urls.txt --batch --smart` | SQL injection scan |
| ` nuclei -l targets.txt -t vulnerabilities/` | Template-based vulnerability scan |

## Recon Checklist

- [ ] Subdomains enumerated (certificate logs, DNS bruteforce, Google dorking)
- [ ] Live hosts verified (not all subdomains are active)
- [ ] Port scan complete (22,80,443,8080,8443,3000,5000,9000,10000)
- [ ] Technology stack identified (web server, frameworks, libraries)
- [ ] Endpoints discovered (params, paths, API endpoints)
- [ ] JavaScript files analyzed (secrets, endpoints, hidden logic)
- [ ] Historical data collected (Wayback, GitHub)
- [ ] Recon data saved to `recon/{target}-{date}.txt`

## Tools Priority

1. **amass** — subdomain enumeration (DNS, certificate logs, passive)
2. **nmap** — port scanning and service detection
3. **ffuf** — directory and parameter fuzzing
4. **waybackurls** — historical endpoint discovery
5. **paramspider** — parameter discovery
6. **wappalyzer** — technology fingerprinting
7. **nuclei** — template-based vulnerability scanning
8. **sqlmap** — SQL injection detection
9. **XSStrike** — XSS scanning
10. **commix** — command injection testing

## Output Structure

Save all recon data organized by target:

```
programs/{target}/
├── recon/
│   ├── subdomains.txt
│   ├── live-hosts.txt
│   ├── ports.txt
│   ├── tech-stack.txt
│   ├── endpoints.txt
│   ├── js-files.txt
│   └── wayback.txt
└── screenshots/
```

## Resources

- **Templates**: See [assets/](assets/) for recon checklist template
- **OWASP**: Use OWASP Testing Guide for methodology alignment
- **wordlists**: /usr/share/wordlists/ for fuzzing dictionaries