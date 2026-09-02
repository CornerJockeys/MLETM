void Main() {
    trace("MLE TM PROD plugin loaded.");
    ProdState::Initialize();
    ProdWhitelist::Initialize();
    LiveDataSource::SetSimulationStatus();
}

void Update(float dt) {
    AssetReloadGuard::Update();
    ChatVisibility::Update();
    ProdWhitelist::Update();
    ProdOverlay::UpdateState();
}

// Openplanet/dev/operator controls. These are not part of the clean broadcast layer.
void Render() {
    ProdOverlay::RenderControls();
}

// The actual production HUD belongs on the interface layer so it can remain visible
// independently of whether the Openplanet overlay/menu is open.
void RenderInterface() {
    ProdOverlay::RenderBroadcast();
}

void RenderMenu() {
    if (UI::MenuItem("MLE TM PROD - Overlay", "", S_ShowProdOverlay)) {
        S_ShowProdOverlay = !S_ShowProdOverlay;
    }
    if (UI::MenuItem("MLE TM PROD - Test Controls", "", S_ShowTestControls)) {
        S_ShowTestControls = !S_ShowTestControls;
    }
    if (UI::MenuItem("MLE TM PROD - Setup Mode", "", S_LayoutSetupMode)) {
        S_LayoutSetupMode = !S_LayoutSetupMode;
    }
    if (UI::MenuItem("MLE TM PROD - MLE Logo", "", S_ShowMleLogo)) {
        S_ShowMleLogo = !S_ShowMleLogo;
    }
    if (UI::MenuItem("MLE TM PROD - Open Overlay Folder")) {
        OverlayTheme::OpenFolder();
    }
}

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    ProdHotkeys::Handle(down, key);
    return UI::InputBlocking::DoNothing;
}

void ShutdownProd() {
    ChatVisibility::Shutdown();
}

void OnDisabled() {
    ShutdownProd();
}

void OnDestroyed() {
    ShutdownProd();
}
