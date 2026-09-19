#!/usr/bin/env bash
# Samples the active Hyprland window every $SCREENTIME_INTERVAL seconds and
# appends one line per sample to a daily raw log. Each line represents
# $SCREENTIME_INTERVAL seconds of usage of that app (duty-cycle sampling).
set -euo pipefail

INTERVAL="${SCREENTIME_INTERVAL:-10}"
RAW_DIR="${SCREENTIME_RAW_DIR:-$HOME/.local/share/screentime/raw}"

mkdir -p "$RAW_DIR"

while true; do
  # Skip counting while the screen is locked (Omarchy uses hyprlock).
  if pgrep -x hyprlock >/dev/null 2>&1; then
    sleep "$INTERVAL"
    continue
  fi

  window_class=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty')

  if [[ -n "$window_class" ]]; then
    day=$(date +%F)
    ts=$(date +%s)
    printf '%s\t%s\n' "$ts" "$window_class" >> "$RAW_DIR/$day.tsv"
  fi

  sleep "$INTERVAL"
done
