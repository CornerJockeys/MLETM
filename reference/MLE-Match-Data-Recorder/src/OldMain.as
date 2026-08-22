void Main(){
    InitializeDb();
    startnew(LoadTextures);
    startnew(MonitoringLoop);
    startnew(MonitorLastInServerTime);
}

string currServerName;
string currServerLogin;
string currGameMode;
string currMapUid;
string currMapName;
uint serverConnectStart;
string serverConnectStartStr;
bool isTeams;
bool isKO;
bool isCup;
bool isRounds;
bool isGoodMode;

// reset to true on server change
bool shouldKeepRecordingThisRound = true;


/**
 * Main monitoring loop.
 * Detect a server connection when the server login string is populated.
 * While we are connected to the same server, the server loop runs.
 * In the server loop, we check for the game mode (which can be updated between maps).
 * Inside that, we have the recording loop. This is active for the same server with the same mode.
 * This calls the UpdateLoopInServer function (which sometimes takes 1 frame, and sometimes yields to wait for certain conditions).
 * We also have a not-recording loop, to pause recording while we're connected to a server but shouldKeepRecordingThisRound is false.
 */
void MonitoringLoop() {
    auto app = GetApp();
    auto net = app.Network;
    auto si = cast<CTrackManiaNetworkServerInfo>(net.ServerInfo);
    while (true) {
        yield();
        if (!S_Enabled) continue;
        currServerLogin = si.ServerLogin;
        currServerName = si.ServerName;
        if (si.ServerLogin.Length == 0) continue;
        trace("Starting server login watch loop, login: " + currServerLogin + currServerLogin.Length);
        shouldKeepRecordingThisRound = currServerLogin.Length > 0;
        if (shouldKeepRecordingThisRound) startnew(OnJoinServer);
        isGoodMode = false;
        serverConnectStart = Time::Stamp;
        serverConnectStartStr = app.OSLocalDate.Replace("/", "-").Replace(":", "_");
        // the server loop
        while (si.ServerLogin == currServerLogin && S_Enabled) {
            currGameMode = si.ModeName;
            isTeams = S_RecordTeams && currGameMode.StartsWith("TM_Teams");
            isKO = S_RecordKO && currGameMode.StartsWith("TM_Knockout");
            isCup = S_RecordCup && currGameMode.StartsWith("TM_Cup");
            isRounds = S_RecordRounds && currGameMode.StartsWith("TM_Rounds");
            isGoodMode = isTeams || isKO || isCup || isRounds;
            trace("Starting game mode watch loop");
            // the recording loop
            while (si.ServerLogin == currServerLogin && currGameMode == si.ModeName && shouldKeepRecordingThisRound) {
                if (isGoodMode) UpdateLoopInServer();
                yield();
            }

            while (!shouldKeepRecordingThisRound && si.ServerLogin == currServerLogin) yield();

            yield();
        }
    }
}

uint lastInServerTime;
// Keeps track of whether we're in a server so we can autohide the post-game helper window.
void MonitorLastInServerTime() {
    auto app = GetApp();
    if (app.Network.ServerInfo is null) NotifyWarning("Network SI null!");
    while (app.Network.ServerInfo is null) yield();
    auto si = cast<CTrackManiaNetworkServerInfo>(app.Network.ServerInfo);
    while (true) {
        if (!isGoodMode) {
            sleep(200);
            continue;
        }
        if (si.ServerLogin.Length > 0) lastInServerTime = Time::Now;
        yield();
    }
}

void StartRecordingIfDisabled() {
    shouldKeepRecordingThisRound = true;
    UpdateMatchLog();
}

void PauseRecording() {
    shouldKeepRecordingThisRound = false;
}

uint joinServerNonce;
void OnJoinServer() {
    if (!shouldKeepRecordingThisRound) return;
    uint myNonce = Math::Rand(0, 1000000000);
    joinServerNonce = myNonce;
    while (!StillInServer(GetApp())) yield();
    if (joinServerNonce != myNonce) return;
    isTeams = currGameMode.StartsWith("TM_Teams");
    isKO = currGameMode.StartsWith("TM_Knockout");
    isCup = currGameMode.StartsWith("TM_Cup");
    isRounds = currGameMode.StartsWith("TM_Rounds");

    if (ShouldPromptWhenJoining(currGameMode)) {
        trace('on join server should prompt');
        UpdateMatchLog();
        ShowMatchRecorderPrompt();
    }
}

void RenderInterface() {
    if (!S_Enabled) return;
    RenderMatchLogUI();
    if (S_ShowRecordingUI) RenderRecordingUI();
}

const string PluginName = Meta::ExecutingPlugin().Name;
const string MenuLabel = "\\$f28" + Icons::AngleUp + Icons::Circle + "\\$z " + Meta::ExecutingPlugin().Name;

