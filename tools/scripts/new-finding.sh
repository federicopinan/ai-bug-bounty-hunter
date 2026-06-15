#!/usr/bin/env bash
# =============================================================================
# new-finding.sh — create a HackerOne-style finding draft
# =============================================================================
# Usage:  ./new-finding.sh <severity> <type> <title> [target]
#         ./new-finding.sh --force <severity> <type> <title> [target]
#         ./new-finding.sh --help
# =============================================================================

set -u

if [ -t 1 ]; then
    C_OK="\033[1;32m"
    C_FAIL="\033[1;31m"
    C_WARN="\033[1;33m"
    C_INFO="\033[1;36m"
    C_OFF="\033[0m"
else
    C_OK=""; C_FAIL=""; C_WARN=""; C_INFO=""; C_OFF=""
fi

ok()   { printf "  ${C_OK}[+]${C_OFF} %s\n" "$*"; }
fail() { printf "  ${C_FAIL}[-]${C_OFF} %s\n" "$*" >&2; }
warn() { printf "  ${C_WARN}[!]${C_OFF} %s\n" "$*" >&2; }
info() { printf "  ${C_INFO}[*]${C_OFF} %s\n" "$*"; }

print_help() {
    cat <<EOF
new-finding.sh — create a safe HackerOne-style Markdown finding draft

USAGE
    ./new-finding.sh <severity> <type> <title> [target]
    ./new-finding.sh --force <severity> <type> <title> [target]
    ./new-finding.sh --help

ARGUMENTS
    severity   Informational, Low, Medium, High, or Critical
    type       Vulnerability class, e.g. IDOR, SQLi, Stored-XSS, SSRF
    title      Short finding title. Quote titles containing spaces.
    target     Optional target name. When provided, writes to
               programs/<target>/vulns/. Without target, writes to the
               current directory.

SAFETY
    Existing files are not overwritten unless --force is provided.
    The generated draft includes placeholders and safety reminders; fill in
    only validated, in-scope evidence before submitting.

EXAMPLES
    ./new-finding.sh High IDOR "Invoice download exposes other users" acme.com
    ./new-finding.sh --force Medium XSS "Reflected XSS in search"
EOF
}

FORCE=0
case "${1:-}" in
    --help|-h)
        print_help
        exit 0
        ;;
    --force)
        FORCE=1
        shift
        ;;
esac

if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    fail "expected <severity> <type> <title> [target]"
    echo
    print_help
    exit 1
fi

SEVERITY="$1"
FINDING_TYPE="$2"
TITLE="$3"
TARGET="${4:-}"

case "$SEVERITY" in
    Informational|Info|Low|Medium|High|Critical|informational|info|low|medium|high|critical)
        ;;
    *)
        fail "unsupported severity: $SEVERITY"
        warn "Use one of: Informational, Low, Medium, High, Critical"
        exit 1
        ;;
esac

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

slugify() {
    printf '%s' "$*" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

sanitize_target() {
    local raw="$1"
    local clean

    clean="${raw#http://}"
    clean="${clean#https://}"
    clean="${clean%/}"

    if [ -z "$clean" ]; then
        fail "target cannot be empty"
        return 1
    fi

    if [[ "$clean" == *"/"* ]] || [[ "$clean" == *".."* ]] || [[ ! "$clean" =~ ^[A-Za-z0-9._-]+$ ]]; then
        fail "unsafe target name: $raw"
        warn "Use a simple in-scope target identifier such as example.com, api-example, or acme_app."
        return 1
    fi

    printf '%s' "$clean"
}

TYPE_SLUG="$(slugify "$FINDING_TYPE")"
TITLE_SLUG="$(slugify "$TITLE")"
DATE="$(date -u +%Y%m%d)"
FILENAME="${DATE}-${SEVERITY,,}-${TYPE_SLUG}-${TITLE_SLUG}.md"

if [ -n "$TARGET" ]; then
    if ! TARGET_CLEAN="$(sanitize_target "$TARGET")"; then
        exit 1
    fi
    OUT_DIR="${ROOT_DIR}/programs/${TARGET_CLEAN}/vulns"
    SCOPE_VALUE="programs/${TARGET_CLEAN}/scope.md"
else
    TARGET_CLEAN=""
    OUT_DIR="$(pwd)"
    SCOPE_VALUE="TODO: target scope reference"
fi

mkdir -p "$OUT_DIR"
OUT_FILE="${OUT_DIR}/${FILENAME}"

if [ -e "$OUT_FILE" ] && [ "$FORCE" -ne 1 ]; then
    fail "finding already exists: $OUT_FILE"
    warn "Re-run with --force to overwrite."
    exit 1
fi

cat > "$OUT_FILE" <<EOF
# [${SEVERITY}] ${FINDING_TYPE} — ${TITLE}

## Title

[${SEVERITY}] ${FINDING_TYPE} in TODO location allows TODO impact

## Summary

TODO: One concise paragraph describing what was found, how it was found, and the validated impact. Avoid theoretical language.

## Scope

- Target: ${TARGET_CLEAN:-TODO}
- Scope reference: ${SCOPE_VALUE}
- Program policy checked: TODO
- Exclusions reviewed: TODO

## Severity

- Rating: ${SEVERITY}
- CVSS vector: TODO (required for High/Critical)
- CWE: TODO
- Rationale: TODO

## Steps to Reproduce

1. TODO: Start from an in-scope account/session.
2. TODO: Send the exact request or perform the exact UI action.
3. TODO: Observe the unauthorized or vulnerable behavior.
4. TODO: Repeat with the negative control, if applicable.

## Impact

TODO: State what an attacker can do right now and connect it to business damage. Include affected data classes, affected roles, tenant boundaries, financial impact, or account takeover path where applicable.

## Evidence

- Evidence ID(s): TODO
- HTTP request/response: TODO
- Screenshots: TODO
- PoC output: TODO
- Redaction notes: TODO

Safety reminders:

- Capture the minimum data needed to prove impact.
- Redact cookies, tokens, secrets, and unrelated user data.
- Do not include out-of-scope traffic or destructive test output.

## Mitigation

TODO: Provide a specific, implementable fix. Example: enforce server-side authorization checks on resource ownership before returning or mutating the object.

## References

- TODO: CWE / OWASP / vendor docs / similar public writeups

## Validation Status

- [ ] Asset is in scope.
- [ ] Bug class is not excluded.
- [ ] Exploitability is confirmed.
- [ ] Business impact is demonstrated.
- [ ] Evidence is sanitized and reproducible.
- [ ] Duplicate search completed.
- [ ] Report language is definitive, not speculative.
EOF

ok "finding created: $OUT_FILE"
info "next: validate impact, attach sanitized evidence, and update tracker.md"
