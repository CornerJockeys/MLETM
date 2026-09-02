# Community Eligibility Card Normalization

These rules apply before either the Openplanet renderer or Discord renderer receives eligibility-card data.

## Scrim points

- `null` -> `0`
- missing -> `0`
- `0` -> `0`
- negative values -> invalid upstream data; do not silently display a negative value
- display format is always `<scrimPoints>/30` for the current ruleset
- values above 30 remain uncapped (for example `35/30`)

## Franchise staff

Accepted card values are `GM`, `AGM`, `CAPT`, or `null`.

When `null`, no franchise-staff stamp is rendered and the remaining top stamps retain their normal positions unless a later layout explicitly defines reflow.

## Status

The card's player-info table contains one `STATUS` row. Do not add separate franchise-role or eligible rows.

For an eligible player, display `Eligible`.

## Team frame

The player's team determines the eligibility-card frame/treatment through `teamFrameKey`. The renderer should not select a generic rarity frame.

## No rarity or tier in V1

Eligibility cards do not currently have rarity or medal/card-tier metadata. Those systems are reserved for the later collectible/career player-card implementation.
