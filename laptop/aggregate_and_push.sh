#!/usr/bin/env bash
# Aggregates today's raw sample log into data/laptop/<date>.json inside the
# git repo, then commits and pushes it if it changed. Meant to be run
# periodically (see systemd/screentime-sync.timer).
set -euo pipefail

REPO_DIR="${SCREENTIME_REPO_DIR:?set SCREENTIME_REPO_DIR to the local clone of this repo}"
RAW_DIR="${SCREENTIME_RAW_DIR:-$HOME/.local/share/screentime/raw}"
INTERVAL="${SCREENTIME_INTERVAL:-10}"
DEVICE_NAME="${SCREENTIME_DEVICE_NAME:-laptop}"
DAY=$(date +%F)

RAW_FILE="$RAW_DIR/$DAY.tsv"
OUT_DIR="$REPO_DIR/data/$DEVICE_NAME"
OUT_FILE="$OUT_DIR/$DAY.json"

mkdir -p "$OUT_DIR"

if [[ ! -f "$RAW_FILE" ]]; then
  exit 0
fi

python3 - "$RAW_FILE" "$INTERVAL" "$DAY" "$DEVICE_NAME" "$OUT_FILE" <<'PYEOF'
import sys, json, collections, datetime

raw_file, interval, day, device, out_file = sys.argv[1:6]
interval = int(interval)

counts = collections.Counter()
with open(raw_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        _, app = line.split("\t", 1)
        counts[app] += interval

data = {
    "date": day,
    "device": device,
    "apps": dict(sorted(counts.items(), key=lambda kv: -kv[1])),
    "total_seconds": sum(counts.values()),
    "updated_at": datetime.datetime.utcnow().isoformat() + "Z",
}

with open(out_file, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF

cd "$REPO_DIR"
git add "data/$DEVICE_NAME/$DAY.json"
if ! git diff --cached --quiet; then
  git commit -m "screentime: update $DEVICE_NAME $DAY" -q
  git push -q origin HEAD
fi
