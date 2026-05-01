---
name: bug-bounty-init
description: >
  Initialize a new bug bounty target. Creates directory structure, configures
  scope, sets up recon workspace, and registers session in memory.
  Trigger: When user says "init", "/init", "start target", "nuevo objetivo".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- User says "init", "/init", "start target", "nuevo objetivo", "arrancar"
- Starting a new bug bounty program or pentest engagement
- Setting up workspace for a new target

## Critical Patterns

### Command Format

```
/init [target-name] [program-name]
```

Examples:
```
/init acme.com hackerone
/init api.target.com open-bug-bounty
/init 192.168.1.1 internal-pentest
```

### What /init Does

1. **Creates directory structure** under `programs/[target]/`
2. **Creates scope config** at `config/[target]-scope.md`
3. **Creates recon workspace** at `programs/[target]/recon/`
4. **Creates notes file** at `programs/[target]/notes.md`
5. **Saves session to engram** for cross-session continuity
6. **Displays quick reference** with target info

### Directory Structure Created

```
programs/[target]/
├── recon/
│   ├── subdomains.txt
│   ├── live-hosts.txt
│   ├── ports.txt
│   ├── tech-stack.txt
│   ├── endpoints.txt
│   ├── js-files.txt
│   ├── wayback.txt
│   └── screenshots/
├── vulns/
│   ├── findings.md
│   └── poc/
├── scope.md
└── notes.md
```

## /init Workflow

### Step 1: Parse Arguments

If no arguments provided, ask user:
- Target name/domain
- Program name (hackerone, open-bug-bounty, private, etc.)
- Scope (if known, else create template)

### Step 2: Create Structure

```bash
mkdir -p programs/{target}/recon/screenshots
mkdir -p programs/{target}/vulns/poc
touch programs/{target}/recon/subdomains.txt
touch programs/{target}/recon/live-hosts.txt
touch programs/{target}/recon/ports.txt
touch programs/{target}/recon/tech-stack.txt
touch programs/{target}/recon/endpoints.txt
touch programs/{target}/recon/js-files.txt
touch programs/{target}/recon/wayback.txt
```

### Step 3: Create Scope Config

If program has public scope, use it. Else create template:

```markdown
# [Target] — [Program] Scope

## Target
- Primary: target.com
- Additional:
  - *.target.com
  - api.target.com

## In-Scope
-

## Out-of-Scope
-

## Allowed Testing Methods
-

## Report Requirements
-

## Notes
-
```

### Step 4: Create Notes File

```markdown
# [Target] — Bug Bounty Notes

## Target Info
- Program: [program]
- Scope: [scope-url]
- Rewards: [rewards-info]

## Recon Timeline
- [date]: Init started

## Findings

### P0 (Critical)
-

### P1 (High)
-

### P2 (Medium)
-

## TODO
- [ ]
- [ ]

## References
-
```

### Step 5: Save to Engram

```bash
mem_save(
  title="Started new target: [target]",
  type="project",
  content="**What**: New bug bounty target [target]\n**Why**: [program] program\n**Where**: programs/[target]/\n**Status**: Recon phase\n**Next**: Run /recon or /hunt to start testing"
)
```

### Step 6: Display Summary

```
╔═══════════════════════════════════════╗
║         TARGET INIT COMPLETE          ║
╚═══════════════════════════════════════╝

Target: [target]
Program: [program]
Location: programs/[target]/

Quick Commands:
  /recon     → Start reconnaissance
  /recon full → Full deep recon
  /hunt      → Start multi-agent hunt
  /notes     → Edit notes

Files Created:
  programs/[target]/scope.md
  programs/[target]/notes.md
  programs/[target]/recon/*
```

## Auto-Resolution

This skill auto-resolves from:
- `/init` command in user input
- "start target", "nuevo objetivo", "arrancar target"
- "setup workspace" for a new engagement

## Resources

- **Templates**: See [assets/](assets/) for scope and notes templates
- **Tools**: See bug-bounty-recon SKILL.md for recon commands
- **Multi-agent**: See bug-bounty-hunt SKILL.md (when available)