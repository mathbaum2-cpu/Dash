#!/usr/bin/env bash
# Reads today's Android usage stats via `dumpsys usagestats` and writes
# data/android/<date>.json into the git repo, then commits and pushes.
#
# Requires: Termux has been granted "Usage access" in
# Settings > Apps > Special app access > Usage access > Termux > Allow.
# No root or adb needed.
#
# NOTE: `dumpsys usagestats` is plain-text and its exact format varies by
# Android version/OEM. Run `dumpsys usagestats > ~/usagestats_sample.txt`
# once and eyeball it if the parser below finds nothing - the two fields it
# relies on (`package=` and `totalTimeUsed=`) are present on stock AOSP 10-14
# but adjust the regex in parse.py if your device differs.
set -euo pipefail

REPO_DIR="${SCREENTIME_REPO_DIR:?set SCREENTIME_REPO_DIR to the local clone of this repo}"
DEVICE_NAME="${SCREENTIME_DEVICE_NAME:-android}"
DAY=$(date +%F)

OUT_DIR="$REPO_DIR/data/$DEVICE_NAME"
OUT_FILE="$OUT_DIR/$DAY.json"
mkdir -p "$OUT_DIR"

RAW=$(dumpsys usagestats 2>&1)

if echo "$RAW" | grep -qi "Permission Denial"; then
  echo "No usage-stats permission. Grant it in Settings > Apps > Special app" >&2
  echo "access > Usage access > Termux > Allow, then retry." >&2
  exit 1
fi

echo "$RAW" | python3 "$(dirname "${BASH_SOURCE[0]}")/parse.py" "$DAY" "$DEVICE_NAME" > "$OUT_FILE"

cd "$REPO_DIR"
git add "data/$DEVICE_NAME/$DAY.json"
if ! git diff --cached --quiet; then
  git commit -m "screentime: update $DEVICE_NAME $DAY" -q
  git push -q origin HEAD
fi
