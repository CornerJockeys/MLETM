[Setting category="PROD Overlay" name="Show overlay"]
bool S_ShowProdOverlay = true;

[Setting category="PROD Overlay" name="Show match banner"]
bool S_ShowMatchBanner = true;

[Setting category="PROD Overlay" name="Banner preset" min=0 max=2 description="0 = PROD Broadcast, 1 = Community, 2 = Minimal."]
int S_BannerPreset = 0;

[Setting category="PROD Overlay" name="Lock banner aspect ratio" description="Keeps banner proportions intact while resizing in Setup mode."]
bool S_LockBannerAspect = true;

[Setting category="PROD Overlay" name="Show live ranking"]
bool S_ShowLiveRanking = true;

[Setting category="PROD Overlay" name="Ranking positions" min=0 max=16 description="Number of ranking positions to reserve/display. 0 = Auto (all active eligible racers, capped at 16). Default MLE 3v3 presentation is 6."]
int S_RankingRowCount = 6;

[Setting category="PROD Overlay" name="Show WR panel"]
bool S_ShowRecordsPanel = true;

[Setting category="PROD Overlay" name="Show MLE TM logo"]
bool S_ShowMleLogo = true;

[Setting category="PROD Overlay" name="Non-banner opacity" min=0.20 max=1.00 description="Transparency for ranking, WR and other non-banner broadcast panels."]
float S_NonBannerOpacity = 0.88f;

[Setting category="PROD Overlay" name="Setup mode" description="Unlocks broadcast widgets for drag/resize. Disable before going live."]
bool S_LayoutSetupMode = false;

[Setting category="PROD Overlay" name="Show test controls"]
bool S_ShowTestControls = true;

[Setting category="PROD Theme" name="Enable local overlay overrides" description="Loads supported team/logo/theme overrides from the plugin storage Overlay folder when available. Bundled defaults remain the fallback."]
bool S_EnableLocalThemeOverrides = true;

[Setting category="PROD Hotkeys" name="Enable broadcast hotkeys"]
bool S_EnableBroadcastHotkeys = true;

[Setting category="PROD Hotkeys" name="Master overlay"]
VirtualKey S_HotkeyMasterOverlay = VirtualKey::F7;

[Setting category="PROD Hotkeys" name="Hide / restore chat"]
VirtualKey S_HotkeyChat = VirtualKey::F8;

[Setting category="PROD Hotkeys" name="Setup / Live mode"]
VirtualKey S_HotkeySetupMode = VirtualKey::F9;

[Setting category="PROD Hotkeys" name="Match banner"]
VirtualKey S_HotkeyBanner = VirtualKey::F10;

[Setting category="PROD Hotkeys" name="Live ranking"]
VirtualKey S_HotkeyRanking = VirtualKey::F11;

[Setting category="PROD Hotkeys" name="WR panel"]
VirtualKey S_HotkeyRecords = VirtualKey::F12;

[Setting category="PROD Hotkeys" name="MLE TM logo"]
VirtualKey S_HotkeyMleLogo = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Next banner preset"]
VirtualKey S_HotkeyNextBannerPreset = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Fit layout to current resolution"]
VirtualKey S_HotkeyFitLayout = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Reset layout"]
VirtualKey S_HotkeyResetLayout = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Previous match number"]
VirtualKey S_HotkeyMatchPrev = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Next match number"]
VirtualKey S_HotkeyMatchNext = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Swap teams"]
VirtualKey S_HotkeySwapTeams = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Team A map score +"]
VirtualKey S_HotkeyTeamAMapPlus = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Team A map score -"]
VirtualKey S_HotkeyTeamAMapMinus = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Team B map score +"]
VirtualKey S_HotkeyTeamBMapPlus = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Team B map score -"]
VirtualKey S_HotkeyTeamBMapMinus = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Team A round +"]
VirtualKey S_HotkeyTeamARoundPlus = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Team A round -"]
VirtualKey S_HotkeyTeamARoundMinus = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Team B round +"]
VirtualKey S_HotkeyTeamBRoundPlus = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Team B round -"]
VirtualKey S_HotkeyTeamBRoundMinus = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Cycle ranking row count"]
VirtualKey S_HotkeyRankingRows = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Non-banner opacity +"]
VirtualKey S_HotkeyOpacityPlus = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Non-banner opacity -"]
VirtualKey S_HotkeyOpacityMinus = VirtualKey::None;

[Setting category="PROD Hotkeys" name="Reload presentation assets"]
VirtualKey S_HotkeyReloadAssets = VirtualKey::None;

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
float S_BannerX = 530.0f;
[Setting hidden]
float S_BannerY = 0.0f;
[Setting hidden]
float S_BannerW = 860.0f;
[Setting hidden]
float S_BannerH = 100.0f;

[Setting hidden]
float S_RankingX = 14.0f;
[Setting hidden]
float S_RankingY = 60.0f;
[Setting hidden]
float S_RankingW = 320.0f;
[Setting hidden]
float S_RankingH = 260.0f;

[Setting hidden]
float S_RecordsX = 1626.0f;
[Setting hidden]
float S_RecordsY = 60.0f;
[Setting hidden]
float S_RecordsW = 280.0f;
[Setting hidden]
float S_RecordsH = 150.0f;

[Setting hidden]
float S_LogoX = 1740.0f;
[Setting hidden]
float S_LogoY = 900.0f;
[Setting hidden]
float S_LogoW = 140.0f;
[Setting hidden]
float S_LogoH = 140.0f;
