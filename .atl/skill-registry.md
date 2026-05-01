# Skill Registry — Hunter Bug Bounty Framework

## Project Overview

AI-powered bug bounty hunting framework. Follows the methodology: **RECON → HUNT → VALIDATE → REPORT**

## Complete Workflow

| Phase | Command | Skill | Hacking Tools | Output |
|-------|---------|-------|---------------|--------|
| **INIT** | `/init target.com [program]` | `bug-bounty-init` | `mkdir`, `touch` | `programs/{target}/recon/`, `scope.md`, `notes.md` |
| **RECON** | `/recon target.com` | `bug-bounty-recon` | `amass`, `nmap`, `ffuf`, `subfinder`, `waybackurls`, `paramspider`, `wappalyzer`, `whatweb`, `nuclei` | `subdomains.txt`, `live-hosts.txt`, `ports.txt`, `endpoints.txt`, `tech-stack.txt` |
| **HUNT** | `/hunt target.com [--flags]` | `bug-bounty-hunt` | `nuclei`, `sqlmap`, `XSStrike`, `commix`, `ffuf` | `vulns/findings.md`, `vulns/poc/*.md` |
| **VALIDATE** | `/validate [type] [endpoint]` | `bug-bounty-validate` | `curl`, `sqlmap`, `nc`, `python3 -m http.server` | CONFIRMED / FALSE_POSITIVE status |
| **REPORT** | `/report [finding]` | `bug-bounty-report` | `markdown` | `vulns/reports/{finding}.md` |

### Workflow Visual

```
┌─────────────────────────────────────────────────────────────────┐
│  /init target.com                                                │
│  → Creates: programs/target/recon/, scope.md, notes.md           │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│  /recon target.com                                              │
│  → Tools: amass, nmap, ffuf, subfinder, waybackurls            │
│  → Output: subdomains.txt, live-hosts.txt, ports.txt,           │
│            endpoints.txt, tech-stack.txt                         │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│  /hunt target.com [--full]                                      │
│  → Automated: nuclei, sqlmap, XSStrike                           │
│  → Manual: IDOR, Auth bypass, SSRF, RCE, Business logic         │
│  → Output: vulns/findings.md (with POCs in vulns/poc/)          │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│  /validate [vuln-type] [endpoint]                               │
│  → Confirms: Is it real? Can you exploit it? What's the impact? │
│  → Status: CONFIRMED or FALSE_POSITIVE                           │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│  /report [finding]                                              │
│  → HackerOne format: Title, Summary, Steps, Impact,            │
│    Mitigation, Evidence, CVSS, CWE                              │
│  → Save to: programs/target/vulns/reports/                       │
└─────────────────────────────────────────────────────────────────┘
```

## Project Skills

| Trigger Context | Skill | Purpose |
|-----------------|-------|---------|
| "init", "/init", "start target", "nuevo objetivo" | `bug-bounty-init` | Initialize new bug bounty target, create structure |
| "recon", "enumerate", "footprinting" | `bug-bounty-recon` | Deep reconnaissance, attack surface mapping |
| "hunt", "/hunt", "start hunting", "buscar vulnerabilidades" | `bug-bounty-hunt` | Multi-technique vulnerability hunting across all vectors |
| "validate", "verify", "exploit", "confirm", "POC" | `bug-bounty-validate` | Vulnerability validation and exploitation verification |
| "report", "writeup", "write finding" | `bug-bounty-report` | Professional vulnerability report writing |
| "sqlmap", "sqli", "sql injection" | `bug-bounty-sqlmap` | SQL injection scanning and exploitation (integrated in /hunt) |

### Skills Status

| Skill | File | Status |
|-------|------|--------|
| `bug-bounty-init` | `.claude/skills/bug-bounty-init/SKILL.md` | ✅ Active |
| `bug-bounty-recon` | `.claude/skills/bug-bounty-recon/SKILL.md` | ✅ Active |
| `bug-bounty-hunt` | `.claude/skills/bug-bounty-hunt/SKILL.md` | ✅ Active |
| `bug-bounty-validate` | `.claude/skills/bug-bounty-validate/SKILL.md` | ✅ Active |
| `bug-bounty-report` | `.claude/skills/bug-bounty-report/SKILL.md` | ✅ Active |
| `bug-bounty-sqlmap` | `.claude/skills/bug-bounty-sqlmap/SKILL.md` | ✅ Active |

## Hacking Tools Reference

| Phase | Tool | Purpose |
|-------|------|---------|
| Recon | `amass` | Subdomain enumeration (DNS, certificate logs, passive) |
| Recon | `nmap` | Port scanning and service detection |
| Recon | `ffuf` | Directory and parameter fuzzing |
| Recon | `subfinder` | Subdomain discovery |
| Recon | `waybackurls` | Historical endpoint discovery |
| Recon | `paramspider` | Parameter discovery |
| Recon | `wappalyzer` | Technology fingerprinting |
| Recon | `whatweb` | Deep fingerprinting |
| Hunt | `nuclei` | Template-based vulnerability scanning |
| Hunt | `sqlmap` | SQL injection detection and exploitation |
| Hunt | `XSStrike` | XSS scanning |
| Hunt | `commix` | Command injection testing |
| Validate | `curl` | Manual testing, request crafting |
| Validate | `nc` | Listener for callbacks (SSRF, blind XSS) |
| Validate | `python3 -m http.server` | Quick server for testing |

## Project Standards (auto-resolved)

### Bug Bounty Hunter Persona
- Professional, methodical, business-impact focused
- Always verify scope before testing
- Document everything with evidence
- Reports must include business impact analysis
- Follow OWASP Top 10 methodology

### Tools Priority Order
1. Manual testing first, automation second
2. Tools: amass, nmap, ffuf, nuclei, sqlmap, XSStrike, commix
3. Always capture evidence (screenshots, HTTP logs, payloads)

### Report Quality Gate
- Title = Severity + Type + Impact
- Must have: Summary, Reproduction Steps, Impact, Mitigation, Evidence
- Business impact section mandatory for High/Critical
- No "might" or "could be" — show evidence
- Duplicate check before submission

### Validation Requirements
- Minimum 2 test cases to confirm
- False positive red flags must be checked
- Severity must match impact (don't inflate)
- POC must be executable and demonstrate real impact

## User Skills (trigger table)

| Code Context | Skill |
|--------------|-------|
| Directory: `.claude/skills/bug-bounty-init/` | bug-bounty-init |
| Directory: `.claude/skills/bug-bounty-recon/` | bug-bounty-recon |
| Directory: `.claude/skills/bug-bounty-hunt/` | bug-bounty-hunt |
| Directory: `.claude/skills/bug-bounty-validate/` | bug-bounty-validate |
| Directory: `.claude/skills/bug-bounty-report/` | bug-bounty-report |
| Directory: `.claude/skills/bug-bounty-sqlmap/` | bug-bounty-sqlmap |
| File: `CLAUDE.md` | Hunter persona loaded automatically |
| File: `config/nuclei/` | Nuclei templates configuration |
| File: `config/wordlists/` | Wordlists for fuzzing and payloads |
