void Main() {
    PacksManager::LoadConfigs();

    while (true) {
        yield();
        PacksManager::Yield();
    }
}

void RenderInterface() {
    RenderManager::RenderInterface();
}

void RenderMenu() {
    RenderManager::RenderMenu();
}