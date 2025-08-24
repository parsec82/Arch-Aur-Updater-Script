LOG_FILE="$HOME/aur-update.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Desktop notification function (if notify-send available)
notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$1" "$2"
    fi
}



# Parsing flag lunghi e brevi
CHECK_ONLY=0
ALL_UPDATE=0
SHOW_HELP=0
NO_COLOR=0
COMPACT=0
FULL=0
INSTALL_MODE=0
REMOVE_MODE=0
INSTALL_PKGS=()
REMOVE_PKGS=()
ARGS=("$@")
i=0
while [ $i -lt $# ]; do
    arg="${ARGS[$i]}"
    case "$arg" in
        --check|-c)
            CHECK_ONLY=1
            ;;
        --all|-a)
            ALL_UPDATE=1
            ;;
        --help|-h)
            SHOW_HELP=1
            ;;
        --no-color|-n)
            NO_COLOR=1
            ;;
        --compact|-C)
            COMPACT=1
            ;;
        --full|-F)
            FULL=1
            ;;
        --install|-i)
            INSTALL_MODE=1
            # Prendi tutti gli argomenti successivi che non iniziano con -
            j=$((i+1))
            while [ $j -lt $# ]; do
                next="${ARGS[$j]}"
                if [[ "$next" == --* || "$next" == -* ]]; then
                    break
                fi
                INSTALL_PKGS+=("$next")
                j=$((j+1))
            done
            i=$((j-1))
            ;;
        --remove|-r)
            REMOVE_MODE=1
            # Prendi tutti gli argomenti successivi che non iniziano con -
            j=$((i+1))
            while [ $j -lt $# ]; do
                next="${ARGS[$j]}"
                if [[ "$next" == --* || "$next" == -* ]]; then
                    break
                fi
                REMOVE_PKGS+=("$next")
                j=$((j+1))
            done
            i=$((j-1))
            ;;
    esac
    i=$((i+1))
done


if [ "$SHOW_HELP" = "1" ]; then
    cat <<EOF
AUR package update script without yay/paru (v$SCRIPT_VERSION)
-------------------------------------------------------------
USAGE:
    ./update-aur.sh [--check] [--all] [--no-color] [--compact|--full] [--install <pkg1> [<pkg2> ...]] [--remove <pkg1> [<pkg2> ...]] [--help]

OPTIONS:
    --check      Show only the status of AUR packages (upgradable, orphaned, out-of-date, removed, missing dependencies) without update prompt.
    --all        Update all upgradable AUR packages without interactive prompt.
    --no-color   Disable colored output.
    --compact    Compact output (one line per package, minimal info).
    --full       Full output (detailed info, default).
    --install    Install one or more AUR packages (space separated).
    --remove     Remove one or more AUR packages (space separated).
    --help, -h   Show this help and exit.

FEATURES:
    - Ignores *debug* packages and those listed in ~/.aurignore
    - Reports orphaned, out-of-date, removed packages, missing AUR dependencies
    - Detailed log in ~/aur-update.log
    - Desktop notifications (notify-send)
    - Automatic cleanup of obsolete build directories
    - Script version check from GitHub

FILE ~/.aurignore:
    List (one per line) AUR packages to exclude from checks/updates.

EXAMPLES:
    ./update-aur.sh --check --compact
    ./update-aur.sh --all --no-color
    ./update-aur.sh --install google-chrome visual-studio-code-bin
    ./update-aur.sh --remove google-chrome visual-studio-code-bin
EOF
    exit 0
fi
# Remove mode: uninstall AUR packages
if [ "$REMOVE_MODE" = "1" ]; then
    if [ ${#REMOVE_PKGS[@]} -eq 0 ]; then
        echo "No package specified for removal."
        exit 1
    fi
    for pkg in "${REMOVE_PKGS[@]}"; do
        if ! pacman -Qq "$pkg" &>/dev/null; then
            echo "Package $pkg is not installed. Skipping."
            log "REMOVE: $pkg not installed."
            continue
        fi
        echo -e "${BOLD}Removing $pkg...${NC}"
        log "REMOVE: start $pkg"
        if sudo pacman -Rns --noconfirm "$pkg"; then
            log "REMOVE: $pkg removed successfully."
            echo "Package $pkg removed successfully."
        else
            echo "Error removing $pkg."
            log "ERROR: failed to remove $pkg"
        fi
    done
    notify "AUR Updater" "AUR package removal completed."
    echo -e "${GREEN}AUR package removal completed.${NC}"
    exit 0
fi
# Install mode: install new AUR packages
if [ "$INSTALL_MODE" = "1" ]; then
    if [ ${#INSTALL_PKGS[@]} -eq 0 ]; then
        echo "No package specified for installation."
        exit 1
    fi
    BUILD_DIR="$HOME/aurbuild"
    mkdir -p "$BUILD_DIR"
    for pkg in "${INSTALL_PKGS[@]}"; do
        if pacman -Qq "$pkg" &>/dev/null; then
            echo "Package $pkg is already installed. Skipping."
            log "INSTALL: $pkg already installed."
            continue
        fi
        echo -e "${BOLD}Installing $pkg from AUR...${NC}"
        log "INSTALL: start $pkg"
        cd "$BUILD_DIR"
        if [ -d "$pkg" ]; then
            cd "$pkg" && git pull || { echo "Unable to update repo $pkg"; log "ERROR: git pull failed for $pkg"; continue; }
        else
            git clone "https://aur.archlinux.org/$pkg.git" || { echo "Clone failed for $pkg"; log "ERROR: clone failed for $pkg"; continue; }
            cd "$pkg"
        fi
        if makepkg -si --noconfirm; then
            log "INSTALL: $pkg installed successfully."
            cd "$BUILD_DIR"
            rm -rf "$pkg"
            echo "Package $pkg installed successfully."
        else
            echo "Error during build/install of $pkg."
            log "ERROR: makepkg/install failed for $pkg"
            cd "$BUILD_DIR"
        fi
    done
    notify "AUR Updater" "AUR package installation completed."
    echo -e "${GREEN}AUR package installation completed.${NC}"
    exit 0
fi

#!/bin/bash
# Script to check and update AUR packages without yay/paru
# Requires: curl, jq, git, makepkg, pacman


# === VERSIONE SCRIPT ===
SCRIPT_VERSION="3.5"

# Script update check from GitHub
GITHUB_REPO="parsec82/Arch-Aur-Updater-Script"
GITHUB_API="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
LATEST_VERSION=""
if command -v curl >/dev/null 2>&1; then
    GITHUB_JSON=$(curl -fsSL "$GITHUB_API" 2>/dev/null || true)
    if [ -n "$GITHUB_JSON" ]; then
        LATEST_VERSION=$(echo "$GITHUB_JSON" | jq -r .tag_name 2>/dev/null | sed 's/^v//')
        if [ -n "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "null" ] && [ "$LATEST_VERSION" != "$SCRIPT_VERSION" ]; then
            echo -e "\033[1;33m\n⚠️  È disponibile una nuova versione dello script: $LATEST_VERSION (tu stai usando $SCRIPT_VERSION)\033[0m"
            notify "AUR Updater" "Nuova versione script disponibile: $LATEST_VERSION (tu: $SCRIPT_VERSION)"
        fi
    fi
fi



set -e

# Colors (can be disabled)
if [ "$NO_COLOR" = "1" ]; then
    NC=""; BOLD=""; YELLOW=""; RED=""; GREEN=""; CYAN=""; MAGENTA="";
else
    NC="\033[0m"; BOLD="\033[1m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; GREEN="\033[1;32m"; CYAN="\033[1;36m"; MAGENTA="\033[1;35m";
fi


# Pacman lock file check
if [ -f /var/lib/pacman/db.lck ]; then
    echo "${RED}Error: pacman is currently in use (lock file present: /var/lib/pacman/db.lck). Please try again later.${NC}"
    log "ERROR: pacman lock file present."
    notify "AUR Updater" "Error: pacman lock file present."
    exit 1
fi

# Dependency check
for dep in curl jq git makepkg pacman; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "Error: command '$dep' is not installed."
        log "ERROR: missing dependency: $dep"
        notify "AUR Updater" "Error: missing dependency: $dep"
        exit 1
    fi
done


# Do not run as root
if [ "$EUID" -eq 0 ]; then
    echo "Do not run this script as root. Use a normal user."
    log "ERROR: running as root is blocked."
    notify "AUR Updater" "Error: running as root is blocked."
    exit 1
fi





# Load ignore list from ~/.aurignore (one per line, ignores comments and empty lines)
IGNORE_LIST=()
if [ -f "$HOME/.aurignore" ]; then
    while IFS= read -r line; do
        line="${line%%#*}" # rimuovi commenti
        line="${line// /}" # rimuovi spazi
        [ -n "$line" ] && IGNORE_LIST+=("$line")
    done < "$HOME/.aurignore"
fi

AUR_PKGS=()
for pkg in $(pacman -Qm | awk '{print $1}'); do
    skip=0
    if [[ "$pkg" == *debug* ]]; then
        skip=1
    fi
    for ign in "${IGNORE_LIST[@]}"; do
        if [[ "$pkg" == "$ign" ]]; then
            skip=1
            break
        fi
    done
    if [ $skip -eq 0 ]; then
        AUR_PKGS+=("$pkg")
    fi
done


if [ ${#AUR_PKGS[@]} -eq 0 ]; then
    echo "No AUR packages installed (excluding debug packages)."
    log "No AUR packages installed (excluding debug)."
    notify "AUR Updater" "No AUR packages installed (excluding debug)."
    exit 0
fi

# Get installed versions
INSTALLED_VERSIONS=()
PKG_ARGS=""
for pkg in "${AUR_PKGS[@]}"; do
    ver=$(pacman -Q $pkg | awk '{print $2}')
    INSTALLED_VERSIONS+=("$ver")
    PKG_ARGS+="&arg[]=$pkg"
done

# Query AUR API for available versions
AUR_API_URL="https://aur.archlinux.org/rpc/?v=5&type=info${PKG_ARGS}"

AUR_INFO=$(curl -fsSL "$AUR_API_URL") || {
    echo "Network error: unable to contact AUR."
    log "ERROR: unable to contact AUR."
    notify "AUR Updater" "Network error: unable to contact AUR."
    exit 2
}


# Compare versions and build lists
UPGRADE_LIST=()
UPGRADE_NAMES=()
REMOVED_LIST=()
ORPHAN_LIST=()
OUTOFDATE_LIST=()
MISSING_AUR_DEPS=()
for i in "${!AUR_PKGS[@]}"; do
    pkg="${AUR_PKGS[$i]}"
    inst_ver="${INSTALLED_VERSIONS[$i]}"
    pkg_info=$(echo "$AUR_INFO" | jq ".results[] | select(.Name==\"$pkg\")")
    aur_ver=$(echo "$pkg_info" | jq -r ".Version")
    maintainer=$(echo "$pkg_info" | jq -r ".Maintainer")
    outofdate=$(echo "$pkg_info" | jq -r ".OutOfDate")
    if [ "$aur_ver" == "null" ]; then
    REMOVED_LIST+=("$pkg ($inst_ver) - REMOVED FROM AUR")
    else
        if [ "$aur_ver" != "$inst_ver" ]; then
            UPGRADE_LIST+=("$pkg ($inst_ver -> $aur_ver)")
            UPGRADE_NAMES+=("$pkg")
        fi
        if [ "$maintainer" == "null" ]; then
            ORPHAN_LIST+=("$pkg ($inst_ver) - ORPHAN (Maintainer: None)")
        fi
        if [ "$outofdate" != "null" ] && [ "$outofdate" != "0" ]; then
            OUTOFDATE_LIST+=("$pkg ($inst_ver) - FLAGGED OUT-OF-DATE")
        fi
        # Check for missing AUR dependencies
        depends=$(echo "$pkg_info" | jq -r '.Depends[]?' | grep -v ":" || true)
        for dep in $depends; do
            if ! pacman -Qq "$dep" &>/dev/null; then
                # If dependency is not installed and not in official repos
                if ! pacman -Si "$dep" &>/dev/null; then
                    MISSING_AUR_DEPS+=("$dep (required by $pkg)")
                fi
            fi
        done
    fi
done



# If there are no updates, but there are orphans/out-of-date/removed, still show warnings





# Compact/full output (for report section only)
compact_echo() {
    # $1: symbol, $2: list
    for item in "${!2}"; do
        echo "$1 $item"
    done
}

if [ ${#UPGRADE_LIST[@]} -eq 0 ]; then
    if [ ${#REMOVED_LIST[@]} -gt 0 ]; then
        if [ "$COMPACT" = "1" ]; then
            for r in "${REMOVED_LIST[@]}"; do echo "REMOVED: $r"; done
        else
            echo -e "${YELLOW}⚠️  Warning: some packages have been removed from AUR:${NC}"
            for r in "${REMOVED_LIST[@]}"; do
                echo -e "  🟡 $r"
                log "REMOVED: $r"
            done
            echo ""
        fi
    fi
    if [ ${#ORPHAN_LIST[@]} -gt 0 ]; then
        if [ "$COMPACT" = "1" ]; then
            for o in "${ORPHAN_LIST[@]}"; do echo "ORPHAN: $o"; done
        else
            echo -e "${MAGENTA}⚠️  Warning: orphan packages (Maintainer: None):${NC}"
            for o in "${ORPHAN_LIST[@]}"; do
                echo -e "  🟣 $o"
                log "ORPHAN: $o"
            done
            echo ""
        fi
    fi
    if [ ${#OUTOFDATE_LIST[@]} -gt 0 ]; then
        if [ "$COMPACT" = "1" ]; then
            for o in "${OUTOFDATE_LIST[@]}"; do echo "OUT-OF-DATE: $o"; done
        else
            echo -e "${RED}⚠️  Warning: packages flagged as OUT-OF-DATE:${NC}"
            for o in "${OUTOFDATE_LIST[@]}"; do
                echo -e "  🔴 $o"
                log "OUT-OF-DATE: $o"
            done
            echo ""
        fi
    fi
    if [ ${#MISSING_AUR_DEPS[@]} -gt 0 ]; then
        if [ "$COMPACT" = "1" ]; then
            for d in "${MISSING_AUR_DEPS[@]}"; do echo "MISSING_DEP: $d"; done
        else
            echo -e "${YELLOW}⚠️  Warning: missing AUR dependencies:${NC}"
            for d in "${MISSING_AUR_DEPS[@]}"; do
                echo -e "  ⚫ $d"
                log "MISSING AUR DEP: $d"
            done
            echo ""
        fi
    fi
    log "All AUR packages are up to date."
    if [ "$COMPACT" = "1" ]; then
        echo "OK: All AUR packages are up to date."
    else
        echo -e "${GREEN}✅ All AUR packages are up to date.${NC}"
    fi
    notify "AUR Updater" "All AUR packages are up to date."
    exit 0
fi

# If only check requested, show status and exit
if [ "$CHECK_ONLY" = "1" ]; then
    notify "AUR Updater" "Check completed: no update performed."
    exit 0
fi

echo ""

# 5. Mostra la lista e chiedi cosa aggiornare



if [ ${#UPGRADE_LIST[@]} -gt 0 ]; then
    if [ "$COMPACT" = "1" ]; then
        for i in "${!UPGRADE_LIST[@]}"; do
            echo "UPGRADE: ${UPGRADE_LIST[$i]}"
            log "AGGIORNABILE: ${UPGRADE_LIST[$i]}"
        done
    else
        echo -e "${CYAN}⬆️  Pacchetti AUR aggiornabili:${NC}"
        for i in "${!UPGRADE_LIST[@]}"; do
            echo -e "  $((i+1)). ${UPGRADE_LIST[$i]}"
            log "AGGIORNABILE: ${UPGRADE_LIST[$i]}"
        done
        echo ""
    fi
fi

if [ "$COMPACT" != "1" ]; then
    if [ ${#REMOVED_LIST[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Attenzione: alcuni pacchetti risultano rimossi dall'AUR:${NC}"
        for r in "${REMOVED_LIST[@]}"; do
            echo -e "  🟡 $r"
        done
        echo ""
    fi
    if [ ${#ORPHAN_LIST[@]} -gt 0 ]; then
        echo -e "${MAGENTA}⚠️  Attenzione: pacchetti orfani (Maintainer: None):${NC}"
        for o in "${ORPHAN_LIST[@]}"; do
            echo -e "  🟣 $o"
        done
        echo ""
    fi
    if [ ${#OUTOFDATE_LIST[@]} -gt 0 ]; then
        echo -e "${RED}⚠️  Attenzione: pacchetti flaggati come OUT-OF-DATE:${NC}"
        for o in "${OUTOFDATE_LIST[@]}"; do
            echo -e "  🔴 $o"
        done
        echo ""
    fi
    if [ ${#MISSING_AUR_DEPS[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Attenzione: dipendenze AUR mancanti:${NC}"
        for d in "${MISSING_AUR_DEPS[@]}"; do
            echo -e "  ⚫ $d"
        done
        echo ""
    fi
fi



if [ "$ALL_UPDATE" = "1" ]; then
    TO_UPDATE=(${UPGRADE_NAMES[@]})
    echo "Updating all packages without prompt (--all)."
else
    echo "Do you want to update all packages? (y/N)"
    read -r ALL
    if [[ "$ALL" =~ ^[yY]$ ]]; then
        TO_UPDATE=(${UPGRADE_NAMES[@]})
    else
        echo "Enter the numbers of the packages to update separated by space (e.g.: 1 3 5):"
        read -r SELECTION
        TO_UPDATE=()
        for idx in $SELECTION; do
            if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le ${#UPGRADE_NAMES[@]} ]; then
                idx0=$((idx-1))
                TO_UPDATE+=("${UPGRADE_NAMES[$idx0]}")
            else
                echo "Invalid value: $idx. Ignored."
            fi
        done
        if [ ${#TO_UPDATE[@]} -eq 0 ]; then
            echo "No package selected. Exiting."
            exit 0
        fi
    fi
fi


# 6. Automatic cleanup of obsolete build directories
BUILD_DIR="$HOME/aurbuild"
mkdir -p "$BUILD_DIR"
# Remove build directories of packages no longer installed
for dir in "$BUILD_DIR"/*; do
    [ -d "$dir" ] || continue
    dname="$(basename "$dir")"
    found=0
    for pkg in "${AUR_PKGS[@]}"; do
        if [ "$dname" = "$pkg" ]; then
            found=1
            break
        fi
    done
    if [ $found -eq 0 ]; then
        echo -e "\033[0;33mCleanup: removing obsolete build directory $dname\033[0m"
        log "CLEANUP: removed obsolete build directory $dname"
        rm -rf "$dir"
    fi
done



for pkg in "${TO_UPDATE[@]}"; do
    echo -e "\n${BOLD}Updating $pkg...${NC}"
    log "START updating $pkg"
    cd "$BUILD_DIR"
    if [ -d "$pkg" ]; then
        cd "$pkg" && git pull || { echo "Unable to update repo $pkg"; log "ERROR: git pull failed for $pkg"; continue; }
    else
        git clone "https://aur.archlinux.org/$pkg.git" || { echo "Clone failed for $pkg"; log "ERROR: clone failed for $pkg"; continue; }
        cd "$pkg"
    fi
    # makepkg must be run as normal user, pacman will ask for sudo if needed
    if makepkg -si --noconfirm; then
        log "SUCCESS: $pkg updated and installed."
        cd "$BUILD_DIR"
        rm -rf "$pkg"
    else
        echo "Error during build/install of $pkg."
        log "ERROR: makepkg/install failed for $pkg"
        cd "$BUILD_DIR"
    fi
done


log "Update completed."
notify "AUR Updater" "Update completed."
echo -e "\n${GREEN}Update completed.${NC}"
