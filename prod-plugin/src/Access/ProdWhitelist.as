namespace ProdWhitelist {
    bool CheckComplete = false;
    bool AdvancedStatsAllowed = false;
    string Status = "Not checked";

    void Initialize() {
        // The backend whitelist lookup will be wired here.
        // Advanced stats must remain locked until access is explicitly granted.
        CheckComplete = false;
        AdvancedStatsAllowed = false;
        Status = "Whitelist not configured";
    }

    bool CanViewAdvancedStats() {
        return CheckComplete && AdvancedStatsAllowed;
    }
}
