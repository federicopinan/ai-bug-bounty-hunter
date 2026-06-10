#!/usr/bin/env bash
# =============================================================================
# hunt.sh — vulnerability scanning orchestrator
# =============================================================================
# Usage:  ./hunt.sh <target-domain>
#         ./hunt.sh acme.com
#         SKIP_NUCLEI=1 ./hunt.sh acme.com
#         ./hunt.sh --help
#
# What it does:
#   1. Confirms the target is in scope (interactive)
#   2. Loads live hosts from programs/<target>/recon/
#   3. Runs nuclei against high/critical templates
#   4. Runs nuclei exposed-panels + tech-detect
#   5. Checks for missing security headers
#   6. Probes common files (robots.txt, sitemap.xml, security.txt)
#   7. Writes a single consolidated report to
#      programs/<target>/vulns/scan-results-<timestamp>.md
#
# Skip any phase with an env var: SKIP_NUCLEI=1, SKIP_HEADERS=1,
# SKIP_COMMON_FILES=1, SKIP_INTERACTIVE=1.
#
# Make executable:  chmod +x tools/scripts/hunt.sh
# =============================================================================

set -u

# ---------- ANSI color codes -------------------------------------------------
if [ -t 1 ]; then
    C_OK="\033[1;32m"
    C_FAIL="\033[1;31m"
    C_WARN="\033[1;33m"
    C_INFO="\033[1;36m"
    C_BOLD="\033[1m"
    C_OFF="\033[0m"
else
    C_OK=""; C_FAIL=""; C_WARN=""; C_INFO=""; C_BOLD=""; C_OFF=""
fi

ok()   { printf "  ${C_OK}[+]${C_OFF} %s\n" "$*"; }
fail() { printf "  ${C_FAIL}[-]${C_OFF} %s\n" "$*" >&2; }
warn() { printf "  ${C_WARN}[!]${C_OFF} %s\n" "$*"; }
info() { printf "  ${C_INFO}[*]${C_OFF} %s\n" "$*"; }
hdr()  { printf "\n${C_BOLD}== %s ==${C_OFF}\n" "$*"; }

# ---------- Help --------------------------------------------------------------
print_help() {
    cat <<EOF
hunt.sh — vulnerability scanning orchestrator for bug bounty targets

USAGE
    ./hunt.sh <target-domain>          Run full scan pipeline
    ./hunt.sh --help                   Show this help

SKIP FLAGS (env vars)
    SKIP_INTERACTIVE=1   do not prompt for scope confirmation
    SKIP_NUCLEI=1        skip both nuclei passes
    SKIP_HEADERS=1       skip security header audit
    SKIP_COMMON_FILES=1  skip robots/sitemap/security.txt probes

OUTPUT
    programs/<target>/vulns/scan-results-<timestamp>.md

EXAMPLES
    ./hunt.sh acme.com
    SKIP_NUCLEI=1 ./hunt.sh acme.com          # manual header/file check only
    SKIP_INTERACTIVE=1 ./hunt.sh acme.com     # CI / scripted runs
EOF
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && { print_help; exit 0; }

# ---------- Argument check ----------------------------------------------------
if [ $# -lt 1 ]; then
    fail "missing target domain"
    echo
    print_help
    exit 1
fi

TARGET="$1"
TARGET="${TARGET#http://}"; TARGET="${TARGET#https://}"; TARGET="${TARGET%/}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TS="$(date -u +%Y%m%d-%H%M%S)"
OUT_DIR="${ROOT_DIR}/programs/${TARGET}/vulns"
mkdir -p "$OUT_DIR"
REPORT="$OUT_DIR/scan-results-${TS}.md"
LIVE_HOSTS_FILE="${ROOT_DIR}/programs/${TARGET}/recon/live-hosts.txt"

# ---------- Pre-flight scope reminder ----------------------------------------
hdr "Scope confirmation"
cat <<EOF
${C_BOLD}================================================================${C_OFF}
${C_WARN}  STOP.${C_OFF}  Before continuing, confirm the following:
${C_BOLD}================================================================${C_OFF}

  - The asset '${C_BOLD}${TARGET}${C_OFF}' is on the in-scope list of a public
    bug bounty program (HackerOne, Bugcrowd, Intigriti, Immunefi, …).
  - The program has published written safe-harbor terms.
  - The scope file programs/${TARGET}/scope.md has been reviewed in the
    last 24 hours.

  If any of the above is uncertain, open programs/${TARGET}/scope.md
  and the program policy page first. Out-of-scope testing = permanent
  ban on most programs.
${C_BOLD}================================================================${C_OFF}
EOF

# Interactive prompt — skip with SKIP_INTERACTIVE=1.
if [ -z "${SKIP_INTERACTIVE:-}" ] && [ -t 0 ]; then
    read -r -p "  Type 'yes' to confirm ${TARGET} is in scope and proceed: " ANSWER
    case "${ANSWER:-}" in
        yes|YES|y|Y)
            ok "scope confirmed"
            ;;
        *)
            warn "scope not confirmed; aborting"
            exit 2
            ;;
    esac
