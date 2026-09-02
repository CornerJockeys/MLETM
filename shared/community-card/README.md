# MLE TM Community Eligibility Card

Shared specification and assets for the MLE TM Community eligibility-card system.

This directory is intentionally outside `com-plugin/` and `bot/` so Openplanet and Discord consumers can use the same data contract and visual definitions.

## Current scope

The current card is an **eligibility card** used for player lookup/status display, especially the Discord `!player <name>` command. It is not yet the long-term collectible/career player-card system described in the S3 backlog.

## Consumers

- `com-plugin/` — future in-game Community eligibility/profile views
- `bot/scrims/` — Discord `!player <name>` eligibility-card generation and scrim-point integration

## Ownership

- The scrim bot owns scrim-point updates.
- The backend/profile layer owns canonical player identity, roster/salary/status data, and team affiliation.
- Renderers consume normalized eligibility-card data; they do not recalculate league stats.

## Scrim points

`null`, missing, or zero scrim points normalize to `0`. Cards always display the value as `X/30`, and values above 30 remain uncapped.

## Visual direction

Eligibility-card frames are **team specific**. The player's team selects the frame/treatment used by the renderer.

The current eligibility card has no rarity system and no medal/card-tier system. Those concepts belong to the future collectible/career card system and should not leak into this renderer yet.

The modular card is composed from team frame/background assets, team logo, division stamp, season stamp, optional franchise-staff stamp, salary block, player identity/status table, and scrim-points block.

## Future alerts

Salary and eligibility changes will eventually be able to trigger webhook alerts to configured Discord servers. Alert delivery is separate from image rendering, but should consume the same canonical player/status data so Discord cards and alerts cannot disagree.
