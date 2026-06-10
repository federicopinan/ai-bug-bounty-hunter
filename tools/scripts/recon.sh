#!/usr/bin/env bash
# =============================================================================
# recon.sh — passive + active reconnaissance orchestrator
# =============================================================================
# Usage:  ./recon.sh <target-domain>
#         ./recon.sh acme.com
#         SKIP_NMAP=1 ./recon.sh acme.com
#         ./recon.sh --help
#
# What it does:
#   1. Sanity-checks the target and required tools
#   2. Subdomain enumeration (subfinder + amass passive)
#   3. Live-host resolution (httpx)
#   4. Top-port scan (nmap)
#   5. Tech detection (whatweb / nuclei tech-detect)
#   6. Directory brute (ffuf)
#   7. Saves everything to programs/<target>/recon/<timestamp>/
#
# Skip any phase with an env var: SKIP_SUBDOMAINS=1, SKIP_HTTPX=1,
# SKIP_NMAP=1, SKIP_TECH=1, SKIP_FFUF=1.
#
# Make executable:  chmod +x tools/scripts/recon.sh
# =============================================================================

set -u  # treat unset variables as errors; do not use -e so partial failures
        # from optional tools (e.g. nmap) do not abort the whole run.

# ---------- ANSI color codes (only when stdout is a TTY) ----------------------
if [ -t 1 ]; then
    C_OK="\033[1;32m"     # green
    C_FAIL="\033[1;31m"   # red
    C_WARN="\033[1;33m"   # yellow
    C_INFO="\033[1;36m"   # cyan
    C_DIM="\033[2m"
    C_BOLD="\033[1m"
    C_OFF="\033[0m"
else
    C_OK=""; C_FAIL=""; C_WARN=""; C_INFO=""; C_DIM=""; C_BOLD=""; C_OFF=""
fi

ok()   { printf "  ${C_OK}[+]${C_OFF} %s\n" "$*"; }
fail() { printf "  ${C_FAIL}[-]${C_OFF} %s\n" "$*" >&2; }
warn() { printf "  ${C_WARN}[!]${C_OFF} %s\n" "$*"; }
info() { printf "  ${C_INFO}[*]${C_OFF} %s\n" "$*"; }
hdr()  { printf "\n${C_BOLD}== %s ==${C_OFF}\n" "$*"; }

