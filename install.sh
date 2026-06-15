#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Hunter — Bug Bounty Toolchain Installer
#
# Installs the full set of recon, fuzzing, vuln-scan, secrets, OAST, mobile
# and screenshot tools referenced by the bug-bounty-* skills.
#
# Usage:
#   ./install.sh                # full install (default)
#   ./install.sh --check        # verify installation, report OK / MISSING
#   ./install.sh --tools-only   # skip wordlists and templates
#   ./install.sh --wordlists-only
#   ./install.sh --update       # update tools (go install -u) + wordlists (git pull)
#   ./install.sh --uninstall    # remove everything installed by this script
#   ./install.sh --help
#
# Target: Debian / Ubuntu / Kali (apt). Other distros are detected and warned.
# Idempotent: re-running will skip already-installed components.
# Silent by default; passes output through a logging layer with timestamps.
# ─────────────────────────────────────────────────────────────────────────────

set -Eeuo pipefail

# ──────────────────────────────────────────────────────────────
# Paths & configuration
# ──────────────────────────────────────────────────────────────
TOOLS_DIR="${HOME}/tools/bin"
WORDLISTS_DIR="${HOME}/wordlists"
TEMPLATES_DIR="${HOME}/nuclei-templates"
GO_DIR="${HOME}/go"
GO_BIN="${GO_DIR}/bin"
GO_VERSION="1.22.5"
GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"

MARKER_DIR="${HOME}/.config/hunter"
INSTALLED_LOG="${MARKER_DIR}/installed.txt"

# Colors (auto-disable when not a TTY)
if [[ -t 1 ]]; then
	C_RESET=$'\033[0m'
	C_BOLD=$'\033[1m'
	C_RED=$'\033[31m'
	C_GREEN=$'\033[32m'
	C_YELLOW=$'\033[33m'
	C_BLUE=$'\033[34m'
	C_CYAN=$'\033[36m'
else
	C_RESET=""
	C_BOLD=""
	C_RED=""
	C_GREEN=""
	C_YELLOW=""
	C_BLUE=""
	C_CYAN=""
fi

# ──────────────────────────────────────────────────────────────
# Logging
# ──────────────────────────────────────────────────────────────
log() { printf "%s[•]%s %s\n" "$C_BLUE" "$C_RESET" "$*"; }
ok() { printf "%s[✓]%s %s\n" "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf "%s[!]%s %s\n" "$C_YELLOW" "$C_RESET" "$*" >&2; }
err() { printf "%s[✗]%s %s\n" "$C_RED" "$C_RESET" "$*" >&2; }
section() { printf "\n%s%s── %s ──%s\n" "$C_BOLD" "$C_CYAN" "$*" "$C_RESET"; }

# Track what we did so --uninstall can reverse it
mark() {
	mkdir -p "$MARKER_DIR"
	echo "$*" >>"$INSTALLED_LOG"
}
unmark() {
	mkdir -p "$MARKER_DIR"
	touch "$INSTALLED_LOG"
	grep -vFx "$*" "$INSTALLED_LOG" >"${INSTALLED_LOG}.tmp" 2>/dev/null || true
	mv "${INSTALLED_LOG}.tmp" "$INSTALLED_LOG" 2>/dev/null || true
}

# Run a command and capture success/failure without aborting the script
# Usage: try "description" command arg1 arg2 ...
try() {
	local desc="$1"
	shift
	if "$@" >/dev/null 2>&1; then
		ok "$desc"
		return 0
	else
		err "FAILED: $desc"
		return 1
	fi
}

# ──────────────────────────────────────────────────────────────
# Preflight
# ──────────────────────────────────────────────────────────────
preflight() {
	section "Preflight"

	if [[ "$EUID" -eq 0 ]]; then
		err "Do not run as root. Run as a normal user with sudo capability."
		exit 1
	fi

	if ! command -v sudo >/dev/null 2>&1; then
		err "sudo is required but not installed. Install it first: apt install sudo"
		exit 1
	fi

	if ! command -v apt-get >/dev/null 2>&1; then
		warn "This installer targets Debian / Ubuntu / Kali (apt)."
		warn "Detected package manager is not apt. Continuing in best-effort mode."
	else
		log "Detected apt-based system"
	fi

	# Architecture check
	local arch
	arch="$(uname -m)"
	case "$arch" in
	x86_64 | amd64) GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz" ;;
	aarch64 | arm64) GO_TARBALL="go${GO_VERSION}.linux-arm64.tar.gz" ;;
	*) warn "Untested architecture: $arch. Continuing." ;;
	esac

	mkdir -p "$TOOLS_DIR" "$WORDLISTS_DIR" "$MARKER_DIR"
	touch "$INSTALLED_LOG"
}

