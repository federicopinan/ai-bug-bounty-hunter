```
  ============================================================
   _   _   _ _____ ___  __  __   _   _ _   _ _____ ____ ____
  | | | | / |  _  |_ _||  \/  | | \ | | \ | |_   _|  _ \_   _|
  | |_| | | | |_) || | | |\/| | |  \| |  \| | | | | |_) || |
  |  _  | | |  _ < | | | |  | | | |\  | |\  | | | |  _ < | |
  |_| |_| |_|_| \_\|___||_|  |_| |_| \_|_| \_| |_| |_| \_\|_|
  /_/   \_\_\   /_/   /_/   \_\_\   /_/   \_\___/
  ============================================================
        [ RECON ]  ->  [ HUNT ]  ->  [ VALIDATE ]  ->  [ REPORT ]
        //  scanning the perimeter since the perimeter had bugs  //
  ============================================================
```

> AI-assisted bug bounty hunting workspace. Recon → Hunt → Validate → Report.

# Hunter — Bug Bounty Hunting Environment

AI-assisted security research framework for public bug bounty programs
(HackerOne, Bugcrowd, Intigriti, Immunefi, and equivalents). Provides
methodology rules, skill-driven workflows, a curated payload library, and
tooling bootstrap.

> **Operator role.** This is a hunter workspace, not a pentest deliverable.
> Optimize for *real-world exploitable impact* and payout, not for
> defense-in-depth findings or compliance writeups.
>
> **Hard limits.** Only test assets explicitly in the program's published
> scope. Never exfiltrate real user data, never DoS, never social-engineer.
> One out-of-scope request can get you banned.

---

## Quickstart

```bash
# 1. Bootstrap tooling (nuclei, subfinder, httpx, katana, sqlmap, ffuf, …)
make install                  # or ./install.sh

# 2. Pull wordlists (SecLists, OneListForAll, nuclei templates)
make wordlists

# 3. Confirm the target is in scope
/scope <target>               # reads program policy, flags in/out-of-scope

# 4. Initialize the target workspace
/init <target> <program>      # e.g. /init acme.com hackerone

# 5. Recon
/recon <target>               # default: subdomains + live hosts + tech
/recon <target> --full        # + endpoints, JS, wayback, ports

# 6. Hunt
/hunt <target>                # all vectors
/hunt <target> --xss --sqli --idor   # specific vectors

# 7. Validate every lead
/validate <finding>

# 8. Report
/report <finding>             # writes to reports/<program>.md
```

---

## Workflow

```
SCOPE  →  RECON  →  HUNT  →  VALIDATE  →  REPORT
   │         │         │          │           │
   │         │         │          │           └→ programs/{target}/vulns/confirmed/
   │         │         │          └→ programs/{target}/vulns/poc/
   │         │         └→ programs/{target}/vulns/nuclei-results.txt
   │         └→ programs/{target}/recon/
   └→ config/{target}-scope.md
```

Each phase has a dedicated skill. Don't skip phases. A bug found in HUNT that
failed VALIDATE is just noise.

---

## Skills

Skills are on-demand instructions loaded by the agent harness (Claude Code,
Pi, or compatible). They live in `.claude/skills/`.

| Skill | Trigger | Purpose |
|---|---|---|
| `bug-bounty-scope` | `/scope`, "is this in scope?" | Read & parse program policy, save in/out-of-scope assets |
| `bug-bounty-init` | `/init`, "new target", "setup workspace" | Create `programs/{target}/` scaffold, scope file, notes |
| `bug-bounty-recon` | `/recon`, "enumerate", "footprinting" | Subdomains, ports, tech, endpoints, JS, wayback |
| `bug-bounty-hunt` | `/hunt`, "start hunting" | Multi-vector testing (XSS, SQLi, IDOR, SSRF, RCE, auth bypass) |
| `bug-bounty-validate` | `/validate`, "verify", "POC" | Confirm exploitability and quantify impact |
| `bug-bounty-report` | `/report`, "writeup", "redactar" | HackerOne-style report with business impact |
| `bug-bounty-sqlmap` | `/sqlmap`, "SQL injection" | Safe SQLMap usage with bug-bounty guardrails |

See each skill's `SKILL.md` for the full contract.

---

## Rules (always-on)

