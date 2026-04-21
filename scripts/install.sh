#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly SUPPORT_DIR="$HOME/Library/Application Support/MacHackerToolkit"
readonly LOG_FILE="$SUPPORT_DIR/install_$(date +%Y%m%d_%H%M%S).log"
readonly MIN_MACOS_VERSION="14.0"

readonly DRY_RUN=false
readonly SKIP_FAILED=false
readonly CATEGORY="all"

declare -a INSTALLED=()
declare -a FAILED=()
declare -a SKIPPED=()

# ── Colors ──────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    R='\033[0;31m' G='\033[0;32m' Y='\033[0;33m' B='\033[0;34m'
    M='\033[0;35m' C='\033[0;36m' W='\033[1;37m' D='\033[2m'
    BOLD='\033[1m' DIM='\033[2m' RESET='\033[0m'
else
    R='' G='' Y='' B='' M='' C='' W='' BOLD='' DIM='' RESET=''
fi

# ── Logging ─────────────────────────────────────────────────────────────────
_log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$ts] [$level] $msg" >> "$LOG_FILE" 2>/dev/null || true
}

info()  { printf "${G}[✓]${RESET} %s\n" "$*"; _log INFO "$*"; }
warn()  { printf "${Y}[!]${RESET} %s\n" "$*"; _log WARN "$*"; }
error() { printf "${R}[✗]${RESET} %s\n" "$*"; _log ERROR "$*"; }
step()  { printf "${C}[→]${RESET} %s\n" "$*"; _log STEP "$*"; }
header(){ printf "\n${BOLD}${W}═══ %s ═══${RESET}\n" "$*"; _log HEADER "$*"; }
dry()   { printf "${M}[DRY]${RESET} %s\n" "$*"; }

# ── Progress ────────────────────────────────────────────────────────────────
PROGRESS_TOTAL=0
PROGRESS_CURRENT=0

progress_start() { PROGRESS_TOTAL=$1; PROGRESS_CURRENT=0; }
progress_tick()  {
    ((PROGRESS_CURRENT++)) || true
    local pct=$(( PROGRESS_CURRENT * 100 / PROGRESS_TOTAL ))
    printf "${D}  [%d/%d %d%%]${RESET}\n" "$PROGRESS_CURRENT" "$PROGRESS_TOTAL" "$pct"
}

# ── Tool categories ─────────────────────────────────────────────────────────
declare -A TOOL_CATEGORIES
TOOL_CATEGORIES[recon]="nmap masscan rustscan"
TOOL_CATEGORIES[network]="wireshark tcpdump"
TOOL_CATEGORIES[wireless]="aircrack-ng reaver pixiewps cowpatty"
TOOL_CATEGORIES[cracking]="hashcat john hydra medusa patator"
TOOL_CATEGORIES[exploit]="metasploit-framework bettercap sqlmap nikto"
TOOL_CATEGORIES[forensics]="binwalk foremost sleuthkit volatility"
TOOL_CATEGORIES[reverse]="ghidra radare2 cutter frida"
TOOL_CATEGORIES[sdr]="gqrx rtl-433 ubertooth hackrf"
TOOL_CATEGORIES[web]="dirb gobuster ffuf wfuzz amass subfinder"
TOOL_CATEGORIES[wordlists]="crunch wordlists"
TOOL_CATEGORIES[ai]="ollama"

readonly PYTHON_DEPS="scapy impacket pwntools yara volatility3 langchain"

# ── Usage ───────────────────────────────────────────────────────────────────
usage() {
    cat <<EOF
${BOLD}Mac Hacker Toolkit — Installer${RESET}

${BOLD}USAGE${RESET}
    $(basename "$0") [OPTIONS]

${BOLD}OPTIONS${RESET}
    --dry-run           Preview what would be installed without making changes
    --skip-failed       Continue on failures instead of aborting
    --category <cat>    Install only a specific category:
                          recon | network | wireless | cracking | exploit |
                          forensics | reverse | sdr | web | wordlists | ai | python | all
    --help              Show this help message

${BOLD}CATEGORIES${RESET}
    recon         Network reconnaissance (nmap, masscan, rustscan)
    network       Network analysis (wireshark, tcpdump)
    wireless      WiFi tools (aircrack-ng, reaver, pixiewps, cowpatty)
    cracking      Password cracking (hashcat, john, hydra, medusa, patator)
    exploit       Exploitation frameworks (metasploit, bettercap, sqlmap, nikto)
    forensics     Digital forensics (binwalk, foremost, sleuthkit, volatility)
    reverse       Reverse engineering (ghidra, radare2, cutter, frida)
    sdr           Software-defined radio (gqrx, rtl-433, ubertooth, hackrf)
    web           Web testing (dirb, gobuster, ffuf, wfuzz, amass, subfinder)
    wordlists     Wordlist tools (crunch, rockyou)
    ai            AI/LLM tools (ollama + models)
    python        Python packages (scapy, impacket, pwntools, yara, volatility3, langchain)
    all           Everything (default)

EOF
    exit 0
}

