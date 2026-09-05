# Fantasy Ticker

Omarchy bar widget for a single Sleeper NFL fantasy league.

## Current behavior

- Displays only `🏈` in the bar as the compact launcher.
- Uses `Fantasy Ticker` as the tooltip and popup title.
- Opens a small popup when clicked.
- Fetches the current NFL state, league rosters, and current-week matchups from Sleeper.
- Displays the user's matchup score and opponent's score.
- Shows loading and offline/error states.
- Keeps the last successful scores visible if a later refresh fails.
- Does not fetch player-level scoring, injuries, or multiple leagues.

## Planned configuration

The manifest records the development identifiers:

```text
userId:   YOUR_SLEEPER_USER_ID
leagueId: YOUR_SLEEPER_LEAGUE_ID
```

These values are identifiers, not passwords or API tokens. They are passed to the widget through its inline Omarchy bar configuration.

## Local development

The project source is in `/home/kec/my-plugin`. The installed copy is in `~/.config/omarchy/plugins/fantasy-ticker/`. The bar configuration is in `~/.config/omarchy/shell.json`.