# ──────────────────────────────────────────────────────────────
# System dependencies
# ──────────────────────────────────────────────────────────────
install_system_deps() {
	section "System dependencies"

	local pkgs=(
		build-essential
		git
		curl
		wget
		ca-certificates
		jq
		python3
		python3-pip
		python3-venv
		pipx
		libpcap-dev
		dnsutils
		net-tools
		unzip
		zip
		nmap
		libssl-dev
		libffi-dev
		whois
		parallel
	)

	log "Updating apt cache"
	sudo apt-get update -qq

	log "Installing: ${pkgs[*]}"
	if sudo apt-get install -y -qq "${pkgs[@]}" >/dev/null 2>&1; then
		ok "apt packages installed"
	else
		warn "Some apt packages failed to install. Continuing with what we have."
	fi
}

# ──────────────────────────────────────────────────────────────
# Go toolchain
# ──────────────────────────────────────────────────────────────
install_go() {
	section "Go toolchain (${GO_VERSION})"

	if command -v go >/dev/null 2>&1; then
		local v
		v="$(go version | awk '{print $3}' | sed 's/go//')"
		log "Existing Go ${v} detected"
		if printf '%s\n%s\n' "$GO_VERSION" "$v" | sort -V -C; then
			ok "Go ${v} satisfies requirement (>= ${GO_VERSION})"
			return 0
		else
			warn "Go ${v} is older than ${GO_VERSION}. Will install a private toolchain to ${GO_DIR}."
		fi
	fi

	if [[ -x "${GO_DIR}/bin/go" ]]; then
		ok "Private Go toolchain already installed at ${GO_DIR}/bin/go"
		return 0
	fi

	log "Downloading Go ${GO_VERSION}"
	local url="https://go.dev/dl/${GO_TARBALL}"
	local tmp
	tmp="$(mktemp -d)"
	curl -fsSL "$url" -o "${tmp}/${GO_TARBALL}"

	log "Extracting to ${GO_DIR}"
	rm -rf "$GO_DIR"
	mkdir -p "$(dirname "$GO_DIR")"
	tar -C "$(dirname "$GO_DIR")" -xzf "${tmp}/${GO_TARBALL}"
	rm -rf "$tmp"

	if [[ -x "${GO_BIN}/go" ]]; then
		ok "Go installed: $(${GO_BIN}/go version)"
	else
		err "Go installation failed"
		return 1
	fi
}

# Export Go-related env for this run
export_gopath() {
	export GOPATH="$GO_DIR"
	export GOBIN="$GO_BIN"
	export PATH="$GO_BIN:$TOOLS_DIR:$PATH"
	mkdir -p "$GO_BIN"
}

