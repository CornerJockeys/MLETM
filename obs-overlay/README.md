# MLE TM PROD OBS Overlay

This package is the broadcast-rendering prototype for MLE TM PROD.

The Openplanet PROD plugin remains responsible for Trackmania-facing data, recorder behavior, and eventual bridge/control messages. This package is responsible only for presentation.

## First milestone

- Fixed 1920x1080 broadcast canvas
- Larger match banner with angular cuts only at the two outer ends
- Team panels connect flush into the rectangular map-score core
- Round-win pips sit below the main colored banner instead of inside it
- Compact WR panel stacked above the live ranking on the left side
- Live ranking using MLE franchise colors and racing stripes after the timing column
- Cyan camera/spectated outline with a camera icon instead of `CAM`
- Team-color vs Red/Blue display mode
- Freeform match labels for regular season and playoff rounds (`M7`, `Quarterfinal`, `Semifinal`, `Grand Final`, etc.)
- Simulated match/ranking data
- Named operator actions that can later map to Stream Deck / Bitfocus Companion / OBS controls
- Optional team wordmark PNG slots

## Files

- `index.html` — transparent OBS browser-source renderer
- `control.html` — local operator/development preview
- `js/state.js` — simulated state + franchise palette
- `js/overlay.js` — renderer and action dispatcher
- `js/control.js` — preview control surface
- `css/overlay.css` — 1920x1080 broadcast layout
- `css/control.css` — preview/control UI

## Preview

Open `control.html` in a normal browser. It embeds `index.html` and exposes named actions such as:

- `TOGGLE_COLOR_MODE`
- `TOGGLE_WIDGET`
- `SET_MATCH_LABEL`
- `SCORE_DELTA`
- `ROUND_DELTA`
- `SWAP_TEAMS`
- `NEXT_SPECTATED`
- `TOGGLE_RESPAWN`
- `SHUFFLE_RANKING`
- `NEXT_MAP`

The control page is intentionally a prototype. It uses `postMessage` to the embedded overlay and is not yet the final network/Stream Deck bridge.

## OBS

For visual testing, add `index.html` as a local Browser Source and set the browser-source size to **1920 x 1080**. The page background is transparent.

The production renderer intentionally assumes a 1080p broadcast canvas. OBS can scale the complete source when needed; individual widgets do not reflow independently.

## Assets

The prototype temporarily points at the existing low-resolution logos in `../prod-plugin/assets/teams/` so the layout can be tested immediately.

Before production use, place the new high-resolution team logos and team-name/wordmark PNGs under `obs-overlay/assets/` and update the paths in `js/state.js`.

Wordmarks are optional. When a team's `wordmark` path is blank or fails to load, the overlay falls back to clean HTML text with **no shadow effect**.

Suggested structure:

```text
obs-overlay/assets/
├── teams/
│   ├── Dodgers.png
│   ├── Flames.png
│   └── ...
└── wordmarks/
    ├── Dodgers.png
    ├── Flames.png
    └── ...
```

Use transparent PNGs with enough source resolution for a 1920x1080 broadcast.

## Color modes

`team` uses the official MLE TM franchise palette.

`redBlue` maps the current Team A to broadcast blue and Team B to broadcast red, including the live-ranking rows. The demo controls also remap simulated ranking players when a team selection changes so the color-mode preview remains accurate for every franchise pairing.

This is deliberately a presentation setting; it does not redefine Trackmania's factual `TeamNum` values in the recorder.

## Next integration step

Replace simulated state with a small local bridge fed by the PROD plugin. The browser renderer should continue to receive the same state/action concepts so visual code remains independent of Openplanet and recorder internals.
