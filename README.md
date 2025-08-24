



# Arch AUR Updater Script

[English](#english) | [Italiano](#italiano)

---



## English


**Version: 3.6**

Bash script for Arch Linux to:
- Check for updates of installed AUR packages
- Allow selective or full update
- Install new AUR packages with `--install <pkg1> [<pkg2> ...]`
- Remove AUR packages with `--remove <pkg1> [<pkg2> ...]`
- Ignore *debug* packages and those listed in `~/.aurignore`
- Report orphaned, out-of-date, removed packages, missing AUR dependencies
- Log all operations to `~/aur-update.log`
- Desktop notification at end or on error (notify-send)
- Automatically cleans up obsolete build directories
- Checks for new script version on GitHub
- Supports `--check`/`-c`, `--all`/`-a`, `--no-color`/`-n`, `--compact`/`-C`, `--full`/`-F`, `--install`/`-i`, `--remove`/`-r`, `--help`/`-h` flags
- Handles pacman lock file: aborts if `/var/lib/pacman/db.lck` exists
- All output, prompts and notifications are in English

### Usage

```bash
./update-aur.sh [--check|-c] [--all|-a] [--no-color|-n] [--compact|-C|--full|-F] [--install|-i <pkg1> [<pkg2> ...]] [--remove|-r <pkg1> [<pkg2> ...]] [--help|-h]
```

- `--check`, `-c`      : Only show AUR package status, no update prompt
- `--all`, `-a`        : Update all upgradable AUR packages without prompt
- `--no-color`, `-n`   : Disable colored output
- `--compact`, `-C`    : Compact output (one line per package, minimal info)
- `--full`, `-F`       : Full output (detailed info, default)
- `--install`, `-i`    : Install one or more AUR packages (space separated)
- `--remove`, `-r`     : Remove one or more AUR packages (space separated)
- `--help`, `-h`       : Show help and exit

### File ~/.aurignore
List (one per line) AUR packages to exclude from checks/updates.

### Examples
```bash
./update-aur.sh --check --compact
./update-aur.sh -c -C
./update-aur.sh --all --no-color
./update-aur.sh -a -n
./update-aur.sh --full
./update-aur.sh -F
./update-aur.sh --install google-chrome visual-studio-code-bin
./update-aur.sh -i google-chrome visual-studio-code-bin
./update-aur.sh --remove google-chrome visual-studio-code-bin
./update-aur.sh -r google-chrome visual-studio-code-bin
```

---



## Italiano


**Versione: 3.6**

Script per Arch Linux che:
- Controlla aggiornamenti dei pacchetti AUR installati
- Permette aggiornamento selettivo o di tutti i pacchetti
- Installa nuovi pacchetti AUR con `--install <pkg1> [<pkg2> ...]`
- Rimuove pacchetti AUR con `--remove <pkg1> [<pkg2> ...]`
- Ignora pacchetti *debug* e quelli elencati in `~/.aurignore`
- Segnala pacchetti orfani, out-of-date, rimossi, dipendenze AUR mancanti
- Logga tutte le operazioni in `~/aur-update.log`
- Notifica a fine aggiornamento o errore (notify-send)
- Pulisce automaticamente le directory di build obsolete
- Controlla se esiste una nuova versione dello script su GitHub
- Supporta i flag `--check`/`-c`, `--all`/`-a`, `--no-color`/`-n`, `--compact`/`-C`, `--full`/`-F`, `--install`/`-i`, `--remove`/`-r`, `--help`/`-h`
- Gestisce il lock file di pacman: termina se `/var/lib/pacman/db.lck` esiste
- Tutto l'output, i prompt e le notifiche sono ora in inglese

### Uso

```bash
./update-aur.sh [--check|-c] [--all|-a] [--no-color|-n] [--compact|-C|--full|-F] [--install|-i <pkg1> [<pkg2> ...]] [--remove|-r <pkg1> [<pkg2> ...]] [--help|-h]
```

- `--check`, `-c`      : Mostra solo lo stato dei pacchetti AUR senza prompt di aggiornamento
- `--all`, `-a`        : Aggiorna tutti i pacchetti AUR aggiornabili senza prompt
- `--no-color`, `-n`   : Disabilita l'output colorato
- `--compact`, `-C`    : Output compatto (una riga per pacchetto, info minima)
- `--full`, `-F`       : Output esteso (dettagliato, default)
- `--install`, `-i`    : Installa uno o più pacchetti AUR (separati da spazio)
- `--remove`, `-r`     : Rimuove uno o più pacchetti AUR (separati da spazio)
- `--help`, `-h`       : Mostra l'help e termina

### File ~/.aurignore
Elenca (uno per riga) i pacchetti AUR da escludere da controlli/aggiornamenti.

### Esempi
```bash
./update-aur.sh --check --compact
./update-aur.sh -c -C
./update-aur.sh --all --no-color
./update-aur.sh -a -n
./update-aur.sh --full
./update-aur.sh -F
./update-aur.sh --install google-chrome visual-studio-code-bin
./update-aur.sh -i google-chrome visual-studio-code-bin
./update-aur.sh --remove google-chrome visual-studio-code-bin
./update-aur.sh -r google-chrome visual-studio-code-bin
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
- All output, prompts and notifications are in English

## Script update / Aggiornamento script
The script automatically checks for new versions on GitHub.

## License / Licenza
MIT
