# MLE TM Community Player Card

Shared specification and assets for the MLE TM Community player-card system.

This directory is intentionally outside `com-plugin/` and `bot/` so both Openplanet and Discord consumers can use the same data contract and visual definitions.

## Consumers

- `com-plugin/` — in-game Community plugin player profiles/cards
- `bot/scrims/` — Discord `!player <name>` card generation and scrim-point integration

## Ownership

- The scrim bot owns scrim-point updates.
- The backend/profile layer owns canonical player identity and profile data.
- Renderers consume normalized card data; they do not recalculate league stats.

## Scrim points

`null`, missing, or zero scrim points normalize to `0`. Cards always display the value as `X/30`.

## Card direction

The current mockup direction uses a modular layered card: base/background, card-tier tint, team/franchise assets, division stamp, season stamp, optional franchise-staff stamp, salary block, player identity table, team logo, and scrim-points block.

The medal/card tier should be expressed visually through the card treatment/tint rather than printed as a tier label.
