# Framework audit

Static review of baseline `41855bbe1c66227e6cf74268388c81b6ceae4a61`.
Three independent bounded explorers covered workflow/policies, storage/bootstrap,
and dashboard/tests. No external targets were contacted. These are local framework
findings, not vulnerability reports about bounty programs.

## Architecture

Agent instructions and Markdown playbooks guide Bash scanner orchestration.
Python utilities manage scope decisions, event logs, evidence, and report drafts.
An Astro/TypeScript read-only dashboard projects Markdown/JSON/JSONL files.
The filesystem is the persistence and integration boundary. Authorization,
containment, phase state, and data formats therefore need shared contracts.

## Prioritized findings

| ID | Priority | Evidence at baseline | Consequence | Correction direction |
| --- | --- | --- | --- | --- |
| A1 | High | `tools/scripts/recon.sh:127-136`, `hunt.sh:110-124` | Scans proceed without machine policy validation; non-TTY bypass | Gate each concrete asset/action before requests; validate redirect destinations |
| A2 | High | `tools/scripts/scope-guard.py:86-92,124-136` | Malformed exclusion actions can silently remove a deny | Validate complete policy schema before evaluation |
| A3 | High | `install.sh:198,548-558` | Shared directories can be deleted without ownership proof | Dedicated managed prefix and explicit ownership/adoption contract |
| A4 | High | `tools/scripts/evidence-vault.py:110-128` | Repeated initialization erases evidence registrations | Reject existing vaults without modification |
| A5 | High, local precondition | `tools/scripts/build-report.py:88,172`; evidence/log writers | Symlinked destinations can redirect writes; dangling report links bypass checks | Contained, no-follow writes and safe publication |
| A6 | High, deployment-dependent | `docker-compose.yml:5-14`; raw API | Unauthenticated data exposed outside loopback | Default loopback binding; explicit authenticated proxy for remote use |
| A7 | Medium | `tools/scripts/evidence-vault.py:144-160` | Concurrent read-modify-write loses evidence | Lock complete transactions and atomically publish metadata |
| A8 | Medium | `tools/scripts/recon.sh:321-326`, `hunt.sh:89,144-148` | Empty/failed runs preserve obsolete scan inputs | Explicit run state and atomic completed-run publication |
| A9 | Medium | `dashboard/src/components/FileViewer.astro:9-15` | Relative server fetch fails under Node | Read through contained scanner directly, not self-HTTP |
| A10 | Medium, local precondition | `dashboard/src/lib/scanner.ts:349-351,392-419,429-442,472-480` | Non-raw readers follow nested symlinks | Apply one contained reader across all data paths |
| A11 | Medium | `dashboard/src/lib/cache.ts:9-20`; scanner activity paths | Unique cache keys and full-log accumulation are unbounded | Bounded cache, expiry eviction, input limits and streaming selection |
| A12 | Medium | `dashboard/src/lib/parser.ts:189-195`; tracker template | Placeholder H3 sections count as findings | Canonical finding format, fixture tests, explicit status mapping |
| A13 | Medium | `dashboard/package.json:14,29-30`, `Dockerfile:1` | Native TypeScript tests disagree with supported Node 20 | Choose and document one supported runner/runtime |
| A14 | Medium | `dashboard/tests/scope-evidence.test.ts:267-284` | Tests rename actual reports directory | Execute fixtures in scratch roots, never user data |
| A15 | Medium | `.github/workflows/` | CI checks formatting/contracts but not behavior | Offline functional tests, typecheck and build |
| A16 | Medium | `tools/scripts/build-report.py:71-74` | Strict mode accepts untouched placeholder text | Clarify completeness versus draft semantics; reject placeholders |
| A17 | Medium | `dashboard/src/lib/parser.ts:235-240`; program page hrefs | Unrestricted link protocols | Absolute HTTP(S) allowlist; render other values as text |
| A18 | Medium | rules/reporting and workflow skill examples | Proof advice conflicts with controlled-data limits | Controlled accounts/canaries and evidence-first instructions |

## Decisions that must not be inferred

- Whether `allowedActions` is a global ceiling, and how path rules bind hosts.
- Compatibility for existing Markdown-only targets and historical finding formats.
- Ownership/adoption of tools installed before a reliable manifest exists.
- Whether strict reports mean complete drafts or submission-ready reports.
- Supported Node runtime and allowed dependency changes.

## Proof and limits

Initial findings are static source observations, not executed exploit claims.
Reproductions and correction evidence are tracked in
`odd/tasks/framework-hardening.md`. Do not run scanner pipelines, installer or
uninstaller to reproduce these findings against real environments.
No dependency CVE assertions, deployment reachability conclusions, or perfect
security claims are made. External catalog accuracy, every transitive dependency,
and real target data have not been audited.
