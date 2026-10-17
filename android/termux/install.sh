#!/usr/bin/env bash
# Run this from inside Termux, in your local clone of this repo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

command -v python3 >/dev/null || { echo "run: pkg install python"; exit 1; }
command -v git >/dev/null || { echo "run: pkg install git"; exit 1; }
command -v curl >/dev/null || { echo "run: pkg install curl"; exit 1; }
command -v termux-job-scheduler >/dev/null || { echo "run: pkg install termux-api"; exit 1; }

mkdir -p "$HOME/.config/screentime"
ENV_FILE="$HOME/.config/screentime/env"
if [[ ! -f "$ENV_FILE" ]]; then
  cat > "$ENV_FILE" <<EOF
SCREENTIME_REPO_DIR=$REPO_DIR
SCREENTIME_DEVICE_NAME=android
EOF
  echo "Wrote $ENV_FILE"
else
  echo "$ENV_FILE already exists, leaving it as-is"
fi

if ! grep -q '^RESCUETIME_API_KEY=' "$ENV_FILE" 2>/dev/null; then
  echo ""
  echo "This tracker reads usage data from the RescueTime API (the Android"
  echo "app tracks usage without needing root or the DUMP permission that"
  echo "raw 'dumpsys usagestats' would require)."
  echo "1. Install the RescueTime Android app and let it track for a bit."
  echo "2. Get an API key at https://www.rescuetime.com/anapi/manage"
  read -rp "Enter your RescueTime API key: " RT_KEY
  echo "RESCUETIME_API_KEY=$RT_KEY" >> "$ENV_FILE"
fi

mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/screentime-run.sh" <<'EOF'
#!/usr/bin/env bash
set -a
source "$HOME/.config/screentime/env"
set +a
exec "$SCREENTIME_REPO_DIR/android/termux/track.sh"
EOF
chmod 755 "$HOME/.local/bin/screentime-run.sh"

# Schedules a periodic (best-effort, Android may batch/delay it) job via
# Termux:API's job scheduler - this is Termux's equivalent of a systemd
# timer, since Termux has no init system of its own.
termux-job-scheduler \
  --job-id 1001 \
  --period-ms 900000 \
  --persisted true \
  --script "$HOME/.local/bin/screentime-run.sh"

echo "Scheduled. First run may take a few minutes; check with:"
echo "  bash $HOME/.local/bin/screentime-run.sh   # to run once manually"
echo ""
echo "Make sure the RescueTime Android app is installed and has been"
echo "tracking for a few minutes, otherwise the API will return no rows yet."