# ── Argument parsing ────────────────────────────────────────────────────────
DRY_RUN=false
SKIP_FAILED=false
CATEGORY="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)      DRY_RUN=true;  shift ;;
        --skip-failed)  SKIP_FAILED=true; shift ;;
        --category)     CATEGORY="${2:-}"; shift 2 ;;
        --help|-h)      usage ;;
        *) error "Unknown option: $1"; usage ;;
    esac
done

# ── Helpers ─────────────────────────────────────────────────────────────────
ver_lte() {
    printf '%s\n%s' "$1" "$2" | sort -V -C 2>/dev/null
}

cmd_exists() {
    command -v "$1" &>/dev/null
}

brew_install() {
    local pkg="$1"
    if $DRY_RUN; then
        dry "brew install $pkg"
        SKIPPED+=("$pkg")
        return 0
    fi
    if brew list --formula "$pkg" &>/dev/null 2>&1; then
        info "$pkg already installed"
        INSTALLED+=("$pkg (existing)")
        return 0
    fi
    step "Installing $pkg..."
    if brew install "$pkg" 2>&1 | tee -a "$LOG_FILE" | tail -1; then
        INSTALLED+=("$pkg")
        progress_tick
    else
        FAILED+=("$pkg")
        if $SKIP_FAILED; then
            warn "Failed to install $pkg — skipping"
            return 0
        else
            error "Failed to install $pkg (use --skip-failed to continue)"
            return 1
        fi
    fi
}

brew_cask_install() {
    local pkg="$1"
    if $DRY_RUN; then
        dry "brew install --cask $pkg"
        SKIPPED+=("$pkg (cask)")
        return 0
    fi
    if brew list --cask "$pkg" &>/dev/null 2>&1; then
        info "$pkg (cask) already installed"
        INSTALLED+=("$pkg (cask, existing)")
        return 0
    fi
    step "Installing $pkg (cask)..."
    if brew install --cask "$pkg" 2>&1 | tee -a "$LOG_FILE" | tail -1; then
        INSTALLED+=("$pkg (cask)")
        progress_tick
    else
        FAILED+=("$pkg (cask)")
        if $SKIP_FAILED; then
            warn "Failed to install $pkg (cask) — skipping"
            return 0
        else
            error "Failed to install $pkg (cask)"
            return 1
        fi
    fi
}

pip_install() {
    local pkg="$1"
    if $DRY_RUN; then
        dry "pip3 install $pkg"
        SKIPPED+=("$pkg (pip)")
        return 0
    fi
    if pip3 show "$pkg" &>/dev/null 2>&1; then
        info "$pkg (pip) already installed"
        INSTALLED+=("$pkg (pip, existing)")
        return 0
    fi
    step "Installing Python: $pkg..."
    if pip3 install --user "$pkg" 2>&1 | tee -a "$LOG_FILE" | tail -1; then
        INSTALLED+=("$pkg (pip)")
        progress_tick
    else
        FAILED+=("$pkg (pip)")
        if $SKIP_FAILED; then
            warn "Failed to install $pkg (pip) — skipping"
            return 0
        else
            error "Failed to install $pkg (pip)"
            return 1
        fi
    fi
}

run_or_dry() {
    local desc="$1"; shift
    if $DRY_RUN; then
        dry "$desc"
        return 0
    fi
    step "$desc"
    "$@"
}

