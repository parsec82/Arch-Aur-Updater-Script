LOG_FILE="$HOME/aur-update.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Funzione notifica desktop (se notify-send disponibile)
notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$1" "$2"
    fi
}


# Parsing flag --check, --all, --help/-h
CHECK_ONLY=0
ALL_UPDATE=0
SHOW_HELP=0
for arg in "$@"; do
        if [[ "$arg" == "--check" ]]; then
                CHECK_ONLY=1
        fi
        if [[ "$arg" == "--all" ]]; then
                ALL_UPDATE=1
        fi
        if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
                SHOW_HELP=1
        fi
done

if [ "$SHOW_HELP" = "1" ]; then
    cat <<EOF
AUR package update script without yay/paru (v$SCRIPT_VERSION)
-------------------------------------------------------------
USAGE:
    ./update-aur.sh [--check] [--all] [--help]

OPTIONS:
    --check     Show only the status of AUR packages (upgradable, orphaned, out-of-date, removed, missing dependencies) without update prompt.
    --all       Update all upgradable AUR packages without interactive prompt.
    --help, -h  Show this help and exit.

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
    ./update-aur.sh --check
    ./update-aur.sh --all
    ./update-aur.sh
EOF
    exit 0
fi

#!/bin/bash
# Script per controllare e aggiornare pacchetti AUR senza yay/paru
# Richiede: curl, jq, git, makepkg, pacman

# === VERSIONE SCRIPT ===
SCRIPT_VERSION="3.1"

# Controllo aggiornamenti script da GitHub
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

# Controllo dipendenze

for dep in curl jq git makepkg pacman; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "Errore: il comando '$dep' non è installato."
        log "ERRORE: dipendenza mancante: $dep"
        notify "AUR Updater" "Errore: dipendenza mancante: $dep"
        exit 1
    fi
done


# Non eseguire come root

if [ "$EUID" -eq 0 ]; then
    echo "Non eseguire questo script come root. Usa un utente normale."
    log "ERRORE: esecuzione come root bloccata."
    notify "AUR Updater" "Errore: esecuzione come root bloccata."
    exit 1
fi





# Carica lista pacchetti da ignorare da ~/.aurignore (uno per riga, commenti e righe vuote ignorate)
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
    echo "Nessun pacchetto AUR installato (esclusi i pacchetti debug)."
    log "Nessun pacchetto AUR installato (esclusi debug)."
    notify "AUR Updater" "Nessun pacchetto AUR installato (esclusi debug)."
    exit 0
fi

# Recupera le versioni installate
INSTALLED_VERSIONS=()
PKG_ARGS=""
for pkg in "${AUR_PKGS[@]}"; do
    ver=$(pacman -Q $pkg | awk '{print $2}')
    INSTALLED_VERSIONS+=("$ver")
    PKG_ARGS+="&arg[]=$pkg"
done

# Interroga l'AUR API per le versioni disponibili
AUR_API_URL="https://aur.archlinux.org/rpc/?v=5&type=info${PKG_ARGS}"

AUR_INFO=$(curl -fsSL "$AUR_API_URL") || {
    echo "Errore di rete: impossibile contattare l'AUR."
    log "ERRORE: impossibile contattare l'AUR."
    notify "AUR Updater" "Errore di rete: impossibile contattare l'AUR."
    exit 2
}


# Confronta le versioni e costruisci le liste
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
        REMOVED_LIST+=("$pkg ($inst_ver) - RIMOSSO DA AUR")
    else
        if [ "$aur_ver" != "$inst_ver" ]; then
            UPGRADE_LIST+=("$pkg ($inst_ver -> $aur_ver)")
            UPGRADE_NAMES+=("$pkg")
        fi
        if [ "$maintainer" == "null" ]; then
            ORPHAN_LIST+=("$pkg ($inst_ver) - ORFANO (Maintainer: None)")
        fi
        if [ "$outofdate" != "null" ] && [ "$outofdate" != "0" ]; then
            OUTOFDATE_LIST+=("$pkg ($inst_ver) - FLAGGATO OUT-OF-DATE")
        fi
        # Controllo dipendenze AUR mancanti
        depends=$(echo "$pkg_info" | jq -r '.Depends[]?' | grep -v ":" || true)
        for dep in $depends; do
            if ! pacman -Qq "$dep" &>/dev/null; then
                # Se la dipendenza non è installata e non è nei repo ufficiali
                if ! pacman -Si "$dep" &>/dev/null; then
                    MISSING_AUR_DEPS+=("$dep (richiesto da $pkg)")
                fi
            fi
        done
    fi
done



# Se non ci sono aggiornamenti, ma ci sono orfani/out-of-date/rimossi, mostra comunque le segnalazioni