These rules fire on every session. They encode the methodology that makes
the difference between a 5% validity ratio and a 60% one.

- **`rules/hunting.md`** — 20 rules of methodology. The non-negotiables:
  - **#1** Read full scope first. One out-of-scope request = potential ban.
  - **#2** Never hunt theoretical bugs. "Can an attacker do this RIGHT NOW?"
  - **#3** Kill weak findings fast (7-question gate, 30-second check).
  - **#6** Automation = highest duplicate rate. Manual finds unique bugs.
  - **#10** Sibling rule. Check every variant of `/api/user/{id}/...`.
  - **#11** A→B signal. Confirmed bug A = the dev made the same mistake
    elsewhere. Hunt for B within 20 minutes before writing the report.
  - **#18–20** Mobile, CI/CD, and SAML are the highest-density bug surfaces
    in 2025–2026 and get their own sections.

- **`rules/reporting.md`** — 12 rules on report quality. The non-negotiables:
  - **#1** No theoretical language. "An attacker can X by Y" — that's it.
  - **#3** Always include PoC. IDOR needs victim's actual data, not 200 OK.
  - **#5** Never submit from the always-rejected list (CSP missing,
    GraphQL introspection alone, open redirect alone, self-XSS, etc.).
  - **#9** Under 600 words. Triagers skim.
  - **#12** Title formula: `[Bug Class] in [Endpoint] allows [role] to [impact]`.

---

## Tools

The skills assume the following tools are on `$PATH`. `make install` will
fetch and place them in `~/tools` and `~/go/bin`.

| Phase | Tools |
|---|---|
| Recon | `subfinder`, `amass`, `assetfinder`, `httpx`, `dnsx`, `katana`, `waybackurls`, `gau`, `gospider` |
| Ports / tech | `nmap`, `whatweb`, `wappalyzer` |
| Fuzzing | `ffuf`, `wfuzz`, `gobuster`, `feroxbuster` |
| Parameter discovery | `paramspider`, `arjun` |
| Vuln scan | `nuclei`, `nikto` |
| SQLi | `sqlmap`, `ghauri` |
| XSS | `xsstrike`, `dalfox` |
| Secrets | `trufflehog`, `gitleaks`, `shhgit` |
| OAST | `interactsh-client` (open-source Burp Collaborator alternative) |
| Screenshots | `gowitness`, `aquatone` |
| Mobile | `apktool`, `jadx`, `frida`, `objection` |
| JWT | `jwt_tool`, `hashcat` |
| Proxy / intercept | `mitmproxy`, `Burp Suite` (manual) |

If a tool is missing, the skill will tell you what to install.

---

## Payloads