else
    warn "SKIP_INTERACTIVE=1 set (or no TTY); proceeding without confirmation"
fi

# ---------- Tool checks ------------------------------------------------------
hdr "Tool checks"
have() { command -v "$1" >/dev/null 2>&1; }
MISSING=()
for tool in nuclei curl; do
    if have "$tool"; then
        ok "$tool: $(command -v "$tool")"
    else
        fail "$tool: not found on PATH"
        MISSING+=("$tool")
    fi
done

# ---------- Build target list ------------------------------------------------
hdr "Target list"
TARGETS_FILE="$OUT_DIR/.hunt-targets-${TS}.txt"
: > "$TARGETS_FILE"

if [ -s "$LIVE_HOSTS_FILE" ]; then
    # httpx output starts with the URL; the rest of the columns are title,
    # status code, etc. We want only the first column.
    awk 'NF {print $1}' "$LIVE_HOSTS_FILE" > "$TARGETS_FILE"
    ok "loaded $(wc -l < "$TARGETS_FILE" | tr -d ' ') targets from recon/live-hosts.txt"
else
    warn "no live-hosts.txt found in programs/${TARGET}/recon/"
    warn "falling back to https://${TARGET} only — run ./recon.sh first for better coverage"
    echo "https://${TARGET}" > "$TARGETS_FILE"
fi

# ---------- 1. nuclei: high + critical --------------------------------------
hdr "[1/3] nuclei — high + critical templates"
if [ -n "${SKIP_NUCLEI:-}" ]; then
    warn "SKIP_NUCLEI set; skipping"
else
    if ! have nuclei; then
        fail "nuclei not installed; skipping"
    elif [ ! -s "$TARGETS_FILE" ]; then
        warn "no targets to scan"
    else
        info "nuclei -severity high,critical"
        NUCLEI_HIGH="$OUT_DIR/nuclei-high-critical-${TS}.txt"
        # -bulk-size and -c keep request rate reasonable.
        # -stats-every 30s gives a heartbeat on long scans.
        nuclei -l "$TARGETS_FILE" \
               -severity high,critical \
               -bulk-size 25 -c 25 \
               -stats-every 30s \
               -o "$NUCLEI_HIGH" \
               -silent 2>/dev/null \
            && ok "nuclei complete: $(wc -l < "$NUCLEI_HIGH" 2>/dev/null | tr -d ' ') findings" \
            || warn "nuclei returned non-zero (partial results saved)"
    fi
fi

# ---------- 2. nuclei: exposed panels + tech ---------------------------------
hdr "[2/3] nuclei — exposed panels + tech"
if [ -n "${SKIP_NUCLEI:-}" ]; then
    warn "SKIP_NUCLEI set; skipping"
else
    if have nuclei; then
        NUCLEI_PANELS="$OUT_DIR/nuclei-panels-${TS}.txt"
        info "nuclei -t exposed-panels/ -t technologies/"
        nuclei -l "$TARGETS_FILE" \
               -t exposed-panels/ \
               -t technologies/ \
               -bulk-size 25 -c 25 \
               -o "$NUCLEI_PANELS" \
               -silent 2>/dev/null \
            && ok "panel/tech scan complete" \
            || warn "panel/tech scan returned non-zero"
    fi
fi

# ---------- 3. Security headers + common files ------------------------------
hdr "[3/3] Header audit + common files"

HEADERS_DIR="$OUT_DIR/headers-${TS}"
mkdir -p "$HEADERS_DIR"
HEADERS_REPORT="$HEADERS_DIR/headers.md"
: > "$HEADERS_REPORT"

# Headers every modern web app should have. Missing a single one is rarely
# reportable on its own, but a pattern across the whole surface is.
EXPECTED_HEADERS=(
    "Strict-Transport-Security"
    "Content-Security-Policy"
    "X-Frame-Options"
    "X-Content-Type-Options"
    "Referrer-Policy"
    "Permissions-Policy"
)

if [ -n "${SKIP_HEADERS:-}" ]; then
    warn "SKIP_HEADERS set; skipping"
