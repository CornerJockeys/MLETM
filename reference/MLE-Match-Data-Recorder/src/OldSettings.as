[Setting hidden] //category="General" name="Enabled"]
bool S_Enabled = true;

[Setting hidden] //category="General" name="Show Recording UI" description="Will show a window while recording when the openplanet interface is shown"]
bool S_ShowRecordingUI = true;

[Setting hidden] // category="Game Modes" name="Record Teams mode?"]
bool S_RecordTeams = true;
[Setting hidden] // category="Game Modes" name="Record KO mode?"]
bool S_RecordKO = false;
[Setting hidden] // category="Game Modes" name="Record Cup mode?"]
bool S_RecordCup = false;
[Setting hidden] // category="Game Modes" name="Record Rounds mode?"]
bool S_RecordRounds = false;

[Setting hidden] // category="Autoprompt" name="Prompt for Teams mode?"]
bool S_AutoPromptForTeams = true;
[Setting hidden] // category="Autoprompt" name="Prompt for KO mode?"]
bool S_AutoPromptForKO = false;
[Setting hidden] // category="Autoprompt" name="Prompt for Cup mode?"]
bool S_AutoPromptForCup = false;
[Setting hidden] // category="Autoprompt" name="Prompt for Rounds mode?"]
bool S_AutoPromptForRounds = false;

bool ShouldPromptWhenJoining(const string &in mode) {
    return S_AutoPromptForTeams && mode.StartsWith("TM_Teams")
        || S_AutoPromptForKO && mode.StartsWith("TM_Knockout")
        || S_AutoPromptForCup && mode.StartsWith("TM_Cup")
        || S_AutoPromptForRounds && mode.StartsWith("TM_Rounds")
     ;
}

[SettingsTab name="General" order=1 icon="Cogs"]
void Render_ST_GameModes() {
    if (logoTexture !is null) {
        auto imageSize = logoTexture.GetSize();
        auto cStart = UI::GetCursorPos();
        UI::Image(logoTexture);
        auto cEnd = UI::GetCursorPos();
        UI::PushFont(g_BigFont);
        auto height = UI::GetTextLineHeightWithSpacing();
        UI::SetCursorPos(cStart + vec2(imageSize.x + 10, (imageSize.y - height) / 2));
        UI::Text(PluginName);
        UI::PopFont();
        UI::SetCursorPos(cEnd);
        UI::Separator();
    }

    UI::AlignTextToFramePadding();
    UI::Text("General:");
    S_Enabled = UI::Checkbox("Enabled?", S_Enabled);
    S_ShowRecordingUI = UI::Checkbox("Show Recording UI?", S_ShowRecordingUI);
    UI::SameLine();
    UI::TextWrapped("\\$9e9This will show a small window while recording when the openplanet interface is shown.");

    UI::Separator();

    UI::AlignTextToFramePadding();
    UI::Text("Game Modes:");

    bool orig_S_RecordTeams = S_RecordTeams;
    S_RecordTeams = UI::Checkbox("Record Teams mode?", S_RecordTeams);
    if (orig_S_RecordTeams != S_RecordTeams) startnew(RecheckRecording);
    bool orig_S_RecordKO = S_RecordKO;
    S_RecordKO = UI::Checkbox("Record KO mode?", S_RecordKO);
    if (orig_S_RecordKO != S_RecordKO) startnew(RecheckRecording);
    bool orig_S_RecordCup = S_RecordCup;
    S_RecordCup = UI::Checkbox("Record Cup mode?", S_RecordCup);
    if (orig_S_RecordCup != S_RecordCup) startnew(RecheckRecording);
    bool orig_S_RecordRounds = S_RecordRounds;
    S_RecordRounds = UI::Checkbox("Record Rounds mode?", S_RecordRounds);
    if (orig_S_RecordRounds != S_RecordRounds) startnew(RecheckRecording);

    UI::Separator();

    UI::AlignTextToFramePadding();
    UI::Text("Autoprompt:");
    UI::AlignTextToFramePadding();
    UI::TextWrapped("\\$9e9This will prompt you to save or ignore the recording when joining a server with the selected mode.");

    bool orig_S_AutoPromptForTeams = S_AutoPromptForTeams;
    S_AutoPromptForTeams = UI::Checkbox("Prompt for Teams mode?", S_AutoPromptForTeams);
    if (orig_S_AutoPromptForTeams != S_AutoPromptForTeams) startnew(RecheckRecording);
    bool orig_S_AutoPromptForKO = S_AutoPromptForKO;
    S_AutoPromptForKO = UI::Checkbox("Prompt for KO mode?", S_AutoPromptForKO);
    if (orig_S_AutoPromptForKO != S_AutoPromptForKO) startnew(RecheckRecording);
    bool orig_S_AutoPromptForCup = S_AutoPromptForCup;
    S_AutoPromptForCup = UI::Checkbox("Prompt for Cup mode?", S_AutoPromptForCup);
    if (orig_S_AutoPromptForCup != S_AutoPromptForCup) startnew(RecheckRecording);
    bool orig_S_AutoPromptForRounds = S_AutoPromptForRounds;
    S_AutoPromptForRounds = UI::Checkbox("Prompt for Rounds mode?", S_AutoPromptForRounds);
    if (orig_S_AutoPromptForRounds != S_AutoPromptForRounds) startnew(RecheckRecording);
}


void RecheckRecording() {
    if (!isGoodMode) {
        currServerLogin = "";
    }
}


[SettingsTab name="Debug" order=99]
void Render_ST_Debug() {
    UI::Text("Logo:");
    if (logoTexture !is null) {
        auto imageSize = logoTexture.GetSize();
        UI::Image(logoTexture);
    } else {
        UI::Text("Loading... (null atm)");
    }
    UI::Separator();
    UI::Text("Footer:");
    UI::PushStyleColor(UI::Col::Border, vec4(1));
    // manually tweaked size to fit the footer
    if (UI::BeginChild("Footer", vec2(0, UI::GetTextLineHeightWithSpacing() * 2.7), true, UI::WindowFlags::AlwaysAutoResize)) {
        RenderUIFooter(false);
    }
    UI::EndChild();
    UI::Separator();
    UI::PopStyleColor(1);
}
