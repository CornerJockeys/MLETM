[Setting category="PROD Recorder" name="Enable match recorder" description="Records official team rounds after the race countdown completes. Requires MLFeedRaceData and MLHook."]
bool S_RecorderEnabled = false;

[Setting category="PROD Recorder" name="Capture speed/position telemetry" description="Samples each participating player's speed and position in memory and flushes it on countdown, checkpoint, respawn, finish, and round finalization events."]
bool S_RecorderCaptureTelemetry = true;

[Setting category="PROD Recorder" name="Telemetry sample interval (ms)" min=50 max=1000 description="100 ms = 10 Hz. Telemetry is archive-only for the playoff build and is not intended for Google Sheets ingestion."]
int S_RecorderTelemetryIntervalMs = 100;

[Setting category="PROD Recorder" name="Expected league players" min=1 max=16 description="Used only for integrity reporting. The recorder still saves unusual/incomplete rounds instead of discarding them."]
int S_RecorderExpectedLeaguePlayers = 6;

[Setting category="PROD Recorder" name="Player disappearance grace (ms)" min=250 max=5000 description="How long a live participant may be missing from MLFeed before the recorder flags them as disappeared. Cached data is retained either way."]
int S_RecorderDisappearGraceMs = 1000;

[Setting category="PROD Recorder" name="Round finalize delay (ms)" min=0 max=3000 description="Short delay after MLFeed reports the round winner so final team score/state can settle before the canonical round is written."]
int S_RecorderFinalizeDelayMs = 350;

[Setting category="PROD Recorder" name="Verbose recorder logging" description="Logs countdown/open/checkpoint/respawn/finish/disappearance/finalize events for playoff testing."]
bool S_RecorderDebugLogging = true;
