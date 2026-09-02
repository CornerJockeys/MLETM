# Eligibility Card Integration

The scrim bot is the Discord-side consumer of the shared MLE TM Community eligibility-card system.

## Command target

`!player <MLE name>` should resolve the requested player, fetch/assemble the normalized Community eligibility profile, render a PNG, and send it to Discord.

This V1 is an **eligibility/status card**, not the future collectible/career player-card system.

## Scrim-point ownership

The scrim bot owns scrim-point updates because scrim points are earned through the scrim system. The eligibility-card renderer does not calculate scrim points.

Before rendering:

```js
const scrimPoints = raw.scrimPoints ?? 0;
```

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

Alert detection/delivery should remain separate from the card renderer, but both should consume the same canonical player/profile data so an alert and a subsequently requested `!player` card cannot disagree about current state.
