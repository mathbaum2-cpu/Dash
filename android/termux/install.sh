#!/usr/bin/env bash
# Run this from inside Termux, in your local clone of this repo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

command -v python3 >/dev/null || { echo "run: pkg install python"; exit 1; }
command -v git >/dev/null || { echo "run: pkg install git"; exit 1; }
command -v termux-job-scheduler >/dev/null || { echo "run: pkg install termux-api"; exit 1; }

mkdir -p "$HOME/.config/screentime"
cat > "$HOME/.config/screentime/env" <<EOF
SCREENTIME_REPO_DIR=$REPO_DIR
SCREENTIME_DEVICE_NAME=android
EOF

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
echo "If this fails with a permission error, grant Termux 'Usage access' in"
echo "Settings > Apps > Special app access > Usage access > Termux > Allow."
