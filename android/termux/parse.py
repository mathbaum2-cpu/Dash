#!/usr/bin/env python3
"""Parses a RescueTime Analytic Data API response (JSON, stdin) into the
shared screentime JSON schema (see docs/DATA_SCHEMA.md).

Expects the response of a query like:
  https://www.rescuetime.com/anapi/data?key=<key>&perspective=interval&
    restrict_kind=activity&interval=day&restrict_begin=<day>&
    restrict_end=<day>&format=json

Row layout (row_headers): Date, Time Spent (seconds), Number of People,
Activity, Category, Productivity.
"""
import sys
import json
import collections
import datetime


def main():
    day, device = sys.argv[1], sys.argv[2]
    payload = json.load(sys.stdin)

    counts = collections.Counter()
    for row in payload.get("rows", []):
        seconds, activity = row[1], row[3]
        counts[activity] += seconds

    apps = dict(sorted(counts.items(), key=lambda kv: -kv[1]))

    data = {
        "date": day,
        "device": device,
        "apps": apps,
        "total_seconds": sum(apps.values()),
        "updated_at": datetime.datetime.utcnow().isoformat() + "Z",
    }
    json.dump(data, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
