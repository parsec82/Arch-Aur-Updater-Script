



# Arch AUR Updater Script

[English](#english) | [Italiano](#italiano)

---


## English

Bash script for Arch Linux to:
- Check for updates of installed AUR packages
- Allow selective or full update
- Ignore *debug* packages and those listed in `~/.aurignore`
- Report orphaned, out-of-date, removed packages, missing AUR dependencies
- Log all operations to `~/aur-update.log`
- Desktop notification at end or on error (notify-send)
- Automatically cleans up obsolete build directories
- Checks for new script version on GitHub
- Supports `--check`, `--all`, `--no-color`, `--compact`, `--full`, `--help/-h` flags
- Handles pacman lock file: aborts if `/var/lib/pacman/db.lck` exists

### Usage

```bash
./update-aur.sh [--check] [--all] [--no-color] [--compact|--full] [--help]
```

- `--check`      : Only show AUR package status, no update prompt
- `--all`        : Update all upgradable AUR packages without prompt
- `--no-color`   : Disable colored output
- `--compact`    : Compact output (one line per package, minimal info)
- `--full`       : Full output (detailed info, default)
- `--help/-h`    : Show help and exit

### File ~/.aurignore
List (one per line) AUR packages to exclude from checks/updates.

### Examples
```bash
./update-aur.sh --check --compact
./update-aur.sh --all --no-color
./update-aur.sh --full
```

---


## Italiano

Script per Arch Linux che:
- Controlla aggiornamenti dei pacchetti AUR installati
- Permette aggiornamento selettivo o di tutti i pacchetti
- Ignora pacchetti *debug* e quelli elencati in `~/.aurignore`
- Segnala pacchetti orfani, out-of-date, rimossi, dipendenze AUR mancanti
- Logga tutte le operazioni in `~/aur-update.log`
- Notifica a fine aggiornamento o errore (notify-send)
- Pulisce automaticamente le directory di build obsolete
- Controlla se esiste una nuova versione dello script su GitHub
- Supporta i flag `--check`, `--all`, `--no-color`, `--compact`, `--full`, `--help/-h`
- Gestisce il lock file di pacman: termina se `/var/lib/pacman/db.lck` esiste

### Uso

```bash
./update-aur.sh [--check] [--all] [--no-color] [--compact|--full] [--help]
```

- `--check`      : Mostra solo lo stato dei pacchetti AUR senza prompt di aggiornamento
- `--all`        : Aggiorna tutti i pacchetti AUR aggiornabili senza prompt
- `--no-color`   : Disabilita l'output colorato
- `--compact`    : Output compatto (una riga per pacchetto, info minima)
- `--full`       : Output esteso (dettagliato, default)
- `--help/-h`    : Mostra l'help e termina

### File ~/.aurignore
Elenca (uno per riga) i pacchetti AUR da escludere da controlli/aggiornamenti.

### Esempi
```bash
./update-aur.sh --check --compact
./update-aur.sh --all --no-color
./update-aur.sh --full
```

---


## Requirements / Requisiti
- Arch Linux
- pacman, curl, jq, git, makepkg
- (optional/opzionale) notify-send for desktop notifications

## Main Features / Funzionalità principali
- Colored output and status symbols (disable with --no-color)
- Compact or full output mode
- Detailed logging
- Desktop notifications
- Build dir cleanup
- Ignore list support
- Script version check
- Integrated help
- Pacman lock file detection

## Script update / Aggiornamento script
The script automatically checks for new versions on GitHub.

## License / Licenza
MIT
