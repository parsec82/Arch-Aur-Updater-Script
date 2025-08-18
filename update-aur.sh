#!/bin/bash
# Script per controllare e aggiornare pacchetti AUR senza yay/paru
# Richiede: curl, jq, git, makepkg, pacman


set -e

# Controllo dipendenze
for dep in curl jq git makepkg pacman; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "Errore: il comando '$dep' non è installato."
        exit 1
    fi
done

# Non eseguire come root
if [ "$EUID" -eq 0 ]; then
    echo "Non eseguire questo script come root. Usa un utente normale."
    exit 1
fi


# 1. Recupera la lista dei pacchetti AUR installati, ignorando quelli con "debug" nel nome
AUR_PKGS=()
for pkg in $(pacman -Qm | awk '{print $1}'); do
    if [[ "$pkg" != *debug* ]]; then
        AUR_PKGS+=("$pkg")
    fi
done
if [ ${#AUR_PKGS[@]} -eq 0 ]; then
    echo "Nessun pacchetto AUR installato (esclusi i pacchetti debug)."
    exit 0
fi

# 2. Recupera le versioni installate
INSTALLED_VERSIONS=()
for pkg in "${AUR_PKGS[@]}"; do
    ver=$(pacman -Q $pkg | awk '{print $2}')
    INSTALLED_VERSIONS+=("$ver")
    PKG_ARGS+="&arg[]=$pkg"
done

# 3. Interroga l'AUR API per le versioni disponibili
AUR_API_URL="https://aur.archlinux.org/rpc/?v=5&type=info${PKG_ARGS}"

# Gestione errori di rete
AUR_INFO=$(curl -fsSL "$AUR_API_URL") || {
    echo "Errore di rete: impossibile contattare l'AUR."
    exit 2
}


# 4. Confronta le versioni e costruisci la lista degli aggiornabili, segnala pacchetti rimossi
UPGRADE_LIST=()
UPGRADE_NAMES=()
REMOVED_LIST=()
for i in "${!AUR_PKGS[@]}"; do
    pkg="${AUR_PKGS[$i]}"
    inst_ver="${INSTALLED_VERSIONS[$i]}"
    aur_ver=$(echo "$AUR_INFO" | jq -r ".results[] | select(.Name==\"$pkg\") | .Version")
    if [ "$aur_ver" == "null" ]; then
        REMOVED_LIST+=("$pkg ($inst_ver) - RIMOSSO DA AUR")
    elif [ "$aur_ver" != "$inst_ver" ]; then
        UPGRADE_LIST+=("$pkg ($inst_ver -> $aur_ver)")
        UPGRADE_NAMES+=("$pkg")
    fi
done

if [ ${#UPGRADE_LIST[@]} -eq 0 ] && [ ${#REMOVED_LIST[@]} -eq 0 ]; then
    echo "Tutti i pacchetti AUR sono aggiornati."
    exit 0
fi

echo ""

# 5. Mostra la lista e chiedi cosa aggiornare
if [ ${#UPGRADE_LIST[@]} -gt 0 ]; then
    echo "Pacchetti AUR aggiornabili:"
    for i in "${!UPGRADE_LIST[@]}"; do
        echo "$((i+1)). ${UPGRADE_LIST[$i]}"
    done
    echo ""
fi
if [ ${#REMOVED_LIST[@]} -gt 0 ]; then
    echo "\033[1;33mAttenzione: alcuni pacchetti risultano rimossi dall'AUR:\033[0m"
    for r in "${REMOVED_LIST[@]}"; do
        echo "  $r"
    done
    echo ""
fi

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

# 6. Aggiorna i pacchetti selezionati
BUILD_DIR="$HOME/aurbuild"
mkdir -p "$BUILD_DIR"
done

for pkg in "${TO_UPDATE[@]}"; do
    echo -e "\n\033[1;34mAggiornamento di $pkg...\033[0m"
    cd "$BUILD_DIR"
    if [ -d "$pkg" ]; then
        cd "$pkg" && git pull || { echo "Impossibile aggiornare repo $pkg"; continue; }
    else
        git clone "https://aur.archlinux.org/$pkg.git" || { echo "Clonazione fallita per $pkg"; continue; }
        cd "$pkg"
    fi
    # makepkg va eseguito come utente normale, pacman chiederà sudo se necessario
    if ! makepkg -si --noconfirm; then
        echo "Errore durante la compilazione/installazione di $pkg."
    fi
    cd "$BUILD_DIR"
done

echo -e "\n\033[1;32mAggiornamento completato.\033[0m"
