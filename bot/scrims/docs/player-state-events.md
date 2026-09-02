# Player State Events and Future Webhooks

Player-state changes are recorded independently from Discord delivery. This keeps salary/eligibility logic canonical and lets multiple Discord servers consume the same events later.

## Event types

- `scrim_points_changed`
- `eligibility_gained`
- `eligibility_lost`
- `salary_changed`

Each event records the player, old value, new value, source, optional source reference, metadata, and timestamp.

## Current producers

Scrim-point mutations emit `scrim_points_changed`. Crossing the 30-point eligibility threshold also emits either `eligibility_gained` or `eligibility_lost` in the same transaction as the point update.

A valid completed scrim awards 5 points once per player. The `(scrim_id, player_id)` award key prevents duplicate awards if completion processing is retried.

Salary events are supported by the event service but should be emitted by the future canonical salary-sync/update path once that path is implemented.

## Future delivery layer

Webhook delivery should consume `player_state_events` rather than detecting changes itself. This allows any number of Discord destinations to subscribe without duplicating league rules.

Do not store raw Discord webhook URLs/tokens in ordinary configuration or event rows. A future subscription record should reference a protected credential/secret by identifier, or use another approved secret-storage mechanism.

Recommended delivery flow:

1. canonical player/scrim update occurs
2. state event is written
3. delivery worker reads undispatched relevant events
4. destination subscriptions are resolved
5. credentials are resolved securely
6. Discord payload is sent
7. delivery attempt/result is logged

Delivery failures must never roll back the underlying league data change.
