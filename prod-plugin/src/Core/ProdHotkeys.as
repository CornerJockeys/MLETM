namespace ProdHotkeys {
    void NotifyState(const string &in message) {
        UI::ShowNotification("MLE TM PROD", message, vec4(0.10f, 0.65f, 0.45f, 0.35f), 2500);
    }

    void ToggleMaster() {
        S_ShowProdOverlay = !S_ShowProdOverlay;
        NotifyState(S_ShowProdOverlay ? "Broadcast overlay enabled" : "Broadcast overlay hidden");
    }

    void ToggleSetupMode() {
        S_LayoutSetupMode = !S_LayoutSetupMode;
        NotifyState(S_LayoutSetupMode ? "Overlay SETUP mode - widgets unlocked" : "Overlay LIVE mode - widgets locked");
    }

    void ToggleBanner() {
        S_ShowMatchBanner = !S_ShowMatchBanner;
    }

    void ToggleRanking() {
        S_ShowLiveRanking = !S_ShowLiveRanking;
    }

    void ToggleRecords() {
        S_ShowRecordsPanel = !S_ShowRecordsPanel;
    }

    void ToggleChat() {
        ChatVisibility::Toggle();
        NotifyState(ChatVisibility::Hidden ? "Game chat hidden locally" : "Game chat restored");
    }

    bool Handle(bool down, VirtualKey key) {
        if (!S_EnableBroadcastHotkeys || !down) return false;

        if (key == S_HotkeyMasterOverlay) {
            ToggleMaster();
            return true;
        }
        if (key == S_HotkeyChat) {
            ToggleChat();
            return true;
        }
        if (key == S_HotkeySetupMode) {
            ToggleSetupMode();
            return true;
        }
        if (key == S_HotkeyBanner) {
            ToggleBanner();
            return true;
        }
        if (key == S_HotkeyRanking) {
            ToggleRanking();
            return true;
        }
        if (key == S_HotkeyRecords) {
            ToggleRecords();
            return true;
        }

        return false;
    }
}