/** Render function called every frame intended only for menu items in `UI`.
*/
void RenderMenu() {
    auto cStart = UI::GetCursorPos();
    if (UI::BeginMenu(MenuLabel)) {
        if (UI::MenuItem("Enabled", "", S_Enabled)) {
            S_Enabled = !S_Enabled;
        }
        if (UI::MenuItem("Show Recording UI", "", S_ShowRecordingUI)) {
            S_ShowRecordingUI = !S_ShowRecordingUI;
        }
        if (UI::MenuItem("Open Log Folder", "", false)) {
            OpenExplorerPath(IO::FromStorageFolder(""));
        }
        UI::EndMenu();
    }
    auto cEnd = UI::GetCursorPos();
    if (logoTexture !is null) {
        UI::SetCursorPos(cStart + vec2(1, 0));
        UI::Image(logoTexture, vec2(UI::GetTextLineHeight()));
        UI::SetCursorPos(cEnd);
    }
}

string GenerateMatchName() {
    return FileNameSafe(serverConnectStartStr + " - " + StripFormatCodes(currServerName));
}

// string FileNameSafe(const string &in filename) {
//     return filename.Replace("|", "")
//         .Replace(":", "")
//         .Replace("#", "")
//         .Replace("?", "")
//         .Replace("*", "")
//         .Replace(":", "")
//         .Replace("\"", "")
//         .Replace("<", "")
//         .Replace(">", "")
//         .Replace("/", "")
//         .Replace("\\", "");
// }

string FileNameSafe(const string &in filename) {
    auto x = filename.Replace("|", "").Replace(":", "").Replace("#", "");
    x = x.Replace("?", "").Replace("*", "").Replace(":", "");
    x = x.Replace('"', "").Replace("<", "").Replace(">", "");
    return x.Replace("/", "").Replace("\\", "");
}

void UpdateLoopInServer() {
    auto app = cast<CGameManiaPlanet>(GetApp());
    // early exit if things aren't available
    if (app.RootMap is null || IsLoadingScreenShowing(app)) return;
    auto cmap = app.Network.ClientManiaAppPlayground;
    if (cmap is null) return;
    if (app.CurrentPlayground is null) return;
    // nothing to do in most UI sequences
    if (IsPlayingOrFinish(cmap)) return;

    // // if the start time is > the end time then we are in warmup;
    // if (!IsStartTimeLTEndTime(app)) return;

    // update map details;
    currMapName = StripFormatCodes(app.RootMap.MapInfo.Name);
    currMapUid = app.RootMap.EdChallengeId;
    // don't save stuff if the warmup is active
    if (MLFeed::GetTeamsMMData_V1().WarmUpIsActive) return;
    // if we hit a reason to save stats, do that
    if (IsEndRoundOrUiInteraction(cmap)) UpdateMatchLog();
    // wait for the map to change, or a loading screen to be present, etc.
    while (StillInServer(app) && IsEndRoundOrUiInteraction(cmap)) yield();
    // if the next UI sequence is Podium, update and save podium results
    if (StillInServer(app) && IsPodium(cmap)) UpdateMatchLog();
    while (StillInServer(app) && IsPodium(cmap)) yield();
}

bool IsStartTimeLTEndTime(CGameCtnApp@ app) {
    if (app.CurrentPlayground is null) return false;
    auto cp = cast<CSmArenaClient>(app.CurrentPlayground);
    if (cp.Arena is null || cp.Arena.Rules is null) return false;
    return cp.Arena.Rules.RulesStateStartTime < cp.Arena.Rules.RulesStateEndTime;
}

bool StillInServer(CGameCtnApp@ app) {
    return app.RootMap !is null && app.Network.ClientManiaAppPlayground !is null && !IsLoadingScreenShowing(app)
        && cast<CTrackManiaNetworkServerInfo>(app.Network.ServerInfo).ServerLogin.Length > 0;
}


bool IsLoadingScreenShowing(CGameCtnApp@ app) {
    return app.LoadProgress.State == NGameLoadProgress::EState::Displayed;
}

bool IsEndRoundOrUiInteraction(CGameManiaAppPlayground@ cmap) {
    if (cmap is null || cmap.UI is null) return false;
    auto seq = cmap.UI.UISequence;
    return seq == CGamePlaygroundUIConfig::EUISequence::EndRound || seq == CGamePlaygroundUIConfig::EUISequence::UIInteraction;
}

bool IsPlayingOrFinish(CGameManiaAppPlayground@ cmap) {
    if (cmap is null || cmap.UI is null) return false;
    auto seq = cmap.UI.UISequence;
    return seq == CGamePlaygroundUIConfig::EUISequence::Playing || seq == CGamePlaygroundUIConfig::EUISequence::Finish;
}

bool IsPodium(CGameManiaAppPlayground@ cmap) {
    if (cmap is null || cmap.UI is null) return false;
    auto seq = cmap.UI.UISequence;
    return seq == CGamePlaygroundUIConfig::EUISequence::Podium;
}
