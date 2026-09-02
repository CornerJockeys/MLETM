namespace RecordsState {
    string OverallLabel = "OVERALL WR";
    string OverallTime = "0:41.686";
    string DivisionLabel = "CL WR";
    string DivisionTime = "0:43.247";
    string Status = "Simulation records";
    bool LiveDataActive = false;

    string DivisionCode(const string &in divisionName) {
        string division = divisionName.ToUpper();
        if (division == "ACADEMY" || division == "ACADEMY LEAGUE" || division == "AL") return "AL";
        if (division == "MASTER" || division == "MASTER LEAGUE" || division == "ML") return "ML";
        return "CL";
    }

    string FormatMs(uint timeMs) {
        if (timeMs == 0) return "--";
        uint minutes = timeMs / 60000;
        uint seconds = (timeMs % 60000) / 1000;
        uint millis = timeMs % 1000;

        string secondsText = tostring(seconds);
        if (seconds < 10) secondsText = "0" + secondsText;

        string millisText = tostring(millis);
        if (millis < 100) millisText = "0" + millisText;
        if (millis < 10) millisText = "0" + millisText;

        return tostring(minutes) + ":" + secondsText + "." + millisText;
    }

    void SyncLabels() {
        DivisionLabel = DivisionCode(MatchState::Division) + " WR";
    }

    void SyncFromSettings() {
        LiveDataActive = false;
        OverallTime = S_TestOverallWR;
        DivisionTime = S_TestDivisionWR;
        SyncLabels();
        Status = "Simulation records";
    }

    void ApplyLive(uint worldTimeMs, uint divisionTimeMs, const string &in status) {
        LiveDataActive = true;
        OverallTime = worldTimeMs > 0 ? FormatMs(worldTimeMs) : "--";
        DivisionTime = divisionTimeMs > 0 ? FormatMs(divisionTimeMs) : "--";
        SyncLabels();
        Status = status;
    }

    void Initialize() {
        SyncFromSettings();
        trace("MLE TM PROD records state initialized.");
    }
}
