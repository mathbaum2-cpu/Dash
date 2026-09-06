# Android setup (Termux)

1. Install [Termux](https://f-droid.org/packages/com.termux/) and
   [Termux:API](https://f-droid.org/packages/com.termux.api/) from F-Droid
   (the Play Store builds are outdated and often broken - use F-Droid).
2. In Termux:
   ```
   pkg install git python termux-api
   git clone <this-repo-url>
   cd Dash
   bash android/termux/install.sh
   ```
3. Grant Termux usage-stats permission: **Settings > Apps > Special app
   access > Usage access > Termux > Allow**. No root or ADB required - this
   is the same standard Android permission any usage-tracking app asks for.
4. Test it manually once: `bash ~/.local/bin/screentime-run.sh` and check
   that `data/android/<today>.json` in your repo clone got populated and
   pushed.
5. Set up git push auth in Termux beforehand (e.g. an SSH key added via
   `ssh-keygen` + added to your GitHub account, or a token-based HTTPS
   remote) - the sync script pushes non-interactively.

## If parsing finds no apps

`dumpsys usagestats` is a plain-text debug dump, not a stable API, and its
exact layout differs across Android versions and OEM skins. If
`data/android/<date>.json` ends up with an empty `apps` object:

```
dumpsys usagestats > ~/usagestats_sample.txt
```

and look at how a per-app line is actually formatted on your device, then
adjust `LINE_RE` in `android/termux/parse.py` to match.

## Fallback if `dumpsys usagestats` doesn't work at all

Some OEM ROMs restrict this further. If so, Tasker (paid) with the AutoTools
plugin can query usage stats through the officially sanctioned Usage Access
permission and write a file that Termux then picks up and pushes the same
way - ask if you want that variant instead.
