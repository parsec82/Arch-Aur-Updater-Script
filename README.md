

# Arch Aur Updater Script


**English below | Italiano in fondo**

---

## Table of Contents
- [English](#english)
- [Italiano](#italiano)

---


# English

Bash script to check and update AUR packages on Arch Linux **without** using yay, paru, or other AUR helpers.
This project is called **Arch Aur Updater Script**.

## Features
- Lists installed AUR packages (excluding those with "debug" in the name)
- Checks for available updates via the AUR API
- Shows packages:
  - Upgradable
  - Removed from AUR
  - Orphaned (Maintainer: None)
  - Flagged as "out-of-date"
- Lets you choose which packages to update (all or selection)
- Downloads, builds, and installs the selected packages
- Deletes the build directory after a successful update

## Requirements
- Arch Linux
- pacman
- curl
- jq
- git
- makepkg

## Usage
1. Make the script executable:
   ```bash
   chmod +x update-aur.sh
   ```
2. Run the script **as a normal user** (not root):
   ```bash
   ./update-aur.sh
   ```
3. Follow the on-screen instructions to choose which packages to update.

## Notes
- The script deletes the build directory of the package after a successful update.
- If the build fails, the directory is kept for debugging purposes.
- Orphaned and out-of-date packages are only reported, not updated automatically.
- If a package is removed from AUR, it is reported.

## Security
Always review PKGBUILD files before installing packages from AUR!

## Example output
```
Upgradable AUR packages:
1. google-chrome (139.0.7258.66-1 -> 139.0.7258.127-1)
2. postman-bin (11.57.5-1 -> 11.58.4-1)

Warning: packages flagged as OUT-OF-DATE:
  uefitool (1:0.28.0-2) - FLAGGED OUT-OF-DATE

Do you want to update all packages? (y/N)
```

## License
MIT

---


# Italiano

Script Bash per controllare e aggiornare pacchetti AUR su Arch Linux **senza** usare yay, paru o altri AUR helper.
Questo progetto si chiama **Arch Aur Updater Script**.

## Funzionalità
- Elenca i pacchetti AUR installati (escludendo quelli con "debug" nel nome)
- Controlla la presenza di aggiornamenti tramite API AUR
- Mostra pacchetti:
  - Aggiornabili
  - Rimossi dall'AUR
  - Orfani (Maintainer: None)
  - Flaggati come "out-of-date"
- Permette di scegliere quali pacchetti aggiornare (tutti o selezione)
- Scarica, compila e installa i pacchetti scelti
- Elimina la directory di build dopo aggiornamento riuscito

## Requisiti
- Arch Linux
- pacman
- curl
- jq
- git
- makepkg

## Utilizzo
1. Rendi eseguibile lo script:
   ```bash
   chmod +x update-aur.sh
   ```
2. Esegui lo script **come utente normale** (non root):
   ```bash
   ./update-aur.sh
   ```
3. Segui le istruzioni a schermo per scegliere quali pacchetti aggiornare.

## Note
- Lo script elimina la directory di build del pacchetto dopo aggiornamento riuscito.
- Se la build fallisce, la directory resta per eventuale debug.
- I pacchetti orfani e out-of-date vengono solo segnalati, non aggiornati automaticamente.
- Se un pacchetto risulta rimosso dall'AUR, viene segnalato.

## Sicurezza
Controlla sempre i PKGBUILD prima di installare pacchetti da AUR!

## Esempio di output
```
Pacchetti AUR aggiornabili:
1. google-chrome (139.0.7258.66-1 -> 139.0.7258.127-1)
2. postman-bin (11.57.5-1 -> 11.58.4-1)

Attenzione: pacchetti flaggati come OUT-OF-DATE:
  uefitool (1:0.28.0-2) - FLAGGATO OUT-OF-DATE

Vuoi aggiornare tutti i pacchetti? (s/N)
```

## Licenza
MIT
