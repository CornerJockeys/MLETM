namespace ProdWhitelist {
    bool CheckComplete = false;
    bool AdvancedStatsAllowed = false;
    bool Authorized = false;
    bool CheckRunning = false;
    string AccountId = "";
    string Role = "";
    string AuthMode = "";
    string Status = "Not checked";
    uint LastAttemptAt = 0;
    const uint RetryDelayMs = 30000;

    void ResetForAccount(const string &in accountId) {
        AccountId = accountId;
        CheckComplete = false;
        AdvancedStatsAllowed = false;
        Authorized = false;
        Role = "";
        AuthMode = "";
        LastAttemptAt = 0;
        Status = accountId.Length > 0 ? "Access check pending" : "Waiting for local TM account";
    }

    string ResolveLocalAccountId() {
        auto app = cast<CTrackMania>(GetApp());
        if (app is null || app.LocalPlayerInfo is null) return "";
        return app.LocalPlayerInfo.WebServicesUserId;
    }

    void CheckAsync() {
        string checkingAccountId = AccountId;
        if (checkingAccountId.Length == 0) {
            CheckRunning = false;
            return;
        }

        auto result = ProdApiClient::GetProdAccess(checkingAccountId);

        // Ignore a stale response if the operator account changed while the request ran.
        if (checkingAccountId != AccountId) {
            CheckRunning = false;
            return;
        }

        if (result is null || !result.requestOk) {
            CheckComplete = false;
            Authorized = false;
            AdvancedStatsAllowed = false;
            Role = "";
            AuthMode = "";
            Status = "Access service unavailable - advanced stats locked";
            CheckRunning = false;
            return;
        }

        CheckComplete = true;
        Authorized = result.authorized;
        AdvancedStatsAllowed = result.authorized && result.advancedStats;
        Role = result.role;
        AuthMode = result.authMode;
        Status = Authorized
            ? (AdvancedStatsAllowed ? "Authorized - advanced stats enabled" : "Authorized - standard PROD access")
            : "Not on PROD whitelist";
        CheckRunning = false;
    }

    void RequestCheck() {
        if (CheckRunning || AccountId.Length == 0) return;
        CheckRunning = true;
        LastAttemptAt = Time::Now;
        Status = "Checking PROD access...";
        startnew(CheckAsync);
    }

    bool RetryDue() {
        if (LastAttemptAt == 0) return true;
        return Time::Now - LastAttemptAt >= RetryDelayMs;
    }

    void Update() {
        string nextAccountId = ResolveLocalAccountId();
        if (nextAccountId != AccountId) {
            ResetForAccount(nextAccountId);
            if (nextAccountId.Length > 0) RequestCheck();
            return;
        }

        if (AccountId.Length > 0 && !CheckComplete && !CheckRunning && RetryDue()) {
            RequestCheck();
        }
    }

    void Initialize() {
        ResetForAccount(ResolveLocalAccountId());
        if (AccountId.Length > 0) RequestCheck();
    }

    bool CanViewAdvancedStats() {
        return CheckComplete && Authorized && AdvancedStatsAllowed;
    }
}
