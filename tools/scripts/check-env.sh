#!/usr/bin/env bash
# =============================================================================
# check-env.sh — safe dependency checker for bug bounty tooling
# =============================================================================
# Usage:  ./check-env.sh
#         ./check-env.sh --help
#
# Safe by default: this script never installs packages, never uses sudo, and
# never changes system state. It only checks PATH and prints suggested commands.
# =============================================================================

set -u

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
fail() { printf "  ${C_FAIL}[-]${C_OFF} %s\n" "$*"; }
warn() { printf "  ${C_WARN}[!]${C_OFF} %s\n" "$*"; }
info() { printf "  ${C_INFO}[*]${C_OFF} %s\n" "$*"; }
hdr()  { printf "\n${C_BOLD}== %s ==${C_OFF}\n" "$*"; }

print_help() {
    cat <<EOF
check-env.sh — verify required bug bounty tools are on PATH

USAGE
    ./check-env.sh              Check required tools
    ./check-env.sh --help       Show this help

REQUIRED TOOLS
    subfinder amass httpx nuclei ffuf whatweb jq git curl

SAFETY
    This script is read-only. It does not install packages, run sudo, or modify
    files. If tools are missing, it prints suggested Kali apt/go commands for
    you to review and run manually.

EXIT STATUS
    0   all required tools are present
    1   one or more required tools are missing
EOF
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && { print_help; exit 0; }

if [ $# -gt 0 ]; then
    fail "unexpected argument: $1"
    echo
    print_help
    exit 1
fi

have() { command -v "$1" >/dev/null 2>&1; }

REQUIRED_TOOLS=(subfinder amass httpx nuclei ffuf whatweb jq git curl)
PRESENT=()
MISSING=()

hdr "Environment check"
info "checking required tools on PATH"

for tool in "${REQUIRED_TOOLS[@]}"; do
    if have "$tool"; then
        PRESENT+=("$tool")
        ok "$tool: $(command -v "$tool")"
    else
        MISSING+=("$tool")
        fail "$tool: not found on PATH"
    fi
done

hdr "Summary"
printf "  ${C_BOLD}%-18s${C_OFF} %s\n" "present" "${#PRESENT[@]} / ${#REQUIRED_TOOLS[@]}"
printf "  ${C_BOLD}%-18s${C_OFF} %s\n" "missing" "${#MISSING[@]}"

if [ "${#MISSING[@]}" -gt 0 ]; then
    printf "  ${C_BOLD}%-18s${C_OFF} %s\n" "missing list" "${MISSING[*]}"
    echo
    warn "No installation was performed. Review and run commands manually if appropriate."
    cat <<'EOF'

Suggested Kali / Debian packages:
    sudo apt update
    sudo apt install -y amass ffuf whatweb jq git curl

Suggested ProjectDiscovery Go installs (requires Go and GOPATH/bin on PATH):
    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest
    go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest

After installing, re-run:
    tools/scripts/check-env.sh
EOF
    exit 1
fi

ok "all required tools are present"