# ──────────────────────────────────────────────────────────────
# Go tools
# ──────────────────────────────────────────────────────────────
GO_TOOLS=(
	# name                                     module
	"github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
	"github.com/projectdiscovery/httpx/cmd/httpx"
	"github.com/projectdiscovery/dnsx/cmd/dnsx"
	"github.com/projectdiscovery/katana/cmd/katana"
	"github.com/projectdiscovery/nuclei/v3/cmd/nuclei"
	"github.com/projectdiscovery/naabu/v2/cmd/naabu"
	"github.com/projectdiscovery/interactsh/cmd/interactsh-client"
	"github.com/ffuf/ffuf/v2"
	"github.com/OJ/gobuster/v3"
	"github.com/tomnomnom/waybackurls"
	"github.com/tomnomnom/gau/v2/cmd/gau"
	"github.com/tomnomnom/unfurl"
	"github.com/hahwul/dalfox/v2"
	"github.com/007sair/tpinfo"
	"github.com/owasp-amass/amass/v4/..."
)

install_go_tools() {
	section "Go security tools"

	export_gopath

	local bin name mod fails=()
	for mod in "${GO_TOOLS[@]}"; do
		name="$(basename "$mod")"
		# The "..." suffix means install the whole module tree
		if [[ "$mod" == *"..." ]]; then
			bin="$(basename "${mod%/*}")" # e.g. amass
		else
			bin="${name}"
		fi
		if [[ -x "${GO_BIN}/${bin}" ]]; then
			ok "Already installed: ${bin}"
			continue
		fi
		log "go install ${mod}"
		if go install "$mod@latest" 2>/dev/null; then
			ok "Installed: ${bin}"
		else
			err "Failed: ${bin}"
			fails+=("$bin")
		fi
	done

	if ((${#fails[@]} > 0)); then
		warn "Failed Go tools: ${fails[*]}"
	fi
}

# ──────────────────────────────────────────────────────────────
# Python tools (via pipx)
# ──────────────────────────────────────────────────────────────
PIPX_TOOLS=(
	"sqlmap"
	"trufflehog"
	"gitleaks"
	"jwt_tool"
	"arjun"
)

install_python_tools() {
	section "Python security tools (pipx)"

	if ! command -v pipx >/dev/null 2>&1; then
		warn "pipx not found despite being in apt deps. Installing now."
		sudo apt-get install -y -qq pipx >/dev/null 2>&1 || true
		python3 -m pip install --user pipx 2>/dev/null || true
	fi

	if ! command -v pipx >/dev/null 2>&1; then
		warn "pipx still not available. Skipping Python tools."
		return 0
	fi

	pipx ensurepath >/dev/null 2>&1 || true

	local pypkg
	for pypkg in "${PIPX_TOOLS[@]}"; do
		if pipx list 2>/dev/null | grep -q "package ${pypkg}"; then
			ok "Already installed: ${pypkg}"
			continue
		fi
		log "pipx install ${pypkg}"
		if pipx install "$pypkg" >/dev/null 2>&1; then
			ok "Installed: ${pypkg}"
		else
			err "Failed: ${pypkg}"
		fi
	done

	# XSStrike needs a slightly different install: it's a git repo, not a pypi pkg
	if [[ ! -d "${HOME}/.local/pipx/venvs/xsstrike" ]]; then
		log "Installing XSStrike from git"
		pipx install "git+https://github.com/s0md3v/XSStrike.git" >/dev/null 2>&1 &&
			ok "Installed: xsstrike" ||
			err "Failed: xsstrike"
	fi
}

# ──────────────────────────────────────────────────────────────
# Direct binary downloads
# ──────────────────────────────────────────────────────────────
install_direct_binaries() {
	section "Direct binary downloads"

	export_gopath

	# assetfinder — tomnomnom
	if ! command -v assetfinder >/dev/null 2>&1; then
		log "Installing assetfinder"
		go install "github.com/tomnomnom/assetfinder@latest" 2>/dev/null &&
			ok "Installed: assetfinder" ||
			err "Failed: assetfinder"
	else
		ok "Already installed: assetfinder"
	fi

	# gowitness — screenshot tool
	if ! command -v gowitness >/dev/null 2>&1; then
		log "Installing gowitness"
		go install "github.com/sensepost/gowitness@latest" 2>/dev/null &&
			ok "Installed: gowitness" ||
			err "Failed: gowitness"
	else
		ok "Already installed: gowitness"
	fi

	# mitmproxy (Python wheel)
	if ! command -v mitmproxy >/dev/null 2>&1; then
		log "Installing mitmproxy"
		python3 -m pip install --user --quiet mitmproxy 2>/dev/null &&
			ok "Installed: mitmproxy" ||
			err "Failed: mitmproxy"
	else
		ok "Already installed: mitmproxy"
	fi

	# apktool — Java jar
	if ! command -v apktool >/dev/null 2>&1; then
		log "Installing apktool"
		local url="https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool"
		local jar="https://github.com/iBotPeaches/Apktool/releases/download/v2.9.3/apktool_2.9.3.jar"
		if sudo curl -fsSL "$url" -o /usr/local/bin/apktool &&
			sudo curl -fsSL "$jar" -o /usr/local/bin/apktool.jar &&
			sudo chmod +x /usr/local/bin/apktool; then
			ok "Installed: apktool"
		else
			err "Failed: apktool"
		fi
	else
		ok "Already installed: apktool"
	fi

	# jadx — release zip
	if ! command -v jadx >/dev/null 2>&1; then
		log "Installing jadx"
		local tmp
		tmp="$(mktemp -d)"
		if curl -fsSL "https://github.com/skylot/jadx/releases/download/v1.5.0/jadx-1.5.0.zip" \
			-o "${tmp}/jadx.zip" &&
			sudo unzip -q -o "${tmp}/jadx.zip" -d /opt/jadx &&
			sudo ln -sf /opt/jadx/bin/jadx /usr/local/bin/jadx; then
			ok "Installed: jadx"
		else
			err "Failed: jadx (Java missing?)"
		fi
		rm -rf "$tmp"
	else
		ok "Already installed: jadx"
	fi
}

# ──────────────────────────────────────────────────────────────
# Wordlists
# ──────────────────────────────────────────────────────────────
WORDLIST_REPOS=(
	"https://github.com/danielmiessler/SecLists.git"
	"https://github.com/six2dez/OneListForAll.git"
	"https://github.com/0xPugal/fuzz4bounty.git"
	"https://github.com/swisskyrepo/PayloadsAllTheThings.git"
	"https://github.com/n0kovo/n0kovo_subdomains.git"
	"https://github.com/BrownBearSec/SDTO-realworld-subdomains.git"
)

install_wordlists() {
	section "Wordlists (${WORDLISTS_DIR})"

	local repo dir name
	for repo in "${WORDLIST_REPOS[@]}"; do
		name="$(basename "$repo" .git)"
		dir="${WORDLISTS_DIR}/${name}"
		if [[ -d "$dir" ]]; then
			ok "Already present: ${name}"
		else
			log "Cloning ${name}"
			if git clone --depth 1 "$repo" "$dir" >/dev/null 2>&1; then
				ok "Cloned: ${name}"
			else
				err "Failed clone: ${name}"
			fi
		fi
	done
}

# ──────────────────────────────────────────────────────────────
# Nuclei templates
# ──────────────────────────────────────────────────────────────
install_nuclei_templates() {
	section "Nuclei templates"

	if [[ ! -d "$TEMPLATES_DIR" ]]; then
		log "Cloning nuclei-templates to ${TEMPLATES_DIR}"
		if git clone --depth 1 "https://github.com/projectdiscovery/nuclei-templates.git" \
			"$TEMPLATES_DIR" >/dev/null 2>&1; then
			ok "Cloned nuclei-templates"
		else
			err "Failed to clone nuclei-templates"
			return 1
		fi
	else
		ok "Already present: nuclei-templates"
	fi

	if command -v nuclei >/dev/null 2>&1; then
		log "Running nuclei -update-templates"
		nuclei -update-templates >/dev/null 2>&1 || true
		ok "Nuclei templates synced"
	fi
}

# ──────────────────────────────────────────────────────────────
# PATH persistence
# ──────────────────────────────────────────────────────────────
PATH_LINES=(
	"export GOPATH=\"\$HOME/go\""
	"export GOBIN=\"\$HOME/go/bin\""
	"export PATH=\"\$HOME/go/bin:\$HOME/.local/bin:\$PATH\""
)

persist_path() {
	section "PATH persistence"

	local rc=""
	for candidate in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
		if [[ -f "$candidate" ]]; then
			rc="$candidate"
			break
		fi
	done
	if [[ -z "$rc" ]]; then
		rc="$HOME/.bashrc"
		touch "$rc"
	fi

	local line added=0
	for line in "${PATH_LINES[@]}"; do
		if ! grep -qF "$line" "$rc" 2>/dev/null; then
			echo "$line" >>"$rc"
			added=$((added + 1))
		fi
	done

	if ((added > 0)); then
		ok "Added ${added} PATH line(s) to ${rc}"
	else
		ok "PATH already configured in ${rc}"
	fi
}

# ──────────────────────────────────────────────────────────────
# Update mode
# ──────────────────────────────────────────────────────────────
update_all() {
	section "Updating everything"

	export_gopath

	log "Updating Go tools"
	local mod
	for mod in "${GO_TOOLS[@]}"; do
		log "go install -u ${mod}"
		go install -u "$mod@latest" 2>/dev/null || warn "Update failed: ${mod}"
	done

	log "Updating pipx packages"
	if command -v pipx >/dev/null 2>&1; then
		pipx upgrade-all 2>/dev/null || warn "Some pipx upgrades failed"
	fi

	log "Updating wordlists"
	local dir
	for dir in "$WORDLISTS_DIR"/*/; do
		[[ -d "$dir" ]] || continue
		if [[ -d "${dir}.git" ]]; then
			log "git pull in $(basename "$dir")"
			(cd "$dir" && git pull --depth 1) >/dev/null 2>&1 &&
				ok "Updated: $(basename "$dir")" ||
				warn "Update failed: $(basename "$dir")"
		fi
	done

	log "Updating nuclei templates"
	if [[ -d "$TEMPLATES_DIR/.git" ]]; then
		(cd "$TEMPLATES_DIR" && git pull --depth 1) >/dev/null 2>&1 &&
			ok "Updated: nuclei-templates"
	fi
	if command -v nuclei >/dev/null 2>&1; then
		nuclei -update-templates >/dev/null 2>&1 || true
	fi
}

# ──────────────────────────────────────────────────────────────
# Uninstall
# ──────────────────────────────────────────────────────────────
uninstall_all() {
	section "Uninstall"

	local answer
	read -r -p "Remove all tools, wordlists, and templates installed by this script? [y/N] " answer
	if [[ ! "$answer" =~ ^[Yy]$ ]]; then
		log "Aborted."
		return 0
	fi

	log "Removing ${GO_BIN}"
	rm -rf "$GO_BIN"

	log "Removing ${TEMPLATES_DIR}"
	rm -rf "$TEMPLATES_DIR"

	log "Removing ${WORDLISTS_DIR}"
	rm -rf "$WORDLISTS_DIR"

	log "Removing ${GO_DIR} (Go toolchain)"
	rm -rf "$GO_DIR"

	log "Removing pipx packages: ${PIPX_TOOLS[*]}"
	local p
	for p in "${PIPX_TOOLS[@]}" xsstrike; do
		pipx uninstall "$p" 2>/dev/null || true
	done

	log "Removing ${MARKER_DIR}"
	rm -rf "$MARKER_DIR"

	ok "Uninstall complete. APT packages and PATH lines in rc files are kept (review manually)."
}

# ──────────────────────────────────────────────────────────────
# Verify
# ──────────────────────────────────────────────────────────────
ALL_BINARIES=(
	# Go
	"subfinder" "httpx" "dnsx" "katana" "nuclei" "naabu"
	"interactsh-client" "ffuf" "gobuster" "waybackurls" "gau"
	"unfurl" "dalfox" "assetfinder" "gowitness" "amass"
	# Python (pipx)
	"sqlmap" "trufflehog" "gitleaks" "jwt_tool" "arjun" "xsstrike"
	# Other
	"mitmproxy" "apktool" "jadx"
	# System
	"nmap" "jq" "go" "git" "curl" "wget" "python3" "pipx"
)

check_install() {
	section "Verification"

	local present=0 missing=0 missing_list=()
	local tool
	for tool in "${ALL_BINARIES[@]}"; do
		if command -v "$tool" >/dev/null 2>&1; then
			local ver
			ver="$("$tool" --version 2>/dev/null | head -1 || echo 'present')"
			printf "  %s✓%s  %-22s  %s\n" "$C_GREEN" "$C_RESET" "$tool" "$ver"
			present=$((present + 1))
		else
			printf "  %s✗%s  %-22s  MISSING\n" "$C_RED" "$C_RESET" "$tool"
			missing=$((missing + 1))
			missing_list+=("$tool")
		fi
	done

	echo
	if ((missing == 0)); then
		ok "All ${present} tools present. You're ready to hunt."
	else
		warn "${missing} tool(s) missing: ${missing_list[*]}"
		warn "Run './install.sh' to retry, or check the install log for details."
	fi

	# Wordlist check
	section "Wordlists"
	if [[ -d "$WORDLISTS_DIR" ]]; then
		local d
		for d in "$WORDLISTS_DIR"/*/; do
			[[ -d "$d" ]] || continue
			printf "  %s✓%s  %s\n" "$C_GREEN" "$C_RESET" "$(basename "$d")"
		done
	else
		warn "No wordlists directory at ${WORDLISTS_DIR}. Run './install.sh --wordlists-only'."
	fi
}

# ──────────────────────────────────────────────────────────────
# Help
# ──────────────────────────────────────────────────────────────
usage() {
	cat <<EOF
Hunter — Bug Bounty Toolchain Installer

Usage:
  ./install.sh                  Full install (default)
  ./install.sh --check          Verify installed tools, report missing
  ./install.sh --tools-only     Skip wordlists and templates
  ./install.sh --wordlists-only Only clone/update wordlists
  ./install.sh --update         Update tools + wordlists + templates
  ./install.sh --uninstall      Remove everything this script installed
  ./install.sh --help           This message

Paths:
  Go binaries:    ${GO_BIN}
  Wordlists:      ${WORDLISTS_DIR}
  Nuclei tpls:    ${TEMPLATES_DIR}
  Install log:    ${INSTALLED_LOG}
EOF
}

# ──────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────
main() {
	local mode="full"
	for arg in "$@"; do
		case "$arg" in
		--check) mode="check" ;;
		--tools-only) mode="tools" ;;
		--wordlists-only) mode="wordlists" ;;
		--update) mode="update" ;;
		--uninstall) mode="uninstall" ;;
		--help | -h)
			usage
			exit 0
			;;
		*)
			err "Unknown flag: $arg"
			usage
			exit 2
			;;
		esac
	done

	printf "%s%sHunter — Bug Bounty Toolchain%s\n" "$C_BOLD" "$C_CYAN" "$C_RESET"

	case "$mode" in
	full)
		preflight
		install_system_deps
		install_go
		install_go_tools
		install_python_tools
		install_direct_binaries
		install_wordlists
		install_nuclei_templates
		persist_path
		check_install
		section "Done"
		ok "Restart your shell or 'source ~/.bashrc' to pick up new PATH."
		ok "Then run 'make check' or './install.sh --check' to re-verify."
		;;
	tools)
		preflight
		install_system_deps
		install_go
		install_go_tools
		install_python_tools
		install_direct_binaries
		persist_path
		check_install
		;;
	wordlists)
		install_wordlists
		install_nuclei_templates
		;;
	update)
		update_all
		check_install
		;;
	uninstall)
		uninstall_all
		;;
	check)
		check_install
		;;
	esac
}

main "$@"
