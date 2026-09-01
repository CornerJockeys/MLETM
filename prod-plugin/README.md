# MLE TM PROD Plugin

Playoff-focused production plugin for MLE Trackmania.

## Initial priorities

1. In-game PROD overlay.
2. PROD whitelist gating for advanced statistics.

## Skeleton

- `src/Main.as` — plugin entry points.
- `src/Core/ProdState.as` — shared runtime state.
- `src/Access/ProdWhitelist.as` — authorization boundary for advanced stats.
- `src/UI/ProdOverlay.as` — overlay rendering surface.
- `src/UI/Settings.as` — user-facing overlay settings.

Advanced statistics are fail-closed: they remain unavailable until the whitelist check explicitly grants access.
