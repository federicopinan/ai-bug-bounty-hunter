# Reconnaissance Checklist

## Phase 1: Passive Recon (No direct interaction)

### Subdomain Enumeration
- [ ] Certificate Transparency (crt.sh)
- [ ] amass passive
- [ ] subfinder
- [ ] Google Dorking (site:, inurl:)
- [ ] GitHub Subdomains
- [ ] DNS bruteforce (amass, gobuster dns)

### Historical Data
- [ ] Wayback Machine
- [ ] GitHub/GitLab code exposure
- [ ] Google Cache
- [ ] Shodan/Censys

### Technology Discovery
- [ ] Wappalyzer
- [ ] WhatWeb
- [ ] BuiltWith

### Email/Employee Discovery
- [ ] theHarvester
- [ ] Hunter.io
- [ ] LinkedIn

## Phase 2: Active Recon (Authorized direct interaction)

### Port Scanning
```
nmap -p 22,80,443,8080,8443,3000,5000,9000,10000 --script vuln -oA {target}-nmap {target}
nmap -p- -sV -T4 {target} (full scan, slower)
```

- [ ] Common web ports (80, 443, 8080, 8443)
- [ ] Development ports (3000, 5000, 8000, 9000)
- [ ] Admin ports (10000, 4443, 8443)
- [ ] VPN ports (1194, 1723)
- [ ] Service version detection

### Web Fingerprinting
- [ ] Technology stack identified
- [ ] Framework version detected
- [ ] Known vulnerabilities in stack

### Content Discovery
- [ ] ffuf/ffuf for directories
- [ ] Gobuster for files
- [ ] wfuzz for parameters
- [ ] Paramspider for parameters
- [ ] waybackurls for historical

## Phase 3: JavaScript Analysis

### JS File Discovery
- [ ] All JS files extracted
- [ ] Source maps found (.map files)
- [ ] Endpoint discovery from JS
- [ ] API key/secrets search

### Secret Scanning
```bash
# In JS files
grep -rE "api[_-]?key|secret|token|password|aws[_-]?key|private|authorization" *.js

# In source code
grep -rE "password|passwd|pwd|secret|key|token" --include="*.py" --include="*.js"
```

## Phase 4: API Recon

### API Endpoint Discovery
- [ ] /api/ routes
- [ ] /v1/, /v2/ versions
- [ ] /graphql endpoint
- [ ] Swagger/OpenAPI docs
- [ ] GraphQL introspection

### API Testing
- [ ] HTTP methods (GET, POST, PUT, DELETE, PATCH)
- [ ] Authentication methods (JWT, API key, OAuth)
- [ ] Rate limiting detection
- [ ] CORS configuration

## Phase 5: Attack Surface Mapping

### Vulnerability Surface
- [ ] Input points identified
- [ ] File upload points
- [ ] Authentication endpoints
- [ ] Payment endpoints
- [ ] Search functionality
- [ ] Redirect handling
- [ ] File inclusion points

### Data Sensitivity
- [ ] PII handling locations
- [ ] Financial data endpoints
- [ ] Session management
- [ ] Token storage

## Output Files

```
recon/
├── subdomains.txt           # All discovered subdomains
├── live-hosts.txt           # Verified active hosts
├── ports.txt               # Port scan results
├── tech-stack.txt          # Technology identification
├── endpoints.txt           # Discovered URLs/paths
├── js-files.txt           # JavaScript file list
├── wayback.txt            # Historical URLs
├── api-endpoints.txt      # API routes found
├── secrets.txt            # Exposed secrets
└── screenshots/           # Visual documentation
```

## Tools Priority

1. **amass** - Subdomain enum
2. **nmap** - Port scanning
3. **ffuf** - Directory fuzzing
4. **subfinder** - Subdomain discovery
5. **waybackurls** - Historical data
6. **paramspider** - Parameter discovery
7. **nuclei** - Template scanning
8. **sqlmap** - SQL injection
9. **XSStrike** - XSS testing
10. **commix** - Command injection