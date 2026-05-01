# Skill Registry — Hunter Bug Bounty Framework

## Project Skills

| Trigger Context | Skill | Purpose |
|-----------------|-------|---------|
| "init", "/init", "start target", "nuevo objetivo" | `bug-bounty-init` | Initialize new bug bounty target, create structure |
| "recon", "enumerate", "footprinting" | `bug-bounty-recon` | Deep reconnaissance, attack surface mapping |
| "sqlmap", "sqli", "sql injection" | `bug-bounty-sqlmap` | SQL injection scanning and exploitation |
| "report", "writeup", "write finding" | `bug-bounty-report` | Professional vulnerability report writing |
| "validate", "verify", "exploit", "confirm", "POC" | `bug-bounty-validate` | Vulnerability validation and exploitation verification |
| "hunt", "/hunt", "multi-agent" | `bug-bounty-hunt` | Multi-agent vulnerability hunting (future) |
| New bug bounty target | All skills in sequence | Full workflow: init → recon → hunt → validate → report |

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
| Directory: `.claude/skills/bug-bounty-sqlmap/` | bug-bounty-sqlmap |
| Directory: `.claude/skills/bug-bounty-report/` | bug-bounty-report |
| Directory: `.claude/skills/bug-bounty-validate/` | bug-bounty-validate |
| File: `CLAUDE.md` | Hunter persona loaded automatically |