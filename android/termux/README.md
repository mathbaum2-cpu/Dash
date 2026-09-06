# Android setup (Termux)

Usage data comes from the [RescueTime](https://www.rescuetime.com/) API, not
from calling `dumpsys usagestats` directly. On modern Android, `dumpsys`
requires `android.permission.DUMP`, a signature-level permission regular
apps (including Termux) can't obtain even with "Usage access" granted - it
fails with `Permission Denial: ... missing android.permission.DUMP
permission`. RescueTime's app reads usage through the official
`UsageStatsManager` API (which only needs the normal Usage Access grant)
and syncs it to their servers, where we can pull it back out via their
public Data API.

1. Install the [RescueTime Android app](https://play.google.com/store/apps/details?id=com.rescuetime.rtx),
   sign in/create an account, and let it track for a few minutes.
2. Get an API key at https://www.rescuetime.com/anapi/manage.
3. Install [Termux](https://f-droid.org/packages/com.termux/) and
   [Termux:API](https://f-droid.org/packages/com.termux.api/) from F-Droid
   (the Play Store builds are outdated and often broken - use F-Droid).
4. In Termux:
   ```
   pkg install git python termux-api curl
   git clone <this-repo-url>
   cd Dash
   bash android/termux/install.sh
   ```
   `install.sh` will prompt for the RescueTime API key from step 2 and
   save it to `~/.config/screentime/env`.
5. Test it manually once: `bash ~/.local/bin/screentime-run.sh` and check
   that `data/android/<today>.json` in your repo clone got populated and
   pushed.
6. Set up git push auth in Termux beforehand (e.g. an SSH key added via
   `ssh-keygen` + added to your GitHub account, or a token-based HTTPS
   remote) - the sync script pushes non-interactively.

## If `data/android/<date>.json` has an empty `apps` object

RescueTime syncs on a delay (every 30 min on the free plan, every 3 min on
paid plans) - if the app was only just installed, or hasn't seen much usage
today yet, there may be nothing to return. Try again later in the day, and
double check the API key in `~/.config/screentime/env` is correct.
