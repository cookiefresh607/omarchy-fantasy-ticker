# Fantasy Ticker

Fantasy Ticker is an Omarchy bar widget for displaying live information from
one Sleeper NFL fantasy league.

It uses Sleeper's public API. You do not need to create an API key or give the
plugin your Sleeper password.

## Features

- Shows `🏈` as a compact launcher in the Omarchy bar.
- Opens a popup when clicked.
- Shows the configured league name, current NFL week, and matchup number.
- Shows both fantasy team names and their aggregate matchup scores.
- Shows loading and offline/error states.
- Keeps the last successful scores visible if a later refresh fails.
- Refreshes automatically once per minute by default.

The current version supports one Sleeper NFL league. It displays aggregate
matchup scores supplied by Sleeper; it does not calculate individual player
fantasy points, injuries, or multiple leagues itself.

## Prerequisites

You need:

- Omarchy with the `omarchy` command available.
- A Sleeper account.
- An NFL fantasy league on Sleeper.
- A working internet connection while finding your league and while using the
  live ticker.

You do not need a Sleeper API key, login token, password, or special API
software. The commands below use `curl`, which is included with Omarchy.

## Installation

Install and enable the plugin with Omarchy:

```bash
omarchy plugin add https://github.com/cookiefresh607/omarchy-fantasy-ticker.git --enable
```

Omarchy will ask you to confirm the installation. The `--enable` option tells
Omarchy to enable the plugin and place this bar widget in the bar. The command
uses HTTPS because it works for normal GitHub users without SSH keys.

Omarchy installs the plugin here:

```text
~/.config/omarchy/plugins/fantasy-ticker/
```

The plugin may not show useful data until you complete the configuration below.

## Find your Sleeper user ID

Your Sleeper username is not the same thing as your Sleeper user ID. Use your
username to ask Sleeper for your user record.

Replace `<YOUR_SLEEPER_USERNAME>` with your Sleeper username, then run:

```bash
curl --fail --silent --show-error \
  "https://api.sleeper.app/v1/user/<YOUR_SLEEPER_USERNAME>"
```

Do not include the `<` and `>` characters when replacing the placeholder.

The response will look similar to this:

```json
{
  "username": "example_user",
  "user_id": "123456789",
  "display_name": "Example User"
}
```

Copy the value after `"user_id"`. In this example, the value to copy is
`123456789`. This is your Sleeper user ID. Keep it as a text value when you
put it into `shell.json`.

If you have `jq` installed, this optional version formats the response for
easier reading:

```bash
curl --fail --silent --show-error \
  "https://api.sleeper.app/v1/user/<YOUR_SLEEPER_USERNAME>" | jq .
```

The basic command does not require `jq`.

## Find your NFL league ID

Sleeper needs both your user ID and the four-digit NFL season. Replace the two
placeholders below and run:

```bash
curl --fail --silent --show-error \
  "https://api.sleeper.app/v1/user/<YOUR_SLEEPER_USER_ID>/leagues/nfl/<NFL_SEASON>"
```

`<NFL_SEASON>` means the four-digit NFL season, for example `2026`. Do not
include the `<` and `>` characters when replacing placeholders.

The response is a JSON list of leagues. Each league has fields similar to:

```json
{
  "name": "Example Fantasy League",
  "league_id": "987654321",
  "season": "2026",
  "status": "in_season"
}
```

Find the league you want to display. Check its `name`, `season`, and `status`
so you do not accidentally choose an old or different league. Copy the value
after `"league_id"`. That value is your Sleeper league ID.

If you have `jq` installed, this optional command prints a simple list of
league names, IDs, seasons, and statuses:

```bash
curl --fail --silent --show-error \
  "https://api.sleeper.app/v1/user/<YOUR_SLEEPER_USER_ID>/leagues/nfl/<NFL_SEASON>" |
  jq -r '.[] | [.name, .league_id, .season, .status] | @tsv'
```

The columns are printed in this order:

```text
league name    league ID    season    status
```

If the list is empty, check the season value and confirm that the user ID is
correct.

## Configure Fantasy Ticker

Open this Omarchy shell configuration file with your preferred text editor:

```bash
nvim ~/.config/omarchy/shell.json
```

The command above uses Neovim, which is available on Omarchy. Replace `nvim`
with the text editor you normally use. If you are using Neovim, press `i` to
edit, press `Esc` when finished, type `:wq`, and press Enter to save and exit.

Find the existing bar entry whose ID is `fantasy-ticker`. Edit that existing
entry to include your values. Do not create a second `fantasy-ticker` entry.

Use this as a pattern, replacing the placeholder values:

```json
{
  "id": "fantasy-ticker",
  "userId": "YOUR_SLEEPER_USER_ID",
  "leagueId": "YOUR_SLEEPER_LEAGUE_ID",
  "leagueName": "My Fantasy League",
  "refreshSeconds": 60
}
```

