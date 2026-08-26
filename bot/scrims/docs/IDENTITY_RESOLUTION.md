# Player identity resolution

The scrim bot resolves players by Discord ID.

Resolution order:

1. Try the existing Sprocket/MLEDB Trackmania identity path using the Discord ID.
2. If Sprocket does not return a usable Trackmania player, query the MLETM API by the same Discord ID.
3. Normalize the result into the bot's local `Player` shape before queue/scrim logic consumes it.

Discord usernames/display names are presentation metadata only. They must not be used to find or match player identity.

The MLETM fallback uses the resolved Trackmania Account ID as Trackmania platform identity while preserving existing Sprocket linkage in local player state.

This identity fallback is intentionally isolated from replay submissions, parsing, verification, and the existing Sprocket-oriented match/result flow.
