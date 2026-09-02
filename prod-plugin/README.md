# MLE TM PROD Plugin

Playoff-focused production plugin for MLE Trackmania.

## Current focus

1. Broadcast overlay and operator controls.
2. PROD whitelist gating for advanced statistics.
3. Production-safe customization without modifying match logic.

## Developer / simulation testing

The presentation shell is intentionally usable without an online room.

- `MLFeedRaceData` and `MLHook` are optional dependencies.
- If live telemetry is unavailable, PROD stays in simulation mode instead of failing to load.
- The actual broadcast HUD renders through `RenderInterface()`.
- Operator/test controls render separately through the Openplanet overlay.
- `Plugins > MLE TM PROD - Test Controls` provides an explicit way to confirm the plugin loaded from the main menu or local play.
- Turning on live MLFeed while no supported playground is active falls back to simulation safely.

This separation is deliberate so graphics/layout/theme work can be tested in Developer mode without requiring an online match room.

## Match banner

- Movable/resizable top match banner.
- Team primary/secondary franchise colors.
- Team map score.
- Five round-win indicators per team.
- Division / match / map metadata rail.
- Transparent team-logo loader with local override support and bundled fallback paths.

Default simulation matchup is Flames vs Hurricanes, Champion League, M7, Battery.

## Live ranking

- Persistent identity-based player rows.
- Adjustable visible ranking count: `Auto` or fixed 1-16 positions; default is 6.
- MLFeed buffers up to 16 eligible racers so top-N cutoff changes can animate cleanly.
- Team-color racing accents.
- Respawn indicator.
- Spectated-player indicator placeholder/simulation.
- Animated position changes.
- Position-loss animation enlarges the affected row, moves it downward, then returns it to normal size.

## Records

- Overall WR widget.
- Division WR widget with AL / CL / ML presentation.
- Manual/simulation values currently; backend record source is still to be wired.

## Layout / operator controls

- Setup Mode unlocks broadcast widgets for drag/resize.
- Live Mode locks widgets against accidental interaction.
- Layout positions/sizes persist between sessions.
- Approved 1920x1080 defaults can be restored from the test controls.
- Configurable hotkeys currently cover master overlay, chat, Setup/Live, banner, ranking and WR panel.

## Local chat control

PROD uses Trackmania's local `OverlayHideChat` UI state. It captures the original value before hiding chat and restores that original value when chat is re-enabled or PROD unloads. It does not mute the room or change server chat permissions.

## Theme / asset overrides

PROD creates a user-editable plugin-storage `Overlay/` directory.

- `Overlay/theme.json` supports validated team-color overrides.
- `Overlay/teams/<Team>.png` overrides a bundled franchise logo.
- Missing/invalid overrides fall back to official bundled defaults.
- The test panel exposes `Open Overlay folder` and `Reload theme/assets` controls.

Bundled official logo paths are:

- `assets/teams/Dodgers.png`
- `assets/teams/Flames.png`
- `assets/teams/Hive.png`
- `assets/teams/Hurricanes.png`
- `assets/teams/Jets.png`
- `assets/teams/Sabres.png`
- `assets/teams/Spectre.png`
- `assets/teams/Wizards.png`

The PNG files themselves still need to be committed to those paths; the loader and fallback contract are already implemented.

## Live MLFeed mode

When the optional dependencies are installed and a supported playground is active, PROD can source:

- Current Trackmania map name.
- Team round wins from MLFeed team data.
- Eligible team racers from `SortedPlayers_Race_Respawns`.
- Live race ordering.
- Player names / stable WebServices identity where available.
- Team side from Trackmania `TeamNum`.
- Respawn presence from `NbRespawnsRequested`.
- Same-checkpoint time gaps when available.

Until the MLE API resolves franchise sides automatically, `Team A = Trackmania Blue` manually maps Team A to Trackmania Blue or Red. Map-series score, franchise names, division/match metadata and WR values remain MLE/manual state for now.

## Structure

- `src/Main.as` — lifecycle, interface render, operator menu and hotkeys.
- `src/Core/ProdState.as` — shared runtime initialization.
- `src/Core/TeamTheme.as` — official franchise/division palette and logo paths.
- `src/Core/OverlayTheme.as` — external theme/logo override loader.
- `src/Core/LayoutState.as` — persistent Setup/Live widget layout.
- `src/Core/MatchState.as` — current/manual match presentation state.
- `src/Core/LiveRankingState.as` — identity-preserving ranking and animation state.
- `src/Core/RecordsState.as` — WR state.
- `src/Core/LiveDataSource.as` — optional MLFeed race adapter.
- `src/Core/ChatVisibility.as` — safe local chat visibility control.
- `src/Core/ProdHotkeys.as` — broadcast hotkey actions.
- `src/Access/ProdWhitelist.as` — authorization boundary for advanced stats.
- `src/UI/ProdOverlay.as` — state/render coordinator.
- `src/UI/MatchBanner.as` — top broadcast scoreboard/banner.
- `src/UI/LiveRanking.as` — ranking widget.
- `src/UI/RecordsPanel.as` — WR widget.
- `src/UI/TestControls.as` — Openplanet-only simulation/live controls.
- `src/UI/Settings.as` — persistent settings.

Advanced statistics remain fail-closed until the whitelist check explicitly grants access.
