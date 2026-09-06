#!/usr/bin/env python3
"""Parses `dumpsys usagestats` text (stdin) into the shared screentime JSON
schema (see docs/DATA_SCHEMA.md). Only looks at the "In-memory daily stats"
section so weekly/monthly/yearly buckets aren't double-counted.

This text format is not a stable API and varies across Android
versions/OEMs. If this finds zero apps on your device, run
`dumpsys usagestats > sample.txt`, look at how a "package=...
totalTimeUsed=..." style line is actually formatted there, and adjust
LINE_RE below.
"""
import sys
import re
import json
import collections
import datetime

LINE_RE = re.compile(r"package=(\S+).*?totalTimeUsed=(\d+)")
SECTION_RE = re.compile(r"In-memory (daily|weekly|monthly|yearly) stats", re.IGNORECASE)


def daily_section(text: str) -> str:
    lines = text.splitlines()
    start = None
    end = len(lines)
    for i, line in enumerate(lines):
        m = SECTION_RE.search(line)
        if m and start is None and m.group(1).lower() == "daily":
            start = i + 1
        elif m and start is not None:
            end = i
            break
    if start is None:
        return text  # fall back to scanning everything
    return "\n".join(lines[start:end])


def main():
    day, device = sys.argv[1], sys.argv[2]
    text = sys.stdin.read()
    section = daily_section(text)

    counts_ms = collections.Counter()
    for line in section.splitlines():
        m = LINE_RE.search(line)
        if m:
            pkg, ms = m.group(1), int(m.group(2))
            counts_ms[pkg] += ms

    apps = {pkg: ms // 1000 for pkg, ms in counts_ms.items()}
    apps = dict(sorted(apps.items(), key=lambda kv: -kv[1]))

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