else
    info "checking security headers on $(wc -l < "$TARGETS_FILE" | tr -d ' ') hosts"
    while IFS= read -r url; do
        [ -z "$url" ] && continue
        # curl -sI sends HEAD; some hosts 405 it, so fall back to GET.
        HEADERS=$(curl -sSL -D - -o /dev/null --max-time 10 "$url" 2>/dev/null \
                  | tr -d '\r' || true)
        for h in "${EXPECTED_HEADERS[@]}"; do
            if ! echo "$HEADERS" | grep -qi "^${h}:"; then
                echo "MISSING ${h} on ${url}" >> "$HEADERS_REPORT"
            fi
        done
    done < "$TARGETS_FILE"
    MISSING_HDRS=$(wc -l < "$HEADERS_REPORT" | tr -d ' ')
    if [ "$MISSING_HDRS" -gt 0 ]; then
        warn "${MISSING_HDRS} missing-header lines recorded"
        warn "  (missing headers are usually Informational — chain with a real bug)"
    else
        ok "all expected headers present on every host"
    fi
fi

# Common files (robots.txt, sitemap.xml, security.txt).
COMMON_PATHS=(robots.txt sitemap.xml .well-known/security.txt humans.txt)
COMMON_REPORT="$OUT_DIR/common-files-${TS}.md"
: > "$COMMON_REPORT"

if [ -n "${SKIP_COMMON_FILES:-}" ]; then
    warn "SKIP_COMMON_FILES set; skipping"
else
    info "probing common files on https://${TARGET}"
    for path in "${COMMON_PATHS[@]}"; do
        URL="https://${TARGET}/${path}"
        code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$URL" 2>/dev/null)
        case "$code" in
            200) ok "${path}: ${code}"; echo "FOUND ${code} ${URL}" >> "$COMMON_REPORT" ;;
            301|302) ok "${path}: ${code} (redirect)"; echo "REDIRECT ${code} ${URL}" >> "$COMMON_REPORT" ;;
            403) warn "${path}: ${code} (forbidden — exists?)" ;;
            404) info "${path}: ${code}" ;;
            *)  warn "${path}: ${code}" ;;
        esac
    done
fi

# ---------- Build consolidated report -----------------------------------------
hdr "Building report"

NUCLEI_HIGH="${OUT_DIR}/nuclei-high-critical-${TS}.txt"
NUCLEI_PANELS="${OUT_DIR}/nuclei-panels-${TS}.txt"

{
    echo "# Scan results — ${TARGET}"
    echo
    echo "- generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "- operator:  ${USER:-$(id -un)} @ $(hostname)"
    echo "- target:    ${TARGET}"
    echo
    echo "## nuclei — high / critical"
    echo
    if [ -s "$NUCLEI_HIGH" ]; then
        echo '```'
        cat "$NUCLEI_HIGH"
        echo '```'
    else
        echo "_no findings or scan skipped_"
    fi
    echo
    echo "## nuclei — exposed panels / tech"
    echo
    if [ -s "$NUCLEI_PANELS" ]; then
        echo '```'
        cat "$NUCLEI_PANELS"
        echo '```'
    else
        echo "_no findings or scan skipped_"
    fi
    echo
    echo "## Security headers"
    echo
    if [ -s "$HEADERS_REPORT" ]; then
        echo "| Host | Missing header |"
        echo "|------|----------------|"
        sed 's/^MISSING \([^ ]*\) on \(.*\)/| \2 | \1 |/' "$HEADERS_REPORT"
        echo
        echo "_Note: missing headers are usually Informational. Chain with a real bug._"
    else
        echo "_all expected headers present or scan skipped_"
    fi
    echo
    echo "## Common files"
    echo
    if [ -s "$COMMON_REPORT" ]; then
        echo '```'
        cat "$COMMON_REPORT"
        echo '```'
    else
        echo "_no notable common files or scan skipped_"
    fi
    echo
    echo "## Missing tools"
    echo
    if [ "${#MISSING[@]}" -eq 0 ]; then
        echo "_none_"
    else
        for t in "${MISSING[@]}"; do echo "- $t"; done
    fi
    echo
    echo "## Next steps"
    echo
    echo "1. Triage each nuclei finding manually — automation = highest dup rate."
    echo "2. Run ./hunt.sh validation phase or use the bug-bounty-validate skill."
    echo "3. Only confirmed, exploitable findings move to programs/${TARGET}/vulns/findings.md."
} > "$REPORT"

# Clean up the temp targets file.
rm -f "$TARGETS_FILE"

ok "report: ${REPORT}"

# ---------- Summary -----------------------------------------------------------
hdr "Summary"
printf "  ${C_BOLD}%-22s${C_OFF} %s\n" "target"        "$TARGET"
printf "  ${C_BOLD}%-22s${C_OFF} %s\n" "targets scanned" "$(wc -l < <(awk 'NF {print $1}' "$LIVE_HOSTS_FILE" 2>/dev/null) 2>/dev/null | tr -d ' ')"
printf "  ${C_BOLD}%-22s${C_OFF} %s\n" "missing tools" "${#MISSING[@]}"
printf "  ${C_BOLD}%-22s${C_OFF} %s\n" "report"        "programs/${TARGET}/vulns/scan-results-${TS}.md"
ok "hunt complete. Next: validate each lead, then /report."
