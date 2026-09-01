namespace ChatVisibility {
    bool Hidden = false;
    bool Applied = false;
    bool OriginalHidden = false;
    string Status = "Chat visible";

    CGamePlaygroundUIConfig@ AppliedConfig = null;

    CGamePlaygroundUIConfig@ GetConfig() {
        auto app = GetApp();
        if (app is null || app.CurrentPlayground is null) return null;
        auto playground = app.CurrentPlayground;
        if (playground.UIConfigs.Length == 0) return null;
        return playground.UIConfigs[0];
    }

    void Restore() {
        if (Applied && AppliedConfig !is null) {
            AppliedConfig.OverlayHideChat = OriginalHidden;
        }
        @AppliedConfig = null;
        Applied = false;
        OriginalHidden = false;
    }

    void SetHidden(bool hidden) {
        if (Hidden == hidden) return;
        Hidden = hidden;
        if (!Hidden) Restore();
    }

    void Toggle() {
        SetHidden(!Hidden);
    }

    void Update() {
        auto config = GetConfig();
        if (config is null) {
            if (Applied) Restore();
            Status = Hidden ? "Chat hide armed; no playground UI" : "Chat visible";
            return;
        }

        // A map/server transition gives us a different UI config object. Restore the
        // old object before capturing the new room's server-provided visibility state.
        if (Applied && AppliedConfig !is config) {
            Restore();
        }

        if (!Hidden) {
            if (Applied) Restore();
            Status = "Chat visible";
            return;
        }

        if (!Applied) {
            OriginalHidden = config.OverlayHideChat;
            @AppliedConfig = config;
            Applied = true;
        }

        // Re-apply while broadcast chat hiding is armed because the game mode/server
        // can refresh UIConfig values during sequence changes.
        config.OverlayHideChat = true;
        Status = "Chat hidden locally";
    }

    void Shutdown() {
        Hidden = false;
        Restore();
        Status = "Chat restored";
    }
}