Curated payload library at `payloads/`, organized by vulnerability class.
Sourced and cross-checked against
[PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)
and [PortSwigger Web Security Academy](https://portswigger.net/web-security).

| Class | File | Priority |
|---|---|---|
| XSS | `payloads/xss.md` | P2 |
| SQL Injection | `payloads/sqli.md` | P0 |
| SSRF | `payloads/ssrf.md` | P2 |
| IDOR | `payloads/idor.md` | P1 |
| Command Injection | `payloads/cmd-injection.md` | P0 |
| JWT | `payloads/jwt.md` | P1 |
| Auth Bypass | `payloads/auth-bypass.md` | P1 |
| SSTI | `payloads/ssti.md` | P1 |
| LFI / RFI | `payloads/lfi-rfi.md` | P1 |
| XXE | `payloads/xxe.md` | P2 |
| OAuth | `payloads/oauth.md` | P1 |

When you need scale beyond these lists, see `wordlists/REFERENCES.md` for
full upstream collections (SecLists, OneListForAll, fuzz4bounty).

---

## Wordlists

| File | Size | Use |
|---|---|---|
| `wordlists/api-endpoints.txt` | 266 | API path discovery |
| `wordlists/common.txt` | 4.7k | Sensitive files, dotfiles, config leaks |
| `wordlists/params.txt` | 6.4k | Parameter name discovery |
| `wordlists/raft-medium-dirs.txt` | ~30k | Directory brute-force |
| `wordlists/sensitive-files.txt` | 68 | High-signal sensitive paths |

For larger wordlists, `wordlists/REFERENCES.md` lists recommended upstreams
and install commands.

---

## Directory Structure

```
.
├── README.md                       # This file
├── CLAUDE.md                       # Agent persona & always-on identity
├── Makefile                        # install / update-wordlists / update-templates
│
├── .claude/skills/                 # Skills (one folder per skill)
│   ├── bug-bounty-scope/
│   ├── bug-bounty-init/
│   ├── bug-bounty-recon/
│   ├── bug-bounty-hunt/
│   ├── bug-bounty-validate/
│   ├── bug-bounty-report/
│   └── bug-bounty-sqlmap/
│
├── rules/                          # Always-on methodology rules
│   ├── hunting.md
│   └── reporting.md
│
├── prompts/                        # Standalone prompt templates (optional,
│                                   # most flows are now skills)
│
├── payloads/                       # Curated payload library
│
├── wordlists/                      # Compact starter wordlists + REFERENCES
│
├── config/                         # Per-program & per-tool configuration
│   ├── nuclei/
│   └── wordlists/
│
├── programs/                       # Per-target workspaces
│   └── {target}/
│       ├── scope.md
│       ├── notes.md
│       ├── recon/
│       │   ├── subdomains.txt
│       │   ├── live-hosts.txt
│       │   ├── ports.txt
│       │   ├── tech-stack.txt
│       │   ├── endpoints.txt
│       │   ├── js-files.txt
│       │   └── wayback.txt
│       ├── screenshots/
│       └── vulns/
│           ├── findings.md
│           ├── tracker.md
│           ├── poc/
│           └── confirmed/
│
├── tools/                          # Local helper scripts
│
├── reports/                        # Generated reports (per-program)
│
├── docs/                           # Misc documentation
│
├── hooks/                          # Harness hooks (if supported)
│
└── templates/                      # Boilerplate files for new targets
```

---

## Conventions

- **Target naming.** Lowercase, no protocol. `acme.com` not `Acme Corp` and
  not `https://acme.com`. Subdomains are targets of their own:
  `api.acme.com`, `admin.acme.com`.
- **Scope files live in `config/{target}-scope.md`** with explicit in-scope
  and out-of-scope lists quoted from the program policy.
- **Findings live in `programs/{target}/vulns/tracker.md`**, one row per
  finding with status (`NEW`, `VALIDATED`, `REPORTED`, `DUPLICATE`,
  `CLOSED`, `RESOLVED`, `INVALID`).
- **Reports live in `reports/{program}.md`**, sorted from highest business
  impact to lowest.
- **Evidence lives alongside the finding** in `programs/{target}/vulns/poc/`
  with HTTP logs, screenshots, payloads, and a one-paragraph context note.
- **Do not commit real bug screenshots with user data**. Strip or redact
  any PII before committing.

---

## Quality Gates

Before writing a report, every finding must pass:

- [ ] Vulnerability is **confirmed exploitable**, not theoretical
- [ ] PoC generates **real impact** (not just `alert(1)` or `200 OK`)
- [ ] Evidence captured (HTTP request/response, screenshot, payload output)
- [ ] Duplication check done (CVE, HackerOne Hacktivity, public writeups)
- [ ] **Target verified in scope** (re-read `scope.md`, do not assume)
- [ ] CVSS vector calculated for High/Critical
- [ ] CWE identified and justified
- [ ] Business impact quantified (financial, data, compliance, reputational)

---

## Anti-Patterns

- "I found a potential XSS" — without PoC, this is Informational at best.
- Reporting CSP/HSTS/CORS missing as standalone bugs — almost always N/A.
- Submitting self-XSS, GraphQL introspection alone, open redirect alone.
- Chaining weak findings with "could be escalated to..." speculation.
- Running `nuclei -severity critical` on a fresh target and submitting the
  output verbatim. That's a duplicate factory, not a hunt.
- Exfiltrating more data than the PoC requires.
- Re-testing resolved findings without first checking the bounty program's
  re-test policy (some explicitly forbid it).

---

## License

Apache-2.0. See header in `CLAUDE.md`.

## References

- [OWASP Web Security Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [PortSwigger Web Security Academy](https://portswigger.net/web-security)
- [HackerOne Hacker101](https://www.hacker101.com/)
- [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)
- [SecLists](https://github.com/danielmiessler/SecLists)
- [ProjectDiscovery Nuclei Templates](https://github.com/projectdiscovery/nuclei-templates)
