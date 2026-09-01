# MLE TM PROD Plugin

Playoff-focused production plugin for MLE Trackmania.

## Current focus

1. Broadcast overlay.
2. PROD whitelist gating for advanced statistics.

## Phase 1 / pre-live test harness

The current build is intentionally simulation-driven so the full visual shell can be tested in one Openplanet session before live race data is wired in.

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
- Spectated-player indicator.
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
- Cycle the spectated player.
- Swap record values.
- Reset the complete demo state.

This lets one test session exercise most visual states without editing files or restarting the plugin for each case.

## Asset status

Team PNGs are intentionally not loaded yet. Binary logo assets and the external overlay/theme folder will be added after the first in-game layout/compile test confirms the rendering shell behaves correctly.

## Structure

- `src/Main.as` — plugin entry points.
- `src/Core/ProdState.as` — shared runtime state.
- `src/Core/MatchState.as` — current/manual match presentation state.
- `src/Core/LiveRankingState.as` — simulated six-player ranking state.
- `src/Core/RecordsState.as` — simulated WR state.
- `src/Access/ProdWhitelist.as` — authorization boundary for advanced stats.
- `src/UI/ProdOverlay.as` — overlay rendering coordinator.
- `src/UI/MatchBanner.as` — top broadcast scoreboard/banner.
- `src/UI/LiveRanking.as` — six-player ranking preview.
- `src/UI/RecordsPanel.as` — WR widget.
- `src/UI/TestControls.as` — Openplanet-only simulation controls.
- `src/UI/Settings.as` — persistent overlay/test settings.

Advanced statistics remain fail-closed until the whitelist check explicitly grants access.
