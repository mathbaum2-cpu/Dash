#!/usr/bin/env bash
# Fetches today's per-app usage from the RescueTime Analytic Data API and
# writes data/android/<date>.json into the git repo, then commits and
# pushes.
#
# Requires:
#  - The RescueTime Android app installed and tracking enabled (this reads
#    Android's official usage-stats API, so it needs no root and no
#    android.permission.DUMP - unlike calling `dumpsys` directly, which is
#    blocked on modern Android even with "Usage access" granted).
#  - RESCUETIME_API_KEY set in ~/.config/screentime/env (get one at
#    https://www.rescuetime.com/anapi/manage).
set -euo pipefail

REPO_DIR="${SCREENTIME_REPO_DIR:?set SCREENTIME_REPO_DIR to the local clone of this repo}"
DEVICE_NAME="${SCREENTIME_DEVICE_NAME:-android}"
API_KEY="${RESCUETIME_API_KEY:?set RESCUETIME_API_KEY in ~/.config/screentime/env - get one at https://www.rescuetime.com/anapi/manage}"
DAY=$(date +%F)

OUT_DIR="$REPO_DIR/data/$DEVICE_NAME"
OUT_FILE="$OUT_DIR/$DAY.json"
mkdir -p "$OUT_DIR"

RAW=$(curl -fsS "https://www.rescuetime.com/anapi/data?key=$API_KEY&perspective=interval&restrict_kind=activity&interval=day&restrict_begin=$DAY&restrict_end=$DAY&format=json")

echo "$RAW" | python3 "$(dirname "${BASH_SOURCE[0]}")/parse.py" "$DAY" "$DEVICE_NAME" > "$OUT_FILE"

cd "$REPO_DIR"
git add "data/$DEVICE_NAME/$DAY.json"
if ! git diff --cached --quiet; then
  git commit -m "screentime: update $DEVICE_NAME $DAY" -q
  git push -q origin HEAD
fi
