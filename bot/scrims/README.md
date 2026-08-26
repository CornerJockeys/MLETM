# MLE TM Scrims Bot

Player-facing Discord bot for MLE Trackmania scrim queues, check-in, map selection, match creation, and related queue operations.

This codebase was imported from `Minor-League-Esports/tm-q-bot` and is being adapted to use the MLETM backend as the self-sufficient Trackmania data layer. The original upstream README is retained as `UPSTREAM_README.md`.

## Identity direction

Discord ID is the only authoritative Discord identity key. Discord usernames are display-only and must not be used for identity matching.

Player resolution should prefer the existing Sprocket/MLEDB source when it is usable, then fall back to the MLETM API by Discord ID.
