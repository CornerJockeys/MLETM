# Eligibility Card Integration

The scrim bot is the Discord-side consumer of the shared MLE TM Community eligibility-card system.

## Command target

The primary Discord interface is `/player name:<MLE name>` with API-backed autocomplete.

The command resolves the requested player, fetches/assembles the normalized Community eligibility profile, renders the eligibility card, and sends it to Discord. Until PNG output is wired, `/player` returns a temporary embed from the same normalized card data.

A legacy `!player <MLE name>` alias may be added later, but it should call the same profile and renderer services rather than maintain separate logic.

This V1 is an **eligibility/status card**, not the future collectible/career player-card system.

## Player lookup and autocomplete

Canonical exact lookup:

- `GET /v1/players/name/:mleName`

Autocomplete search:

- `GET /v1/players/search?q=<partial name>&limit=25`

Search considers both MLE and Trackmania names, while the slash-command option stores the canonical MLE name as its value.

## Scrim-point ownership

The scrim bot owns scrim-point updates because scrim points are earned through the scrim system. The eligibility-card renderer does not calculate scrim points.

Current intended rule:

- a valid completed scrim awards **5 scrim points per participating player**
- eligibility threshold is **30 points**
- the `(scrim_id, player_id)` award record is unique, so retries cannot award the same completion twice
- a valid queue-scrim completion requires the scrim to be active and all participating players to have checked in

`validScrimCompletionService.complete(scrimId)` is the canonical completion coordinator. Future replay-verifier/submission paths should call it after the scrim has been accepted as valid.

Before rendering, missing/null scrim points normalize to `0`.

The display is always `<scrimPoints>/30`. Do not cap values at 30; `35` renders as `35/30`.

## Shared contract

Use:

- `shared/community-card/player-card.schema.json`
- `shared/community-card/layout-v1.json`
- `shared/community-card/normalization.md`
- `shared/community-card/assets/`

The Discord implementation should render from the same normalized eligibility data as COM rather than maintaining a separate schema.

## Team-specific frames

Each team supplies its own eligibility-card frame/background treatment. The normalized profile provides `teamFrameKey`, and the renderer selects the matching team asset.

There is no rarity or medal/card-tier system in eligibility-card V1.

## Rendering direction

Prefer deterministic image composition (SVG/canvas/Sharp-style layered rendering) over generated images. Player-specific text and assets should be placed onto reusable card layers at request time.

## Future Discord webhook alerts

The scrim/bot ecosystem should later support configurable webhook delivery to multiple Discord servers for relevant player changes, including:

- eligibility/status changes
- salary changes

Alert detection/delivery should remain separate from the card renderer, but both should consume the same canonical player/profile data so an alert and a subsequently requested `/player` card cannot disagree about current state.
