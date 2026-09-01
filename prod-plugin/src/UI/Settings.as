[Setting category="PROD Overlay" name="Show overlay"]
bool S_ShowProdOverlay = true;

[Setting category="PROD Overlay" name="Show match banner"]
bool S_ShowMatchBanner = true;

[Setting category="PROD Overlay" name="Show live ranking"]
bool S_ShowLiveRanking = true;

[Setting category="PROD Overlay" name="Show WR panel"]
bool S_ShowRecordsPanel = true;

[Setting category="PROD Overlay" name="Setup mode" description="Unlocks broadcast widgets for drag/resize. Disable before going live."]
bool S_LayoutSetupMode = false;

[Setting category="PROD Overlay" name="Show test controls"]
bool S_ShowTestControls = true;

[Setting category="PROD Theme" name="Enable local overlay overrides" description="Loads supported team/logo/theme overrides from the plugin storage Overlay folder when available. Bundled defaults remain the fallback."]
bool S_EnableLocalThemeOverrides = true;

[Setting category="PROD Live Data" name="Use live MLFeed race data" description="OFF by default. When enabled, current map, round score, player ordering and respawn state are sourced from MLFeed where available."]
bool S_UseLiveRaceData = false;

[Setting category="PROD Live Data" name="Team A is Trackmania Blue" description="Temporary side mapping until PROD resolves franchise sides from the MLE API."]
bool S_LiveTeamAIsBlue = false;

[Setting category="PROD Phase 1 Test Data" name="Division"]
string S_TestDivision = "CHAMPION LEAGUE";

[Setting category="PROD Phase 1 Test Data" name="Match label"]
string S_TestMatchLabel = "M7";

[Setting category="PROD Phase 1 Test Data" name="Map name"]
string S_TestMapName = "BATTERY";

[Setting category="PROD Phase 1 Test Data" name="Team A"]
string S_TestTeamAName = "FLAMES";

[Setting category="PROD Phase 1 Test Data" name="Team B"]
string S_TestTeamBName = "HURRICANES";

[Setting category="PROD Phase 1 Test Data" name="Team A map score"]
int S_TestTeamAMapScore = 1;

[Setting category="PROD Phase 1 Test Data" name="Team B map score"]
int S_TestTeamBMapScore = 0;

[Setting category="PROD Phase 1 Test Data" name="Team A round wins"]
int S_TestTeamARoundWins = 2;

[Setting category="PROD Phase 1 Test Data" name="Team B round wins"]
int S_TestTeamBRoundWins = 1;

[Setting category="PROD Phase 1 Test Data" name="Overall WR"]
string S_TestOverallWR = "0:41.686";

[Setting category="PROD Phase 1 Test Data" name="Division WR"]
string S_TestDivisionWR = "0:43.247";

// Persisted broadcast layout. These are intentionally hidden from the normal settings UI;
// setup mode and the PROD controls are the supported way to manipulate them.
[Setting hidden]
float S_BannerX = 580.0f;
[Setting hidden]
float S_BannerY = 0.0f;
[Setting hidden]
float S_BannerW = 760.0f;
[Setting hidden]
float S_BannerH = 86.0f;

[Setting hidden]
float S_RankingX = 14.0f;
[Setting hidden]
float S_RankingY = 48.0f;
[Setting hidden]
float S_RankingW = 300.0f;
[Setting hidden]
float S_RankingH = 250.0f;

[Setting hidden]
float S_RecordsX = 1640.0f;
[Setting hidden]
float S_RecordsY = 48.0f;
[Setting hidden]
float S_RecordsW = 260.0f;
[Setting hidden]
float S_RecordsH = 150.0f;
