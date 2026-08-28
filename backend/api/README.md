# MLE TM API

This directory is the source of truth for the Cloudflare Worker that exposes the MLE Trackmania backend API.

## Runtime

- Cloudflare Worker name: `mle-tm-temp-api`
- Worker entry point: `src/index.js`
- Temporary data source: generated repository snapshots under `backend/data/`

Cloudflare is the runtime. The code and configuration in this directory are the canonical copy that should be changed first and then deployed.

## API v1

### Health

- `GET /v1/health`

### Players

- `GET /v1/players/account/:accountId`
- `GET /v1/players/discord/:discordId`
- `GET /v1/players/tmid/:tmid`

Trackmania account ID remains the canonical Trackmania identity. Discord ID is the canonical Discord identity used for bot/player resolution. Discord usernames are not used for identity matching.

### Teams

- `GET /v1/teams`

### Maps and leaderboards

- `GET /v1/maps/:mapUid`
- `GET /v1/maps/:mapUid/leaderboards/:division`

## Temporary scrim runtime archive

During development, the scrim bot can persist lifecycle artifacts through the Worker:

- `POST /v1/runtime/scrims/:scrimUid/session`
- `POST /v1/runtime/scrims/:scrimUid/submission`
- `POST /v1/runtime/scrims/:scrimUid/result`

The Worker wraps the submitted payload and writes it to `runtime/scrims/<scrimUid>/<artifact>.json` on the repository `main` branch. This is temporary storage until the permanent database is ready.

The endpoint requires two Cloudflare Worker secrets:

- `MLETM_WRITE_TOKEN`: shared bearer token used by trusted MLETM bot processes.
- `GITHUB_RUNTIME_TOKEN`: fine-grained GitHub token with Contents read/write access to this repository.

Neither secret belongs in the repository or plugin.

## Temporary compatibility routes

The previous unversioned routes remain available for the current plugin/leaderboard implementation while consumers migrate to `/v1`:

- `GET /health`
- `GET /teams`
- `GET /players/:accountId`
- `GET /maps/:mapUid`
- `GET /maps/:mapUid/leaderboards/:division`

New consumers should use `/v1` routes.

## Temporary storage

The current Worker imports generated JSON snapshots from `backend/data/`. This is intentional for development and beta work and can later be replaced by the permanent database without changing the public API contract.

Current snapshots include:

- `players.json`
- `maps.json`
- `map-records.json`
- `club-tags.json`

Runtime scrim artifacts are stored separately under `runtime/scrims/` so writes do not touch the Worker deployment source tree.

## Next backend slices

Planned consumers and extensions include:

1. Discord player fallback resolution by Discord ID.
2. Scrim/match creation contracts.
3. Replay submission and manual Discord upload flow.
4. Verification orchestration, including Nadeo Live Match evidence.
5. Replay parser integration.
6. Recorder submissions.
7. Admin tooling.
