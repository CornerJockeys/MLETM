namespace ProdOverlay {
    void Render() {
        if (!S_ShowProdOverlay) return;

        UI::SetNextWindowSize(360, 140, UI::Cond::FirstUseEver);
        if (UI::Begin("MLE TM PROD", S_ShowProdOverlay)) {
            UI::Text("PROD overlay skeleton");
            UI::Separator();

            if (ProdWhitelist::CanViewAdvancedStats()) {
                UI::Text("Advanced stats: Enabled");
            } else {
                UI::Text("Advanced stats: Locked");
            }

            UI::Text("Access: " + ProdWhitelist::Status);
        }
        UI::End();
    }
}
