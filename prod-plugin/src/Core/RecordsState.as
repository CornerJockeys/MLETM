namespace RecordsState {
    string OverallLabel = "OVERALL WR";
    string OverallTime = "0:41.686";
    string DivisionLabel = "CL WR";
    string DivisionTime = "0:43.247";

    void SyncFromSettings() {
        OverallTime = S_TestOverallWR;
        DivisionTime = S_TestDivisionWR;

        string division = S_TestDivision.ToUpper();
        if (division == "ACADEMY" || division == "ACADEMY LEAGUE" || division == "AL") {
            DivisionLabel = "AL WR";
        } else if (division == "MASTER" || division == "MASTER LEAGUE" || division == "ML") {
            DivisionLabel = "ML WR";
        } else {
            DivisionLabel = "CL WR";
        }
    }

    void Initialize() {
        SyncFromSettings();
        trace("MLE TM PROD records simulation initialized.");
    }
}
