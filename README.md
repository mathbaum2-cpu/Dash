# Screentime Tracker

Tracks app usage on an Arch Linux laptop (Omarchy/Hyprland) and an Android
phone, syncing both into this repo as JSON so any Claude session can read
and analyze the data directly.

## How it works

Each device runs a small local script that samples/reads app usage and
periodically commits+pushes a JSON summary to `data/<device>/<date>.json`.
There's no server or database - git is the sync mechanism and the data
store.

- **Laptop setup:** [`laptop/`](laptop/) - polls the active Hyprland window
  via `hyprctl` and a systemd user timer syncs it to git. See
  [`laptop/install.sh`](laptop/install.sh).
- **Android setup:** [`android/termux/`](android/termux/) - reads
  `dumpsys usagestats` from Termux and syncs it to git. See
  [`android/termux/README.md`](android/termux/README.md).
- **Data format:** [`docs/DATA_SCHEMA.md`](docs/DATA_SCHEMA.md).

## Reading the data

List `data/*/*.json`. Each file is one device's totals for one day, updated
in place throughout the day. No aggregation script is needed to read it -
parse the JSON and sum/compare as needed.