The fields mean:

- `id`: tells Omarchy which plugin this bar entry uses. Leave it as
  `fantasy-ticker`.
- `userId`: your Sleeper account's `user_id`.
- `leagueId`: the `league_id` for the NFL league you selected.
- `leagueName`: the name displayed in the popup. This is a local label and
  does not need to exactly match Sleeper's league name.
- `refreshSeconds`: how often the widget requests updated scores. `60` is the
  recommended value. The plugin enforces a 30-second minimum; invalid, zero,
  negative, or missing values fall back to 60 seconds.

Keep `shell.json` valid JSON. Property names and text values need double quotes.
Put a comma between fields, but not after the final field in an object. Do not
replace the entire file; preserve your other bar widgets and settings.

## Reload/rescan the plugin

After saving the configuration, use Omarchy's supported plugin rescan command:

```bash
omarchy-shell shell rescanPlugins
```

This rescans plugin code without restarting your whole session. Omarchy also
reloads plugin files saved under `~/.config/omarchy/plugins/` automatically.

## Remove Fantasy Ticker

To remove the installed plugin, use Omarchy's supported removal command:

```bash
omarchy plugin remove fantasy-ticker
```

After removal, check `~/.config/omarchy/shell.json` and remove or review any
remaining `fantasy-ticker` bar entry if Omarchy leaves one behind. Preserve
your other bar widgets and settings.

## Verify the installation

A successful setup looks like this:

1. `🏈` appears in the Omarchy bar.
2. Hovering over it shows the `Fantasy Ticker` tooltip.
3. Clicking it opens the `Fantasy Ticker` popup.
4. Your configured league name appears.
5. The current NFL week appears.
6. Both fantasy team names and scores appear.
7. The status changes from `Loading…` to `Live`.
8. `Last updated` shows a recent local time.

You can check whether Omarchy discovered the plugin with:

```bash
omarchy plugin list
```

The lower-level shell command is:

```bash
omarchy-shell shell listPlugins
```

## Troubleshooting

### The `🏈` icon is missing

Check that the plugin is installed and discovered:

```bash
omarchy plugin list
```

If it is installed but disabled, enable it:

```bash
omarchy plugin enable fantasy-ticker
omarchy-shell shell rescanPlugins
```

Also check that the bar layout contains an entry with:

```json
"id": "fantasy-ticker"
```

### The plugin is installed but disabled

Run:

```bash
omarchy plugin enable fantasy-ticker
```

Then run the plugin rescan command from the previous section.

### `shell.json` is invalid

If `jq` is installed, validate the file with:

```bash
jq empty ~/.config/omarchy/shell.json
```

No output means the JSON is valid. An error usually means a missing comma,
extra comma, or mismatched quote.

### The user ID is rejected or no leagues are returned

Run the user lookup command again and make sure you copied `user_id`, not
`username` or `display_name`. Use the exact Sleeper username and try the
correct four-digit NFL season.

### The wrong league is displayed

Run the league lookup command again and compare the league's `name`,
`league_id`, `season`, and `status`. Update only the `leagueId` and
`leagueName` fields in the existing Fantasy Ticker entry.

### The popup says there is no current matchup

Check that you selected the correct league and season. A league may not have a
current matchup during the offseason, a bye week, or a playoff bye. The
plugin currently supports one weekly matchup and does not choose among
multiple leagues.

### Sleeper is offline or the widget says Offline

Test the public NFL state endpoint directly:

```bash
curl --fail --silent --show-error \
  "https://api.sleeper.app/v1/state/nfl"
```

If this command fails, check your internet connection or wait for Sleeper to
become available. The widget will try again on its next refresh.

### Scores are not updating

Confirm that `refreshSeconds` is not set to an unexpectedly large value. The
recommended value is `60`. Check that `Last updated` changes after a minute or
two. Sleeper supplies aggregate matchup totals, so a score may remain
unchanged when games are not in progress.

## Privacy and Sleeper API notes

- Fantasy Ticker uses Sleeper's public, read-only HTTP API.
- No Sleeper password is required.
- No Sleeper API key or login token is required.
- `userId` and `leagueId` are identifiers, not passwords.
- Keep personal IDs in your local `~/.config/omarchy/shell.json`.
- Do not commit personal IDs to a public plugin repository.
- The plugin sends read-only requests for the configured league and does not
  modify Sleeper data.

## Development information

The project repository contains:

- `manifest.json`: Omarchy plugin metadata and configuration schema.
- `BarWidget.qml`: the bar launcher, popup, refresh timer, and Sleeper request
  handling.
- `README.md`: this installation and configuration guide.

The development source is in `<project-directory>`. The installed copy is in
`~/.config/omarchy/plugins/fantasy-ticker/`. The user's bar configuration is
in `~/.config/omarchy/shell.json`.
