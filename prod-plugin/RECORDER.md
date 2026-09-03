# PROD Recorder Contract

Recorder schema version: **1**  
Introduced in PROD plugin **0.1.8**.

## Lifecycle

The recorder is event-driven rather than an end-of-round snapshot.

1. MLFeed `StartNewRace` changes after warmup / at the real race start.
2. PROD opens a round cache and freezes the participating player list and each player's Trackmania `TeamNum`.
3. Live player caches update throughout the round.
4. The current round is persisted on:
   - countdown / round open
   - checkpoint
   - respawn
   - player finish
   - round finalization
5. As soon as a player finishes, their player cache becomes immutable.
6. A later disconnect, despawn, map transition, or MLFeed cleanup cannot remove a frozen result.
7. Unfinished/disappeared players retain all data captured before disappearance and are finalized as unfinished rather than discarded.
8. Finalized rounds are deduplicated by deterministic `roundKey`.

If PROD is enabled/reloaded in the middle of an already-running race, it establishes the current `StartNewRace` value as a baseline and waits for the next countdown instead of pretending the partial race began normally.

## Identity and teams

Each player-round attempts to retain:

- `accountId` (`WebServicesUserId`) — preferred stable identity
- login
- displayed Trackmania name
- Trackmania `teamNum`

Team assignment is frozen at round open. If MLFeed later reports a different valid team for that player, the original team is retained and `capture.teamChangedDuringRound` is flagged.

League concepts such as TMID, MLE name, franchise, division, match number, or playoff round are intentionally not recorder responsibilities. Those are joined downstream.

## Player result data

Each player-round retains factual race data including:

- finished / DNF state
- disappearance flag
- finish position and finish time when available
- round points and observed total points
- race and respawn-adjusted ranks
- checkpoint times
- respawn count, timestamps, checkpoint counts, and time loss
- theoretical race time
- latency estimate

The recorder does **not** infer crashes or mistakes. For the playoff build, respawns are the only verified mistake-like event.

## Speed / position telemetry

When enabled, PROD samples each participating player's `CSmScriptPlayer` at the configured interval (default **100 ms / 10 Hz**) and stores rows as:

```text
[raceTimeMs, speedKph, x, y, z]
```

Telemetry is accumulated in memory and flushed to disk only on the gameplay persistence events above. It is **archive-only** for the playoff Google Sheets workflow; the Sheet ingestion payload should omit the high-frequency `telemetry.samples` array.

A telemetry failure must never invalidate otherwise valid checkpoint/result/respawn data.

## Files

Recorder storage root:

```text
Openplanet plugin storage / Recorder/
```

Current files:

- `current-round.json` — durable in-progress round cache
- `finalized-rounds/<roundKey>.json` — canonical finalized round copies
- `matches/<session>.json` — match/session archive grouped by map and round

The plugin menu includes **MLE TM PROD - Open Recorder Folder**.

## Round identity

`roundKey` is deterministic and currently built from:

```text
serverLogin | mapUid | rulesStartMs | StartNewRace
```

The same observed round therefore has the same key if a save/delivery operation is retried.

## Integrity

Unusual rounds are retained instead of silently dropped. Each round reports:

- participating players
- captured players
- expected league players (default 6)
- players with account IDs
- players with telemetry available
- whether a round result was observed
- `complete`

`complete` is currently an ingestion-safety signal based on seeing a round result and capturing the configured expected player count. Downstream systems may apply stricter validation.

## Not in 0.1.8 yet

- Google Apps Script delivery / retry queue
- Google Sheet parser
- automatic rehydration of an interrupted `current-round.json` after plugin restart
- replay/API verification
- crash inference
