


# Arch AUR Updater Script

**English below | Italiano in fondo**

---

## 🇮🇹 Descrizione (Italiano)

Script per Arch Linux che:
- Controlla aggiornamenti dei pacchetti AUR installati
- Permette aggiornamento selettivo o di tutti i pacchetti
- Ignora pacchetti *debug* e quelli elencati in `~/.aurignore`
- Segnala pacchetti orfani, out-of-date, rimossi, dipendenze AUR mancanti
- Logga tutte le operazioni in `~/aur-update.log`
- Notifica a fine aggiornamento o errore (notify-send)
- Pulisce automaticamente le directory di build obsolete
- Controlla se esiste una nuova versione dello script su GitHub
- Supporta i flag `--check`, `--all`, `--help/-h`

### Uso

```bash
./update-aur.sh [--check] [--all] [--help]
```

- `--check`   : Mostra solo lo stato dei pacchetti AUR senza prompt di aggiornamento
- `--all`     : Aggiorna tutti i pacchetti AUR aggiornabili senza prompt
- `--help/-h` : Mostra l'help e termina

### File ~/.aurignore
Elenca (uno per riga) i pacchetti AUR da escludere da controlli/aggiornamenti.

### Esempi
```bash
./update-aur.sh --check
./update-aur.sh --all
./update-aur.sh
```

---

## 🇬🇧 Description (English)

Bash script for Arch Linux to:
- Check for updates of installed AUR packages
- Allow selective or full update
- Ignore *debug* packages and those listed in `~/.aurignore`
- Report orphaned, out-of-date, removed packages, missing AUR dependencies
- Log all operations to `~/aur-update.log`
- Desktop notification at end or on error (notify-send)
- Automatically cleans up obsolete build directories
- Checks for new script version on GitHub
- Supports `--check`, `--all`, `--help/-h` flags

### Usage

```bash
./update-aur.sh [--check] [--all] [--help]
```

- `--check`   : Only show AUR package status, no update prompt
- `--all`     : Update all upgradable AUR packages without prompt
- `--help/-h` : Show help and exit

### File ~/.aurignore
List (one per line) AUR packages to exclude from checks/updates.

### Examples
```bash
./update-aur.sh --check
./update-aur.sh --all
./update-aur.sh
```

---

## Requisiti / Requirements
- Arch Linux
- pacman, curl, jq, git, makepkg
- (opzionale) notify-send per notifiche desktop

## Funzionalità principali / Main Features
- Output colorato e simboli per stato pacchetti
- Logging dettagliato
- Notifiche desktop
- Pulizia build dir
- Supporto ignore list
- Controllo nuova versione script
- Help integrato

## Aggiornamento script
Lo script controlla automaticamente la presenza di nuove versioni su GitHub.

## Licenza
MIT
