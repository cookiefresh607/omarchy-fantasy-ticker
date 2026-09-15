# Fantasy Ticker — Plugin Plan

## Status

This is a planning document only. No plugin implementation has been started yet, and no Omarchy configuration has been changed.

The first release will be a simple Omarchy bar-widget plugin for NFL fantasy football using Sleeper.

## Goal

Fantasy Ticker will eventually connect to fantasy sports services and show live information about the user's fantasy teams in the Omarchy bar.

For version one, the scope is intentionally small:

- Support Sleeper only.
- Support NFL only.
- Support one selected league.
- Show the user's current matchup score in the bar.
- Open a small popup with matchup details.
- Refresh periodically.
- Clearly show unconfigured, loading, stale, offline, and offseason states.

The first version should not attempt to be a complete fantasy dashboard. Multiple leagues, multiple sports, advanced player views, notifications, and player-by-player live scoring can come later.

## What we inspected

The current Omarchy shell is based on Quickshell. Bar widgets are QML components discovered through a `manifest.json` file. User-owned plugin source belongs under:

```text
~/.config/omarchy/plugins/<plugin-id>/
```

The current user's shell configuration is:

```text
~/.config/omarchy/shell.json
```

The local documentation and examples inspected were:

- `/usr/share/omarchy/shell/README.md`
- `/usr/share/omarchy/shell/Ui/BarWidget.qml`
- `/usr/share/omarchy/shell/services/PluginRegistry.qml`
- `~/.config/omarchy/shell.json`
- `~/.config/omarchy/plugins/kairos.day-in-history/`
- `~/.config/omarchy/plugins/slcode777.omagotchi/`
- `~/.config/omarchy/plugins/io.github.seangsr.omarchy-cleaner/`
- `~/.config/omarchy/plugins/akshar.radio-atlas/`

Important Omarchy decisions from that inspection:

- Every plugin needs a root-level `manifest.json`.
- A bar widget declares `kinds: ["bar-widget"]`.
- The manifest points to the QML entry point with `entryPoints.barWidget`.
- A bar-widget instance is enabled by appearing in `bar.layout.left`, `bar.layout.center`, or `bar.layout.right` in `shell.json`.
- Widget settings are stored inline on that layout entry; there is no separate Omarchy settings file for the widget.
- Plugin code under `~/.config/omarchy/plugins/` hot-reloads when saved.
- Plugins run as unsandboxed code inside `omarchy-shell`, so network and parsing work must be defensive and asynchronous.

## Proposed files

The initial plugin repository should eventually look like this:

```text
fantasy-ticker/
├── manifest.json
├── BarWidget.qml
├── FantasyData.js       # optional at first; useful for parsing/formatting helpers
├── README.md
└── tests/
    └── run              # optional parser/validation tests
```

### `manifest.json`

Describes the plugin to Omarchy. It will contain:

- `schemaVersion`: `1`
- Plugin ID, name, version, author, license, and description.
- `kinds: ["bar-widget"]`
- `entryPoints: { "barWidget": "BarWidget.qml" }`
- Bar-widget metadata such as display name, category, whether multiple instances are allowed, and the default bar section.
- Configuration metadata for values such as `userId`, `leagueId`, and `refreshSeconds`.

The proposed plugin ID is `fantasy-ticker`. If the plugin is later published, a namespaced ID such as `com.example.fantasy-ticker` may be more appropriate depending on the distribution convention.

### `BarWidget.qml`

The main UI and controller. It will:

- Import QtQuick, Quickshell, Quickshell.Io, `qs.Commons`, and `qs.Ui` as needed.
- Extend Omarchy's `BarWidget` base component.
- Set `moduleName` to the plugin ID.
- Read inline settings through the base component's settings object.
- Display a compact ticker button.
- Run network requests through asynchronous Quickshell `Process` objects.
- Parse JSON and update QML properties.
- Own a `Timer` for periodic refreshes.
- Open a popup with more information when clicked.

### `FantasyData.js`

Optional initially. It should hold pure helper functions once the QML file becomes crowded, including:

- Safe conversion of numbers and strings.
- Finding the user's roster.
- Finding the opponent with the same matchup ID.
- Formatting scores and timestamps.
- Handling missing or null values.

Keeping data transformation separate from UI code will make the plugin easier to learn, test, and extend.

### `README.md`

Should explain installation, configuration, supported Sleeper data, limitations, and privacy behavior.

### `tests/run`

Optional but recommended. The first tests should exercise parsing against saved sample JSON rather than requiring a live Sleeper account or network connection.

## Technologies

The implementation should use:

- QML for the widget interface.
- QtQuick for UI elements and timers.
- Quickshell for bar integration and asynchronous processes.
- JavaScript embedded in QML or in `FantasyData.js` for parsing and formatting.
- `curl`, launched by Quickshell's `Process`, for HTTPS requests.
- JSON for Sleeper responses and Omarchy configuration.
- Git for version control and eventual plugin distribution.

Python, Node.js, a database, and a web server are not needed for the first version.

## Sleeper API communication

Sleeper's documented API is read-only and does not require an API token. The plugin will communicate with it through HTTPS GET requests.

The planned data flow is:

1. Resolve the user, if the user initially supplies a username:

   ```text
   GET https://api.sleeper.app/v1/user/<username>
   ```

2. Store/use the numeric `user_id`. Usernames can change, so the numeric ID is the better long-term identifier.

3. Discover NFL leagues if league selection is added:

   ```text
   GET https://api.sleeper.app/v1/user/<user_id>/leagues/nfl/<season>
   ```

