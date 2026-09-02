# Player Card Integration

The scrim bot is the Discord-side consumer of the shared MLE TM Community player-card system.

## Command target

`!player <MLE name>` should resolve the requested player, fetch/assemble the normalized Community player-card profile, render a PNG, and send it to Discord.

## Scrim-point ownership

The scrim bot owns scrim-point updates because scrim points are earned through the scrim system. The player-card renderer does not calculate scrim points.

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

The Discord implementation should render from the same normalized profile data as COM rather than maintaining a separate card schema.

## Rendering direction

Prefer deterministic image composition (SVG/canvas/Sharp-style layered rendering) over generated images. Player-specific text and assets should be placed onto reusable card layers at request time.
