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

    vec4 TeamAPrimary;
    vec4 TeamASecondary;
    vec4 TeamBPrimary;
    vec4 TeamBSecondary;
    vec4 DivisionColor;

    int ClampRoundWins(int value) {
        if (value < 0) return 0;
        if (value > 5) return 5;
        return value;
    }

    vec4 ResolvePrimaryColor(const string &in teamName) {
        return TeamThemes::Primary(teamName);
    }

    vec4 ResolveSecondaryColor(const string &in teamName) {
        return TeamThemes::Secondary(teamName);
    }

    vec4 ResolveDivisionColor(const string &in divisionName) {
        return TeamThemes::DivisionColor(divisionName);
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