4. Fetch league metadata:

   ```text
   GET https://api.sleeper.app/v1/league/<league_id>
   ```

5. Fetch rosters:

   ```text
   GET https://api.sleeper.app/v1/league/<league_id>/rosters
   ```

6. Fetch the NFL state to identify the current week:

   ```text
   GET https://api.sleeper.app/v1/state/nfl
   ```

7. Fetch the week's matchups:

   ```text
   GET https://api.sleeper.app/v1/league/<league_id>/matchups/<week>
   ```

The user's roster is found by matching its `owner_id` to the configured Sleeper `user_id`. The opponent is the other roster with the same `matchup_id`. The matchup response includes team totals and matchup IDs.

The full NFL player map should not be downloaded during normal refreshes. Sleeper documents it as approximately 5 MB and recommends requesting it no more than about once per day. If player names are needed later, the plugin should cache that data or request a smaller filtered response where possible.

### Important live-data limitation

The documented Sleeper API clearly provides matchup totals, rosters, league data, NFL state, and player metadata. It does not clearly document a public player-by-player live fantasy-statistics endpoint.

Therefore version one should promise live/current matchup totals, not promise detailed live points for every individual player. We should verify actual Sleeper responses during implementation before expanding the feature description.

## Authentication and configuration

There will be no Sleeper login screen and no password, cookie, OAuth token, or API key.

The API is read-only and publicly queryable according to Sleeper's documentation. Configuration should contain identifiers and preferences only.

### Initial configuration

Recommended settings:

```text
userId          required
leagueId        required
refreshSeconds  optional; default 60
showOpponent    optional; default true
```

For beginner-friendly setup, a later iteration could accept a Sleeper username and resolve it to a user ID. The simplest first implementation should use the numeric `userId` and `leagueId` directly.

An example bar entry will eventually look like:

```json
{
  "id": "fantasy-ticker",
  "userId": "your-sleeper-user-id",
  "leagueId": "your-league-id",
  "refreshSeconds": 60,
  "showOpponent": true
}
```

This entry would be placed in one of the bar layout arrays in `~/.config/omarchy/shell.json`. That configuration change belongs to the implementation/install step and must not happen while this document-only phase is in progress.

## Update mechanism

The widget should use an asynchronous polling loop:

```text
startup
  → fetch current data
  → parse response
  → update QML properties
  → bar and popup redraw
  → timer waits for the refresh interval
  → fetch again
```

The popup should include a manual refresh action.

While a new request is running, the widget should keep displaying the last successful result. If a request fails, it should show a stale/offline indicator instead of erasing useful data.

The widget should prevent overlapping requests. A manual refresh should not start a second request while one is already in progress.

## First implementation milestones

Build in this order:

1. Create a static bar widget displaying `Fantasy Ticker`.
2. Add a valid manifest and confirm Omarchy can discover it.
3. Add inline configuration for `userId`, `leagueId`, and refresh interval.
4. Fetch NFL state and one league matchup.
5. Display a compact result such as:

   ```text
   My Team 82.4 — Opponent 76.8
   ```

6. Add a popup showing league name, week, team names, both scores, last updated time, and status.
7. Add periodic polling and a manual refresh button.
8. Add parser tests using fixture JSON.
9. Improve error handling and text truncation.
10. Only afterward consider player details, injuries, multiple leagues, notifications, or richer visuals.

## Potential problems and safeguards

### API and data problems

- Usernames can change; prefer numeric user IDs.
- The NFL can be in preseason, regular season, postseason, or offseason.
- A league may not have an active matchup.
- Scores may be missing or null before games begin.
- `owner_id`, `roster_id`, and `matchup_id` have different meanings.
- League formats and scoring settings vary.
- API response fields may be missing, null, or changed in the future.
- Sleeper may return HTTP 400, 404, 429, 500, or 503 responses.
- The public API may not provide the player-level live stats desired for a future release.

### Network and shell stability

- Requests must be asynchronous so the Omarchy shell does not freeze.
- Requests need connection and total-operation timeouts.
- Polling must be slow enough to avoid rate limiting.
- Requests should be bounded in size before output is collected.
- Overlapping requests must be prevented.
- The last successful data should remain visible during transient failures.
- Error messages should be useful but compact.

### Security and robustness

- Plugins run as unsandboxed code inside `omarchy-shell`.
- API hosts and URL paths should be allowlisted rather than assembled from arbitrary response data.
- User-controlled settings must be validated before being placed into a command or URL.
- Remote text should be length-limited, single-line where appropriate, and rendered safely.
- No secrets should be collected or stored.
- The full player database should not be fetched on every timer tick.

### User interface

- The bar has limited width; long league and team names need truncation.
- The widget needs clear loading, stale, offline, unconfigured, and offseason states.
- The widget should remain readable in both horizontal and vertical bar orientations.
- The popup should contain details that do not fit in the bar.

## Decisions still deferred

These are intentionally not part of the first implementation:

- Multiple leagues.
- Automatic league discovery and league picker UI.
- Multiple fantasy sports.
- Player-by-player live scoring.
- Injury/news feeds.
- Notifications when a game starts or a player scores.
- Persistent local caching beyond what is needed for stale display.
- A separate headless `Service.qml` shared by multiple widgets.
- Packaging or publishing the plugin.

## Definition of success for version one

Version one is successful when a configured user can place Fantasy Ticker in the Omarchy bar and see the current NFL matchup score update without freezing the shell, while receiving a clear and safe status message when configuration, network access, or Sleeper data is unavailable.