# ── Banner ──────────────────────────────────────────────────────────────────
banner() {
    printf "${BOLD}${R}"
    cat <<'BANNER'
  ┳┳┓┏┓┏┓  ┏┓┏┓┏┓
   ┃┃┣┫┣   ┃┃┫ ┣
  ┗┛┗┛┗┛  ┣┛┗┛┗┛
  ┏┓┏┓┏┓┏┓┏┓   Mac Hacker Toolkit
  ┃╋┫ ┫┣┫┣┫    Installer v1.0
  ┛┗┛┗┛┗┛┗┛    
BANNER
    printf "${RESET}"
    printf "${D}  https://github.com/mac-hacker-toolkit${RESET}\n\n"
}

# ── Pre-flight checks ───────────────────────────────────────────────────────
check_macos() {
    header "Pre-flight Checks"
    
    if [[ "$(uname)" != "Darwin" ]]; then
        error "This toolkit requires macOS. Detected: $(uname)"
        exit 1
    fi
    info "Platform: macOS"

    local macos_ver
    macos_ver="$(sw_vers -productVersion)"
    if ! ver_lte "$MIN_MACOS_VERSION" "$macos_ver"; then
        error "macOS $MIN_MACOS_VERSION+ required. Detected: $macos_ver"
        exit 1
    fi
    info "macOS version: $macos_ver ✓"

    local arch
    arch="$(uname -m)"
    case "$arch" in
        arm64) info "Architecture: Apple Silicon ($arch)" ;;
        x86_64) warn "Architecture: Intel ($arch) — some tools may be slower or unavailable" ;;
        *) error "Unknown architecture: $arch"; exit 1 ;;
    esac

    if [[ "$(id -u)" -eq 0 ]]; then
        error "Do not run this script as root / with sudo"
        exit 1
    fi
    info "Running as: $(whoami) ✓"

    if xcode-select -p &>/dev/null; then
        info "Xcode CLI tools: installed ✓"
    else
        step "Installing Xcode CLI tools..."
        if $DRY_RUN; then
            dry "xcode-select --install"
        else
            xcode-select --install 2>&1 || true
            warn "You may need to re-run this script after Xcode CLI tools finish installing"
        fi
    fi

    info "Disk space available: $(df -h / | awk 'NR==2{print $4}')"
}

