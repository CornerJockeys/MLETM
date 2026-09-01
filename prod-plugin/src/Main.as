void Main() {
    trace("MLE TM PROD plugin loaded.");
    ProdState::Initialize();
    ProdWhitelist::Initialize();
}

void Update(float dt) {
    ChatVisibility::Update();
}

void Render() {
    ProdOverlay::Render();
}

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    ProdHotkeys::Handle(down, key);
    // PROD hotkeys are presentation controls only. Never consume the key event from
    // Trackmania; operators can rebind any collisions through Openplanet settings.
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
