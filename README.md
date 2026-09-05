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

## Configuration

Each user supplies their own Sleeper IDs in the Fantasy Ticker entry in their
Omarchy shell configuration file:

```text
~/.config/omarchy/shell.json
```

Find the bar layout section containing `fantasy-ticker` and add `userId`,
`leagueId`, and optionally `refreshSeconds` to that entry:

```json
{
  "id": "fantasy-ticker",
  "userId": "YOUR_SLEEPER_USER_ID",
  "leagueId": "YOUR_SLEEPER_LEAGUE_ID",
  "refreshSeconds": 60
}
```

`userId` identifies your Sleeper account. `leagueId` identifies the Sleeper
fantasy league whose matchup should be displayed. You can find these values
from Sleeper's public API or from the setup instructions for your league.

`refreshSeconds` controls how often the widget checks for updated scores. The
default and recommended value is `60`, meaning once per minute.

Neither `userId` nor `leagueId` is a password or an API token. They are public
identifiers used to select the Sleeper account and league. Do not put your
personal IDs into the plugin repository; keep them in your local
`~/.config/omarchy/shell.json` file.

Repository copies should use placeholders instead of personal IDs:

```text
userId:   YOUR_SLEEPER_USER_ID
leagueId: YOUR_SLEEPER_LEAGUE_ID
```

## Local development

The project source is in `/home/kec/my-plugin`. The installed copy is in `~/.config/omarchy/plugins/fantasy-ticker/`. The bar configuration is in `~/.config/omarchy/shell.json`.