# ── Homebrew ────────────────────────────────────────────────────────────────
install_homebrew() {
    header "Homebrew"

    if cmd_exists brew; then
        info "Homebrew already installed ✓"
        if ! $DRY_RUN; then
            step "Updating Homebrew..."
            brew update 2>&1 | tee -a "$LOG_FILE" | tail -3
        else
            dry "brew update"
        fi
        return
    fi

    run_or_dry "Installing Homebrew..." bash -c \
        '$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)'

    if [[ "$(uname -m)" == "arm64" && ! -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        grep -q '/opt/homebrew/bin' "$HOME/.zprofile" 2>/dev/null || \
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    elif [[ "$(uname -m)" == "x86_64" && ! -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if cmd_exists brew; then
        info "Homebrew installed successfully ✓"
    elif ! $DRY_RUN; then
        error "Homebrew installation failed"
        $SKIP_FAILED && return 0 || exit 1
    fi
}

# ── Brew tap setup ──────────────────────────────────────────────────────────
setup_taps() {
    header "Homebrew Taps"
    local taps=("homebrew/cask" "homebrew/services")
    for tap in "${taps[@]}"; do
        if $DRY_RUN; then
            dry "brew tap $tap"
        else
            brew tap "$tap" 2>&1 | tee -a "$LOG_FILE" || true
        fi
    done
    info "Taps configured ✓"
}

# ── Category installs ───────────────────────────────────────────────────────
install_category() {
    local cat="$1"
    local tools="${TOOL_CATEGORIES[$cat]:-}"

    if [[ -z "$tools" ]]; then
        warn "Unknown category: $cat"
        return
    fi

    header "Installing: $cat"

    local count
    count=$(echo "$tools" | wc -w | tr -d ' ')
    progress_start "$count"

    # Some tools need cask, default to formula
    local cask_re="(wireshark|ghidra|gqrx|cutter)"

    for pkg in $tools; do
        if [[ "$pkg" =~ $cask_re ]]; then
            brew_cask_install "$pkg"
        elif [[ "$pkg" == "wordlists" ]]; then
            brew_install "cracklib-words" 2>/dev/null || true
            install_rockyou
        else
            brew_install "$pkg"
        fi
    done
}

install_rockyou() {
    local rockyou_dir="$SUPPORT_DIR/wordlists"
    local rockyou="$rockyou_dir/rockyou.txt"

    if $DRY_RUN; then
        dry "Download rockyou.txt → $rockyou"
        return
    fi

    if [[ -f "$rockyou" ]]; then
        info "rockyou.txt already present ✓"
        return
    fi

    step "Downloading rockyou.txt..."
    mkdir -p "$rockyou_dir"
    if curl -fsSL -o "$rockyou.gz" \
        "https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt.gz" 2>&1 | tee -a "$LOG_FILE"; then
        gunzip -f "$rockyou.gz" 2>/dev/null || true
        info "rockyou.txt downloaded ($(du -h "$rockyou" | cut -f1)) ✓"
        INSTALLED+=("rockyou.txt")
    else
        FAILED+=("rockyou.txt")
        warn "Failed to download rockyou.txt — you can manually place it at $rockyou"
    fi
}

# ── Python deps ─────────────────────────────────────────────────────────────
install_python_deps() {
    header "Python Dependencies"

    if ! cmd_exists python3; then
        error "python3 not found — install Xcode CLI tools first"
        $SKIP_FAILED && return 0 || return 1
    fi

    info "Python: $(python3 --version 2>&1)"
    info "pip3: $(pip3 --version 2>&1 | head -1)"

    local count
    count=$(echo "$PYTHON_DEPS" | wc -w | tr -d ' ')
    progress_start "$count"

    for pkg in $PYTHON_DEPS; do
        pip_install "$pkg"
    done
}

# ── Ollama / AI ─────────────────────────────────────────────────────────────
setup_ollama() {
    header "Ollama & LLM Models"

    if $DRY_RUN; then
        dry "brew install ollama"
        dry "ollama serve (background)"
        for model in mistral llama3 phi; do
            dry "ollama pull $model"
        done
        return
    fi

    brew_install "ollama"

    if ! cmd_exists ollama; then
        warn "ollama not available after install — skipping model pull"
        FAILED+=("ollama-models")
        return
    fi

    step "Starting Ollama service..."
    if ! pgrep -f "ollama serve" &>/dev/null; then
        ollama serve &>/dev/null &
        local ollama_pid=$!
        sleep 3
        if ! kill -0 "$ollama_pid" 2>/dev/null; then
            warn "Ollama service failed to start"
        fi
    else
        info "Ollama service already running ✓"
    fi

    local models=("mistral" "llama3" "phi")
    progress_start "${#models[@]}"

    for model in "${models[@]}"; do
        step "Pulling model: $model..."
        if ollama pull "$model" 2>&1 | tee -a "$LOG_FILE"; then
            info "Model $model ready ✓"
            INSTALLED+=("ollama/$model")
            progress_tick
        else
            FAILED+=("ollama/$model")
            if $SKIP_FAILED; then
                warn "Failed to pull $model — skipping"
            else
                error "Failed to pull $model"
                return 1
            fi
        fi
    done
}

# ── Directory structure ─────────────────────────────────────────────────────
create_dirs() {
    header "Application Support Directories"

    local dirs=(
        "$SUPPORT_DIR"
        "$SUPPORT_DIR/wordlists"
        "$SUPPORT_DIR/captures"
        "$SUPPORT_DIR/scans"
        "$SUPPORT_DIR/reports"
        "$SUPPORT_DIR/logs"
        "$SUPPORT_DIR/plugins"
        "$SUPPORT_DIR/config"
        "$SUPPORT_DIR/tmp"
        "$TOOLKIT_ROOT/tools"
    )

    for d in "${dirs[@]}"; do
        if $DRY_RUN; then
            dry "mkdir -p $d"
        else
            mkdir -p "$d"
        fi
    done

    if ! $DRY_RUN; then
        info "Directories created ✓"
    fi
}

# ── Permissions ─────────────────────────────────────────────────────────────
set_permissions() {
    header "Permissions"

    local bin_dirs=()
    if [[ -d "$TOOLKIT_ROOT/tools" ]]; then bin_dirs+=("$TOOLKIT_ROOT/tools"); fi
    if [[ -d "$TOOLKIT_ROOT/scripts" ]]; then bin_dirs+=("$TOOLKIT_ROOT/scripts"); fi

    for d in "${bin_dirs[@]}"; do
        if $DRY_RUN; then
            dry "chmod +x $d/*.sh"
        else
            find "$d" -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
        fi
    done

    if ! $DRY_RUN; then
        chmod 700 "$SUPPORT_DIR" 2>/dev/null || true
        chmod 700 "$SUPPORT_DIR/config" 2>/dev/null || true
        info "Permissions set ✓"
    fi
}

# ── Verification ────────────────────────────────────────────────────────────
verify_installations() {
    header "Verification"

    local all_tools=()
    for cat in "${!TOOL_CATEGORIES[@]}"; do
        for pkg in ${TOOL_CATEGORIES[$cat]}; do
            [[ "$pkg" == "wordlists" ]] && continue
            all_tools+=("$pkg")
        done
    done

    local ok=0 missing=0
    for tool in "${all_tools[@]}"; do
        if cmd_exists "$tool" || brew list --formula "$tool" &>/dev/null 2>&1; then
            ((ok++)) || true
        else
            ((missing++)) || true
            warn "Not found: $tool"
        fi
    done

    printf "\n${BOLD}Verification Summary${RESET}\n"
    printf "  ${G}Found:${RESET}     %d\n" "$ok"
    printf "  ${R}Missing:${RESET}   %d\n" "$missing"

    for pkg in $PYTHON_DEPS; do
        if pip3 show "$pkg" &>/dev/null 2>&1; then
            ((ok++)) || true
        else
            ((missing++)) || true
            warn "Python package not found: $pkg"
        fi
    done
}

# ── Report ──────────────────────────────────────────────────────────────────
generate_report() {
    header "Installation Report"

    local report="$SUPPORT_DIR/install_report.txt"

    {
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║            Mac Hacker Toolkit — Installation Report         ║"
        echo "╠══════════════════════════════════════════════════════════════╣"
        echo "║  Date:        $(date)                                       "
        echo "║  macOS:       $(sw_vers -productVersion)                                              "
        echo "║  Architecture:$(uname -m)                                              "
        echo "║  Category:    $CATEGORY                                              "
        echo "║  Dry Run:     $DRY_RUN                                              "
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo ""
        echo "── INSTALLED (${#INSTALLED[@]}) ──────────────────────────────────────"
        for item in "${INSTALLED[@]}"; do echo "  ✓ $item"; done
        echo ""
        echo "── FAILED (${#FAILED[@]}) ──────────────────────────────────────────"
        for item in "${FAILED[@]}"; do echo "  ✗ $item"; done
        echo ""
        echo "── SKIPPED (dry-run) (${#SKIPPED[@]}) ────────────────────────────"
        for item in "${SKIPPED[@]}"; do echo "  ◌ $item"; done
        echo ""
        echo "── LOG ────────────────────────────────────────────────────────"
        echo "  $LOG_FILE"
        echo ""
        if [[ ${#FAILED[@]} -eq 0 ]]; then
            echo "  Status: ✓ ALL GOOD"
        else
            echo "  Status: ⚠ SOME FAILURES — review log"
        fi
    } | tee "$report"

    printf "\n${D}Report saved: $report${RESET}\n"
}

# ── Main ────────────────────────────────────────────────────────────────────
main() {
    banner

    mkdir -p "$SUPPORT_DIR/logs"

    $DRY_RUN && printf "${M}${BOLD}  ⚡ DRY RUN MODE — no changes will be made${RESET}\n\n"

    check_macos
    install_homebrew
    setup_taps

    if [[ "$CATEGORY" == "all" ]]; then
        for cat in recon network wireless cracking exploit forensics reverse sdr web wordlists ai; do
            install_category "$cat"
        done
        install_python_deps
    elif [[ "$CATEGORY" == "python" ]]; then
        install_python_deps
    elif [[ "$CATEGORY" == "ai" ]]; then
        install_category "ai"
        setup_ollama
    else
        install_category "$CATEGORY"
    fi

    if [[ "$CATEGORY" == "all" || "$CATEGORY" == "ai" ]]; then
        setup_ollama
    fi

    create_dirs
    set_permissions

    if ! $DRY_RUN; then
        verify_installations
    fi

    generate_report

    printf "\n${G}${BOLD}  Done! Happy hacking.${RESET}\n\n"
}

main "$@"
