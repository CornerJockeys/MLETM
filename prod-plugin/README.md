# MLE TM PROD Plugin

Playoff-focused production plugin for MLE Trackmania.

## Current focus

1. Broadcast overlay.
2. PROD whitelist gating for advanced statistics.

## Phase 1

Phase 1 establishes the first real broadcast widget using manual/test match data.

- Movable and resizable top match banner.
- Flames vs Hurricanes default test matchup.
- Champion League / M7 / Battery metadata rail.
- Team map score.
- Five round-win slots per team.
- Flames and Hurricanes franchise colors with secondary accents.
- Manual test values exposed through Openplanet settings.

The Phase 1 banner intentionally does not load team PNGs yet. Binary logo assets will be added after the first in-game layout/compile test.

## Structure

- `src/Main.as` — plugin entry points.
- `src/Core/ProdState.as` — shared runtime state.
- `src/Core/MatchState.as` — current/manual match presentation state.
- `src/Access/ProdWhitelist.as` — authorization boundary for advanced stats.
- `src/UI/ProdOverlay.as` — overlay rendering surface.
- `src/UI/MatchBanner.as` — top broadcast scoreboard/banner.
- `src/UI/Settings.as` — overlay and Phase 1 test settings.

Advanced statistics remain fail-closed until the whitelist check explicitly grants access.