# ---------- Help --------------------------------------------------------------
print_help() {
    cat <<EOF
recon.sh — reconnaissance orchestrator for bug bounty targets

USAGE
    ./recon.sh <target-domain>           Run full recon pipeline
    ./recon.sh --help                    Show this help

SKIP FLAGS (env vars)
    SKIP_SUBDOMAINS=1   skip subfinder + amass
    SKIP_HTTPX=1        skip live-host resolution
    SKIP_NMAP=1         skip port scan
    SKIP_TECH=1         skip tech detection
    SKIP_FFUF=1         skip directory brute

OUTPUT
    programs/<target>/recon/<timestamp>/
        subdomains.txt        unique subdomain list
        live-hosts.txt        hosts responding 2xx/3xx
        ports.txt            nmap grepable + open ports
        tech-stack.txt        detected technologies
        endpoints.txt         directory brute results

EXAMPLES
    ./recon.sh acme.com
    SKIP_NMAP=1 SKIP_FFUF=1 ./recon.sh acme.com
    ./recon.sh api.acme.com
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
# Strip any protocol prefix and trailing slash the user might pass in.
TARGET="${TARGET#http://}"; TARGET="${TARGET#https://}"
TARGET="${TARGET%/}"

# ---------- Sanity checks -----------------------------------------------------
hdr "Pre-flight"
info "target: ${C_BOLD}${TARGET}${C_OFF}"
info "operator: ${USER:-$(id -un)} @ $(hostname)"

# Tool availability helper: warns (does not abort) when a tool is missing.
have() { command -v "$1" >/dev/null 2>&1; }

MISSING=()
for tool in subfinder amass httpx nmap ffuf; do
    if have "$tool"; then
        ok "$tool: $(command -v "$tool")"
    else
        fail "$tool: not found on PATH"
        MISSING+=("$tool")
    fi
done

# whatweb is optional; we also accept nuclei as a tech-detect fallback.
HAVE_WHATWEB=0; have whatweb && HAVE_WHATWEB=1
HAVE_NUCLEI=0;  have nuclei  && HAVE_NUCLEI=1
if [ "$HAVE_WHATWEB" -eq 0 ] && [ "$HAVE_NUCLEI" -eq 0 ]; then
    warn "tech detection skipped: install whatweb or nuclei"
fi

# ---------- Workspace ---------------------------------------------------------
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TS="$(date -u +%Y%m%d-%H%M%S)"
OUT_DIR="${ROOT_DIR}/programs/${TARGET}/recon/${TS}"
mkdir -p "$OUT_DIR"
ok "output: ${OUT_DIR}"

# Latest symlink so the user can always find the most recent run.
ln -sfn "$TS" "${ROOT_DIR}/programs/${TARGET}/recon/latest"

# Scope reminder
hdr "Scope check"
cat <<EOF
  ${C_WARN}Reminder:${C_OFF} only test assets explicitly in the program's
  published scope. If '${TARGET}' is not in
  programs/${TARGET}/scope.md, stop and update the scope file first.
EOF
[ -f "${ROOT_DIR}/programs/${TARGET}/scope.md" ] \
    && ok "scope file present" \
    || warn "no scope file at programs/${TARGET}/scope.md (create one before hunting)"

# ---------- 1. Subdomain enumeration -----------------------------------------
hdr "[1/6] Subdomain enumeration"
if [ -n "${SKIP_SUBDOMAINS:-}" ]; then
    warn "SKIP_SUBDOMAINS set; skipping"
else
    : > "$OUT_DIR/subdomains.txt"
    if have subfinder; then
        info "subfinder -d ${TARGET} -all -silent"
        subfinder -d "$TARGET" -all -silent 2>/dev/null \
            | tee -a "$OUT_DIR/subdomains.txt" >/dev/null
        ok "subfinder done"
    else
        warn "subfinder not installed; skipping"
    fi
    if have amass; then
        # Passive only — no DNS brute. We never want to be loud on a
        # target we don't own unless the program explicitly allows it.
        info "amass enum -passive -d ${TARGET}"
        amass enum -passive -d "$TARGET" -nocolor 2>/dev/null \
            | tee -a "$OUT_DIR/subdomains.txt" >/dev/null
        ok "amass (passive) done"
    fi
    # Always include the apex.
    echo "$TARGET" >> "$OUT_DIR/subdomains.txt"
    sort -u "$OUT_DIR/subdomains.txt" -o "$OUT_DIR/subdomains.txt"
    SUBDOMAIN_COUNT=$(wc -l < "$OUT_DIR/subdomains.txt" | tr -d ' ')
    ok "unique subdomains: ${SUBDOMAIN_COUNT}"
fi

# ---------- 2. Live hosts (httpx) --------------------------------------------
hdr "[2/6] Live host resolution"
if [ -n "${SKIP_HTTPX:-}" ]; then
    warn "SKIP_HTTPX set; skipping"
else
    if ! have httpx; then
        fail "httpx not installed; cannot resolve live hosts"
    elif [ ! -s "$OUT_DIR/subdomains.txt" ]; then
        warn "no subdomains to probe"
    else
        info "httpx -l subdomains.txt -title -tech-detect -status-code"
        # -follow-host-redirects is safe; -no-color keeps output parseable.
        httpx -l "$OUT_DIR/subdomains.txt" \
              -title -tech-detect -status-code \
              -follow-host-redirects \
              -silent \
              -o "$OUT_DIR/live-hosts.txt" 2>/dev/null
        # httpx with -silent writes only the rows we asked for.
        LIVE_COUNT=$(wc -l < "$OUT_DIR/live-hosts.txt" 2>/dev/null | tr -d ' ')
        LIVE_COUNT=${LIVE_COUNT:-0}
        ok "live hosts: ${LIVE_COUNT}"
    fi
fi

# ---------- 3. Port scan ------------------------------------------------------
hdr "[3/6] Top-port scan (nmap)"
if [ -n "${SKIP_NMAP:-}" ]; then
    warn "SKIP_NMAP set; skipping"
else
    if ! have nmap; then
        fail "nmap not installed; skipping port scan"
    elif [ ! -s "$OUT_DIR/live-hosts.txt" ]; then
        warn "no live hosts to scan"
    else
        # Top bug-bounty ports: web front-ends, dev consoles, common admin.
        PORTS="22,80,443,3000,4000,5000,8000,8080,8443,8888,9000,9090,9200,27017"
        # Extract clean URL list from httpx output (URL is the first column
        # with -status-code; for other httpx versions it's hostname:port).
        URL_LIST="$OUT_DIR/urls.txt"
        awk '{print $1}' "$OUT_DIR/live-hosts.txt" \
            | sed -E 's|^https?://||' \
            | cut -d/ -f1 > "$URL_LIST"
        info "nmap -sT -Pn --top-ports 1000 against $(wc -l < "$URL_LIST") hosts"
        # -sT (TCP connect) so we don't need raw socket privileges.
        nmap -sT -Pn --top-ports 1000 \
             -T3 --max-retries 2 \
             -iL "$URL_LIST" \
             -oG "$OUT_DIR/ports.gnmap" \
             -oN "$OUT_DIR/ports.txt" >/dev/null 2>&1 \
            && ok "nmap complete (see ports.txt)" \
            || warn "nmap returned non-zero (partial scan likely)"
    fi
fi

# ---------- 4. Technology detection ------------------------------------------
hdr "[4/6] Technology detection"
if [ -n "${SKIP_TECH:-}" ]; then
    warn "SKIP_TECH set; skipping"
else
    if [ "$HAVE_WHATWEB" -eq 0 ] && [ "$HAVE_NUCLEI" -eq 0 ]; then
        warn "neither whatweb nor nuclei installed; skipping"
    elif [ ! -s "$OUT_DIR/live-hosts.txt" ]; then
        warn "no live hosts to fingerprint"
    else
        : > "$OUT_DIR/tech-stack.txt"
        # Prefer nuclei tech-detect when present — easier to parse.
        if [ "$HAVE_NUCLEI" -eq 1 ]; then
            info "nuclei -asn-tech-detect (bulk, against live hosts)"
            awk '{print $1}' "$OUT_DIR/live-hosts.txt" > "$OUT_DIR/_tech_targets.txt"
            nuclei -l "$OUT_DIR/_tech_targets.txt" \
                   -t technologies/ \
                   -silent \
                   -o "$OUT_DIR/tech-stack.txt" 2>/dev/null \
                && ok "nuclei tech-detect complete" \
                || warn "nuclei tech-detect failed"
        fi
        # Fallback / augment with whatweb on the apex only — it can be slow
        # and noisy against every host.
        if [ "$HAVE_WHATWEB" -eq 1 ]; then
            info "whatweb https://${TARGET}"
            whatweb -a 1 "https://${TARGET}" --no-errors \
                >> "$OUT_DIR/tech-stack.txt" 2>/dev/null \
                && ok "whatweb complete" \
                || warn "whatweb returned non-zero"
        fi
    fi
fi

# ---------- 5. Directory brute ------------------------------------------------
hdr "[5/6] Directory brute (ffuf)"
if [ -n "${SKIP_FFUF:-}" ]; then
    warn "SKIP_FFUF set; skipping"
else
    if ! have ffuf; then
        fail "ffuf not installed; skipping"
    else
        WORDLIST="${ROOT_DIR}/wordlists/common.txt"
        if [ ! -s "$WORDLIST" ]; then
            warn "wordlists/common.txt missing; trying /usr/share/wordlists/dirb/common.txt"
            WORDLIST="/usr/share/wordlists/dirb/common.txt"
        fi
        if [ ! -s "$WORDLIST" ]; then
            fail "no wordlist found; skipping ffuf"
        else
            : > "$OUT_DIR/endpoints.txt"
            # Only brute the apex — bruting every subdomain multiplies load
            # and rarely finds more than a few extra files.
            info "ffuf https://${TARGET}/FUZZ"
            ffuf -u "https://${TARGET}/FUZZ" \
                 -w "$WORDLIST" \
                 -mc 200,201,204,301,302,307,401,403 \
                 -ac \
                 -t 30 \
                 -rate 50 \
                 -recursion-depth 1 \
                 -o "$OUT_DIR/ffuf.json" \
                 -of json \
                 -s 2>/dev/null
            # Flatten ffuf JSON into a plain list for downstream tools.
            if command -v jq >/dev/null 2>&1 && [ -s "$OUT_DIR/ffuf.json" ]; then
                jq -r '.results[]? | "\(.status) \(.url)"' \
                    "$OUT_DIR/ffuf.json" 2>/dev/null > "$OUT_DIR/endpoints.txt" \
                    && ok "ffuf complete: $(wc -l < "$OUT_DIR/endpoints.txt") endpoints" \
                    || warn "ffuf jq parse failed"
            else
                warn "jq not available; ffuf JSON not flattened (still in ffuf.json)"
            fi
        fi
    fi
fi

# ---------- 6. Summary --------------------------------------------------------
hdr "[6/6] Summary"
SUBDOMAIN_COUNT=$(wc -l < "$OUT_DIR/subdomains.txt" 2>/dev/null | tr -d ' '); SUBDOMAIN_COUNT=${SUBDOMAIN_COUNT:-0}
LIVE_COUNT=$(wc -l < "$OUT_DIR/live-hosts.txt" 2>/dev/null | tr -d ' ');       LIVE_COUNT=${LIVE_COUNT:-0}
OPEN_PORT_COUNT=$(grep -cE "^[0-9]+/tcp[[:space:]]+open" "$OUT_DIR/ports.txt" 2>/dev/null || echo 0)
ENDPOINT_COUNT=$(wc -l < "$OUT_DIR/endpoints.txt" 2>/dev/null | tr -d ' ');   ENDPOINT_COUNT=${ENDPOINT_COUNT:-0}

printf "  ${C_BOLD}%-22s${C_OFF} %s\n" "subdomains"          "$SUBDOMAIN_COUNT"
printf "  ${C_BOLD}%-22s${C_OFF} %s\n" "live hosts"          "$LIVE_COUNT"
printf "  ${C_BOLD}%-22s${C_OFF} %s\n" "open TCP ports"      "$OPEN_PORT_COUNT"
printf "  ${C_BOLD}%-22s${C_OFF} %s\n" "endpoints (ffuf)"    "$ENDPOINT_COUNT"
printf "  ${C_BOLD}%-22s${C_OFF} %s\n" "missing tools"       "${#MISSING[@]}"
printf "  ${C_BOLD}%-22s${C_OFF} %s\n" "output"              "programs/${TARGET}/recon/${TS}/"

# Also write the latest run pointer and a human-readable summary.
cat > "$OUT_DIR/SUMMARY.txt" <<EOF
target:        ${TARGET}
timestamp:     ${TS}
subdomains:    ${SUBDOMAIN_COUNT}
live-hosts:    ${LIVE_COUNT}
open-ports:    ${OPEN_PORT_COUNT}
endpoints:     ${ENDPOINT_COUNT}
missing-tools: ${MISSING[*]:-}
EOF

# Mirror the stable files into the parent recon dir so the older skills
# (which read programs/<target>/recon/live-hosts.txt) keep working.
for f in subdomains.txt live-hosts.txt ports.txt tech-stack.txt endpoints.txt; do
    if [ -s "$OUT_DIR/$f" ]; then
        cp -f "$OUT_DIR/$f" "${ROOT_DIR}/programs/${TARGET}/recon/$f"
    fi
done

ok "recon complete. Next: ./hunt.sh ${TARGET}"
