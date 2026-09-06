# Screentime data schema

Each device writes one JSON file per day to `data/<device>/<YYYY-MM-DD>.json`:

```json
{
  "date": "2026-09-06",
  "device": "laptop",
  "apps": {
    "firefox": 5423,
    "code": 3400,
    "kitty": 1200
  },
  "total_seconds": 10023,
  "updated_at": "2026-09-06T18:32:00Z"
}
```

- `apps`: seconds of active foreground time per app, sorted descending. On the
  laptop the key is the Hyprland window class (`hyprctl activewindow -j` ->
  `.class`). On Android it's the app package name.
- `total_seconds`: sum of all `apps` values for that day.
- `updated_at`: UTC timestamp of the last sync for that file. Files are
  overwritten in place throughout the day as new samples come in, so the
  latest git commit for a given date always has the current totals for that
  day.
- `device`: currently `laptop` or `android`. Add more subfolders under
  `data/` for additional devices; the schema is per-device-per-day and
  doesn't need central coordination.

Reading the data (e.g. from Claude): list `data/*/*.json`, parse each file,
and aggregate/compare across dates and devices as needed. There is no
database - the git history of these files is the full time series.
