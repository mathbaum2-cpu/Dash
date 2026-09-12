#!/usr/bin/env bash
# Run this from inside your local clone of this repo, on the Omarchy/Hyprland
# laptop. Sets up the tracker + git-sync as user-level systemd services.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

command -v hyprctl >/dev/null || { echo "hyprctl not found - are you on Hyprland?"; exit 1; }
command -v jq >/dev/null || { echo "jq not found - install it: sudo pacman -S jq"; exit 1; }
command -v python3 >/dev/null || { echo "python3 not found - install it: sudo pacman -S python"; exit 1; }

mkdir -p "$HOME/.local/bin" "$HOME/.config/screentime" "$HOME/.config/systemd/user"

install -m 755 "$SCRIPT_DIR/track.sh" "$HOME/.local/bin/screentime-track.sh"
install -m 755 "$SCRIPT_DIR/aggregate_and_push.sh" "$HOME/.local/bin/screentime-sync.sh"

if [[ ! -f "$HOME/.config/screentime/env" ]]; then
  cp "$SCRIPT_DIR/config/env.example" "$HOME/.config/screentime/env"
  sed -i "s#^SCREENTIME_REPO_DIR=.*#SCREENTIME_REPO_DIR=$REPO_DIR#" "$HOME/.config/screentime/env"
  echo "Wrote $HOME/.config/screentime/env with SCREENTIME_REPO_DIR=$REPO_DIR"
else
  echo "$HOME/.config/screentime/env already exists, leaving it as-is"
fi

cp "$SCRIPT_DIR/systemd/screentime-track.service" "$HOME/.config/systemd/user/"
cp "$SCRIPT_DIR/systemd/screentime-sync.service" "$HOME/.config/systemd/user/"
cp "$SCRIPT_DIR/systemd/screentime-sync.timer" "$HOME/.config/systemd/user/"

systemctl --user daemon-reload
systemctl --user enable --now screentime-track.service
systemctl --user enable --now screentime-sync.timer

echo "Done. Check status with:"
echo "  systemctl --user status screentime-track.service"
echo "  systemctl --user list-timers screentime-sync.timer"
echo ""
echo "Make sure git push works passwordlessly from this machine (SSH key or"
echo "a credential helper with a token) - the sync service pushes as you."
