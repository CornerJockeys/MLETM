# MLE TM PROD Plugin

Playoff-focused production plugin for MLE Trackmania.

## Current focus

1. Broadcast overlay.
2. PROD whitelist gating for advanced statistics.

## Pre-live test build

The current build is designed so the presentation shell can be exercised in one Openplanet session before the real MLE match/API flow is complete.

### Match banner

- Movable and resizable top match banner.
- Flames vs Hurricanes default test matchup.
- Champion League / M7 / Battery metadata rail.
- Team map score.
- Five round-win slots per team.
- Flames and Hurricanes franchise colors with secondary accents.

### Live ranking preview

- Six persistent player rows.
- Team-color row accents.
- Spectated-player simulation indicator.
- Respawn indicator.
- Placement-change simulation controls.

The current simulation changes ordering immediately. Animated row movement is the next ranking step after the first in-game render is validated.

### Records preview

- Overall WR panel.
- Division WR panel with AL / CL / ML labeling and division color.
- Simulated record-value switching.

### PROD test controls

`MLE TM PROD - Test Controls` appears only while the Openplanet overlay is open. It can:

- Toggle the master overlay, banner, live ranking, and WR panel independently.
- Cycle AL / CL / ML presentation.
- Cycle the current test map.
- Swap Flames and Hurricanes.
- Increment/decrement map and round scores.
- Simulate ranking changes.
- Toggle respawn indicators.
- Cycle the simulated spectated player.
- Swap record values.
- Reset the complete demo state.

### Dormant live MLFeed mode

`Use live MLFeed race data` is OFF by default. When enabled, the plugin currently attempts to source:

- Current Trackmania map name.
- Current team round wins from MLFeed `ClanScores`.
- Up to six active team racers from `SortedPlayers_Race_Respawns`.
- Live race ordering.
- Player names.
- Team side from Trackmania `TeamNum`.
- Respawn presence from `NbRespawnsRequested`.
- Same-checkpoint time gaps when available.

Until the MLE API resolves franchise sides automatically, `Team A = Trackmania Blue` manually maps the broadcast's Team A to Trackmania team 1 (Blue) or team 2 (Red). Map-series score, franchise names, division/match metadata and WR values remain manual/MLE-owned state.

If live race data is unavailable, the test panel reports that state without changing the default simulation switch.

## Asset status

Team PNGs are intentionally not loaded yet. Binary logo assets and the external overlay/theme folder will be added after the first in-game layout/compile test confirms the rendering shell behaves correctly.

## Structure

- `src/Main.as` — plugin entry points.
- `src/Core/ProdState.as` — shared runtime state.
- `src/Core/MatchState.as` — current/manual match presentation state.
- `src/Core/LiveRankingState.as` — simulated/live six-player ranking state.
- `src/Core/RecordsState.as` — WR state.
- `src/Core/LiveDataSource.as` — optional MLFeed race adapter.
- `src/Access/ProdWhitelist.as` — authorization boundary for advanced stats.
- `src/UI/ProdOverlay.as` — overlay rendering/data coordinator.
- `src/UI/MatchBanner.as` — top broadcast scoreboard/banner.
- `src/UI/LiveRanking.as` — six-player ranking preview.
- `src/UI/RecordsPanel.as` — WR widget.
- `src/UI/TestControls.as` — Openplanet-only simulation/live controls.
- `src/UI/Settings.as` — persistent overlay/test settings.

Advanced statistics remain fail-closed until the whitelist check explicitly grants access.