if [ ${#UPGRADE_LIST[@]} -eq 0 ]; then
    if [ ${#REMOVED_LIST[@]} -gt 0 ]; then
        echo -e "\033[1;33m⚠️  Attenzione: alcuni pacchetti risultano rimossi dall'AUR:\033[0m"
        for r in "${REMOVED_LIST[@]}"; do
            echo -e "  🟡 $r"
            log "RIMOSSO: $r"
        done
        echo ""
    fi
    if [ ${#ORPHAN_LIST[@]} -gt 0 ]; then
        echo -e "\033[1;35m⚠️  Attenzione: pacchetti orfani (Maintainer: None):\033[0m"
        for o in "${ORPHAN_LIST[@]}"; do
            echo -e "  🟣 $o"
            log "ORFANO: $o"
        done
        echo ""
    fi
    if [ ${#OUTOFDATE_LIST[@]} -gt 0 ]; then
        echo -e "\033[1;31m⚠️  Attenzione: pacchetti flaggati come OUT-OF-DATE:\033[0m"
        for o in "${OUTOFDATE_LIST[@]}"; do
            echo -e "  🔴 $o"
            log "OUT-OF-DATE: $o"
        done
        echo ""
    fi
    if [ ${#MISSING_AUR_DEPS[@]} -gt 0 ]; then
        echo -e "\033[1;33m⚠️  Attenzione: dipendenze AUR mancanti:\033[0m"
        for d in "${MISSING_AUR_DEPS[@]}"; do
            echo -e "  ⚫ $d"
            log "DIPENDENZA AUR MANCANTE: $d"
        done
        echo ""
    fi
    log "Tutti i pacchetti AUR aggiornati."
    echo -e "\033[1;32m✅ Tutti i pacchetti AUR sono aggiornati.\033[0m"
    notify "AUR Updater" "Tutti i pacchetti AUR sono aggiornati."
    exit 0
fi

# Se richiesto solo check, mostra stato e termina
if [ "$CHECK_ONLY" = "1" ]; then
    notify "AUR Updater" "Check completato: nessun aggiornamento eseguito."
    exit 0
fi

echo ""

# 5. Mostra la lista e chiedi cosa aggiornare

if [ ${#UPGRADE_LIST[@]} -gt 0 ]; then
    echo -e "\033[1;36m⬆️  Pacchetti AUR aggiornabili:\033[0m"
    for i in "${!UPGRADE_LIST[@]}"; do
        echo -e "  $((i+1)). ${UPGRADE_LIST[$i]}"
        log "AGGIORNABILE: ${UPGRADE_LIST[$i]}"
    done
    echo ""
fi

if [ ${#REMOVED_LIST[@]} -gt 0 ]; then
    echo -e "\033[1;33m⚠️  Attenzione: alcuni pacchetti risultano rimossi dall'AUR:\033[0m"
    for r in "${REMOVED_LIST[@]}"; do
        echo -e "  🟡 $r"
    done
    echo ""
fi
if [ ${#ORPHAN_LIST[@]} -gt 0 ]; then
    echo -e "\033[1;35m⚠️  Attenzione: pacchetti orfani (Maintainer: None):\033[0m"
    for o in "${ORPHAN_LIST[@]}"; do
        echo -e "  🟣 $o"
    done
    echo ""
fi
if [ ${#OUTOFDATE_LIST[@]} -gt 0 ]; then
    echo -e "\033[1;31m⚠️  Attenzione: pacchetti flaggati come OUT-OF-DATE:\033[0m"
    for o in "${OUTOFDATE_LIST[@]}"; do
        echo -e "  🔴 $o"
    done
    echo ""
fi
if [ ${#MISSING_AUR_DEPS[@]} -gt 0 ]; then
    echo -e "\033[1;33m⚠️  Attenzione: dipendenze AUR mancanti:\033[0m"
    for d in "${MISSING_AUR_DEPS[@]}"; do
        echo -e "  ⚫ $d"
    done
    echo ""
fi


if [ "$ALL_UPDATE" = "1" ]; then
    TO_UPDATE=("${UPGRADE_NAMES[@]}")
    echo "Aggiornamento di tutti i pacchetti senza prompt (--all)."
else
    echo "Vuoi aggiornare tutti i pacchetti? (s/N)"
    read -r ALL
    if [[ "$ALL" =~ ^[sS]$ ]]; then
        TO_UPDATE=("${UPGRADE_NAMES[@]}")
    else
        echo "Inserisci i numeri dei pacchetti da aggiornare separati da spazio (es: 1 3 5):"
        read -r SELECTION
        TO_UPDATE=()
        for idx in $SELECTION; do
            if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le ${#UPGRADE_NAMES[@]} ]; then
                idx0=$((idx-1))
                TO_UPDATE+=("${UPGRADE_NAMES[$idx0]}")
            else
                echo "Valore non valido: $idx. Ignorato."
            fi
        done
        if [ ${#TO_UPDATE[@]} -eq 0 ]; then
            echo "Nessun pacchetto selezionato. Uscita."
            exit 0
        fi
    fi
fi


# 6. Pulizia automatica delle directory di build non più usate
BUILD_DIR="$HOME/aurbuild"
mkdir -p "$BUILD_DIR"
# Rimuovi directory di pacchetti non più installati
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
        echo -e "\033[0;33mPulizia: rimozione directory build obsoleta $dname\033[0m"
        log "PULIZIA: rimossa directory build obsoleta $dname"
        rm -rf "$dir"
    fi
done


for pkg in "${TO_UPDATE[@]}"; do
    echo -e "\n\033[1;34mAggiornamento di $pkg...\033[0m"
    log "INIZIO aggiornamento di $pkg"
    cd "$BUILD_DIR"
    if [ -d "$pkg" ]; then
        cd "$pkg" && git pull || { echo "Impossibile aggiornare repo $pkg"; log "ERRORE: git pull fallito per $pkg"; continue; }
    else
        git clone "https://aur.archlinux.org/$pkg.git" || { echo "Clonazione fallita per $pkg"; log "ERRORE: clonazione fallita per $pkg"; continue; }
        cd "$pkg"
    fi
    # makepkg va eseguito come utente normale, pacman chiederà sudo se necessario
    if makepkg -si --noconfirm; then
        log "SUCCESSO: $pkg aggiornato e installato."
        cd "$BUILD_DIR"
        rm -rf "$pkg"
    else
        echo "Errore durante la compilazione/installazione di $pkg."
        log "ERRORE: makepkg/install fallito per $pkg"
        cd "$BUILD_DIR"
    fi
done

log "Aggiornamento completato."
notify "AUR Updater" "Aggiornamento completato."
echo -e "\n\033[1;32mAggiornamento completato.\033[0m"
