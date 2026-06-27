# Hunter Dashboard

Read-only Astro dashboard for the Hunter bug bounty workspace. Renders targets, recon, findings, and activity from `programs/` and `reports/` using the Kanagawa Dragon palette.

> **Read-only by design.** The dashboard mounts the project as `:ro` and never writes to your repo.

## Quickstart

### Docker (recommended)

From the repo root:

```bash
docker compose up -d --build
# → http://localhost:4321
```

Stop:

```bash
docker compose down
```

### Dev mode (no Docker)

From `dashboard/`:

```bash
npm install
npm run dev
# → http://localhost:4321
```

The dev server reads `../programs/` and `../reports/` relative to `dashboard/`.

### Production build (no Docker)

```bash
npm install
npm run build
npm start
```

## Pages

| Path | Purpose |
|---|---|
| `/` | Overview — programs grid, severity mix, top critical/high findings, activity feed |
| `/programs/[target]` | Single program — recon stats, Scope Guard status, recon artifacts (linkable), findings, evidence vaults, file viewer |
| `/findings` | Cross-program findings table with severity/status/target/search filters |
| `/api/programs` | JSON: list of program summaries |
| `/api/programs/[target]` | JSON: full program detail with findings |
| `/api/programs/[target]/scope` | JSON: Scope Guard availability and rule counts from `programs/{target}/scope.json` |
| `/api/findings` | JSON: all findings (supports `?severity=&status=&target=&q=`) |
| `/api/activity` | JSON: Flight Recorder events plus file mtimes (supports `?limit=N&target=example.com`; invalid/missing `limit` defaults to 30, values clamp to 1..100, blank `target` means all targets) |
| `/api/raw/[target]/[...path]` | JSON: `{ content, size, mtime }` for one file (max 1MB) |

## Configuration

Environment variables (all optional, defaults shown):

| Variable | Default | Description |
|---|---|---|
| `PORT` | `4321` | HTTP port |
| `HOST` | `0.0.0.0` | Bind address |
| `PROJECT_ROOT` | `..` (one level up) | Absolute path to the Hunter repo root |
| `REPORTS_ROOT` | `${PROJECT_ROOT}/reports` | Absolute path to the reports directory |
| `CACHE_TTL_MS` | `5000` | In-memory cache TTL for parsed data |

In `docker-compose.yml` the dashboard mounts the repo at `/app/project:ro` and reports at `/app/reports:ro`.

## Architecture

```
dashboard/                 Astro 4 + Node SSR + Tailwind 3
├── src/lib/               scanner (walks programs/), parser (markdown), cache (TTL)
├── src/pages/api/         JSON endpoints (programs, findings, activity, raw file read)
├── src/pages/             index.astro, findings.astro, programs/[target].astro
├── src/components/        badges, cards, feed, file viewer, header
└── src/styles/            kanagawa.css — palette + base layout
```

### Data model

The parser handles the standard `tracker.md` template shipped with Hunter:

- Sections `## P0 — Critical`, `## P1 — High`, `## P2 — Medium`, `## P3 — Low`, `## P4 — Informational`
- Each finding under `### [Title]`
- Metadata table with `**Status**`, `**Severity**`, `**Endpoint**`, `**Bounty**`, `**Platform ID**`, etc.
- Horizontal rule (`---`) ends a finding block

### Flight Recorder / Action Log

Structured AI/script actions can be appended per target as JSONL:

```bash
tools/scripts/log-event.sh <target> <phase> <action> <status> [message]

# Example
tools/scripts/log-event.sh acme.com recon subfinder success \
  "Discovered 18 candidate subdomains" \
  --command "subfinder -d acme.com -o programs/acme.com/recon/subdomains.txt" \
  --output-path "programs/acme.com/recon/subdomains.txt" \
  --metadata '{"count":18}'
```

Events are written to `programs/{target}/activity/events.jsonl`, one JSON object
per line. The logger creates the `activity/` directory, rejects unsafe target
names, uses UTC ISO timestamps, and fails without writing if `--metadata` is not
a valid JSON object. `--output-path` must be a safe relative path; absolute paths
and `..` traversal are rejected.

`/api/activity` merges Flight Recorder events with legacy file-mtime activity so
the dashboard still shows context for older target workspaces. Event files are
read as streaming JSONL; malformed lines are skipped, and if an event claims a
different target than its containing folder, the folder target is used while the
claimed value is retained as `metadata.originalTarget`.

### Scope Guard and Evidence Vaults

The dashboard reads `programs/{target}/scope.json` as the machine-readable
companion to `scope.md`. Program detail shows whether Scope Guard is available,
the policy URL, action allowlist, and in/out rule counts. Invalid or missing
`scope.json` is treated as unavailable so automation should deny by default.
Scope Guard treats `outOfScope` as deny-first: matching rules without `actions`
block every action, and concrete candidate hosts/URLs containing wildcard
characters are rejected even though config patterns may use wildcards.

Evidence vaults created by `tools/scripts/evidence-vault.sh` live at
`programs/{target}/vulns/poc/{finding_id}/`. Program detail lists vault IDs,
titles, and evidence file counts when `metadata.json` exists. The dashboard is
read-only; use `tools/scripts/build-report.sh` to generate report drafts from
vault metadata and evidence. Add `--strict` when you want missing metadata,
reproduction/impact text, or evidence files to fail instead of producing TODOs.
Evidence files are capped at 10MB before copying by default; set
`EVIDENCE_VAULT_MAX_BYTES` to a byte count to adjust the local guardrail.

### Caching

- All scans are cached in-memory per-server-process.
- TTL defaults to 5s (`CACHE_TTL_MS`).
- Restart the container to force a cold read; cache clears on process exit.

### Empty state

If `programs/` has no target directories (only the `{target}` placeholder), the dashboard shows a clear empty state with the right command (`/init <target> <program>`).

## Security notes

- The dashboard mounts the project read-only (`:ro`) in Docker — it cannot modify your files.
- The `/api/raw/[target]/[...path]` endpoint resolves real paths, rejects symlink escapes outside `programs/{target}/`, and caps files at 1MB to prevent abuse.
- Do **not** expose this dashboard to the public internet without authentication. It exposes hunting data including scope, endpoints, and findings. For LAN/local-only use it's fine as-is.
- If you need auth: terminate at a reverse proxy (Caddy, Traefik, nginx) with basic auth or OIDC.

## Limitations (v1)

- No real-time updates or live log streaming. The dashboard refreshes via `location.reload()` after 60s of user inactivity.
- No screenshot previews — recon/screenshot files are listed as links, not embedded.
- No edit UI — by design. To update state, edit the markdown files directly.
- Tracker parser expects the standard template format. Custom tracker layouts will fall back to 0 findings.

## Stack

- Astro 4 (SSR, Node adapter, standalone mode)
- Tailwind CSS 3 (custom Kanagawa palette)
- TypeScript 5 strict
- Node 20+

## License

Apache-2.0 (matches parent repo).
