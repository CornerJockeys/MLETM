namespace MatchState {
    string Division = "CHAMPION LEAGUE";
    string MatchLabel = "M7";
    string MapName = "BATTERY";

    string TeamAName = "FLAMES";
    string TeamBName = "HURRICANES";

    int TeamAMapScore = 1;
    int TeamBMapScore = 0;
    int TeamARoundWins = 2;
    int TeamBRoundWins = 1;

    vec4 TeamAPrimary = vec4(0.788f, 0.165f, 0.024f, 0.97f);
    vec4 TeamASecondary = vec4(0.965f, 0.769f, 0.196f, 1.0f);
    vec4 TeamBPrimary = vec4(0.000f, 0.314f, 0.188f, 0.97f);
    vec4 TeamBSecondary = vec4(0.957f, 0.451f, 0.129f, 1.0f);
    vec4 DivisionColor = vec4(0.494f, 0.333f, 0.808f, 1.0f);

    int ClampRoundWins(int value) {
        if (value < 0) return 0;
        if (value > 5) return 5;
        return value;
    }

    vec4 ResolvePrimaryColor(const string &in teamName) {
        string key = teamName.ToUpper();
        if (key == "FLAMES") return vec4(0.788f, 0.165f, 0.024f, 0.97f);
        if (key == "HURRICANES") return vec4(0.000f, 0.314f, 0.188f, 0.97f);
        return vec4(0.12f, 0.13f, 0.15f, 0.97f);
    }

    vec4 ResolveSecondaryColor(const string &in teamName) {
        string key = teamName.ToUpper();
        if (key == "FLAMES") return vec4(0.965f, 0.769f, 0.196f, 1.0f);
        if (key == "HURRICANES") return vec4(0.957f, 0.451f, 0.129f, 1.0f);
        return vec4(0.90f, 0.90f, 0.90f, 1.0f);
    }

    vec4 ResolveDivisionColor(const string &in divisionName) {
        string key = divisionName.ToUpper();
        if (key == "CL" || key == "CHAMPION" || key == "CHAMPION LEAGUE") {
            return vec4(0.494f, 0.333f, 0.808f, 1.0f);
        }
        if (key == "AL" || key == "ACADEMY" || key == "ACADEMY LEAGUE") {
            return vec4(0.000f, 0.522f, 0.980f, 1.0f);
        }
        if (key == "ML" || key == "MASTER" || key == "MASTER LEAGUE") {
            return vec4(0.820f, 0.000f, 0.341f, 1.0f);
        }
        return vec4(0.122f, 0.749f, 0.361f, 1.0f);
    }

    void SyncFromSettings() {
        Division = S_TestDivision;
        MatchLabel = S_TestMatchLabel;
        MapName = S_TestMapName;

        TeamAName = S_TestTeamAName;
        TeamBName = S_TestTeamBName;

        TeamAMapScore = S_TestTeamAMapScore < 0 ? 0 : S_TestTeamAMapScore;
        TeamBMapScore = S_TestTeamBMapScore < 0 ? 0 : S_TestTeamBMapScore;
        TeamARoundWins = ClampRoundWins(S_TestTeamARoundWins);
        TeamBRoundWins = ClampRoundWins(S_TestTeamBRoundWins);

        TeamAPrimary = ResolvePrimaryColor(TeamAName);
        TeamASecondary = ResolveSecondaryColor(TeamAName);
        TeamBPrimary = ResolvePrimaryColor(TeamBName);
        TeamBSecondary = ResolveSecondaryColor(TeamBName);
        DivisionColor = ResolveDivisionColor(Division);
    }

    void Initialize() {
        SyncFromSettings();
        trace("MLE TM PROD manual match state initialized.");
    }
}
