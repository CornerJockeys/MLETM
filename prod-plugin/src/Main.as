void Main() {
    trace("MLE TM PROD plugin loaded.");
    ProdState::Initialize();
    ProdWhitelist::Initialize();
}

void Render() {
    ProdOverlay::Render();
}
