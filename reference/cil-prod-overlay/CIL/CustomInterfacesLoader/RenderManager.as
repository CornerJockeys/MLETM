namespace RenderManager {
    bool G_RenderInterface = Meta::IsDeveloperMode(); // render by default in dev mode
    float G_ButtonsDummySize = 0.;

    void RenderInterface() {
        if (G_RenderInterface) {
            UI::SetNextWindowSize(550., 250.);
            UI::Begin(Icons::Television + " Custom Interface Loader###CustomInterfaceLoader", G_RenderInterface, UI::WindowFlags::NoSavedSettings);

            if (UI::Button(Icons::FolderOpen + ' Open File Explorer')) {
                OpenExplorerPath(IO::FromStorageFolder(''));
            }

            UI::SameLine();

            if (UI::Button(Icons::Refresh + ' Reload')) {
                PacksManager::LoadConfigs();
            }

            UI::SameLine();

            vec2 LeftAlignedButtonsCursorPos = UI::GetCursorPos();

            UI::Dummy(vec2(G_ButtonsDummySize, 1.));

            UI::SameLine();

            vec2 RightAlignedButtonsCursorPos = UI::GetCursorPos();

            if (UI::Button(Icons::Info + ' Info')) {
                OpenBrowserURL('https://openplanet.dev/plugin/' + Meta::ExecutingPlugin().SiteID);
            }
            UI::SameLine();

            float RightAlignedButtonsWidth = UI::GetCursorPos().x - RightAlignedButtonsCursorPos.x;

            float ScrollBarSize = 0.;
            if (UI::GetScrollMaxY() > 0.) {
                ScrollBarSize = UI::GetStyleVarFloat(UI::StyleVar::ScrollbarSize);
            }

            G_ButtonsDummySize = Math::Max(0., UI::GetWindowSize().x - RightAlignedButtonsWidth - LeftAlignedButtonsCursorPos.x - UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x - ScrollBarSize);

            UI::Dummy(vec2());

            if (UI::BeginTable('ConfigTable', 5, UI::TableFlags(UI::TableFlags::NoSavedSettings | UI::TableFlags::Resizable | UI::TableFlags::Sortable | UI::TableFlags::SizingStretchProp |UI::TableFlags::ScrollY ))) {
                UI::TableSetupColumn("Name", UI::TableColumnFlags::DefaultSort, 200.);
                UI::TableSetupColumn("Author", UI::TableColumnFlags::None, 150.);
                UI::TableSetupColumn("Version", UI::TableColumnFlags::None, 100.);
                UI::TableSetupColumn("Modes", UI::TableColumnFlags::None, 300.);
                UI::TableSetupColumn("Enable", UI::TableColumnFlags::NoSort, 70.);
                UI::TableHeadersRow();

                const array<string> ConfigIds = PacksManager::G_Configs.GetKeys();

                for (uint i = 0; i < ConfigIds.Length; i++) {
                    const string Id = ConfigIds[i];
                    const PackConfig@ Config = PacksManager::GetConfig(Id);

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text(Config.Name);
                    UI::TableNextColumn();
                    UI::Text(Config.Author);
                    UI::TableNextColumn();
                    UI::Text(Config.Version);
                    UI::TableNextColumn();
                    UI::Text(Config.getPrettyModes());
                    UI::TableNextColumn();

                    const int index = PacksManager::G_EnabledConfigs.Find(Id);
                    const bool enabled = (index >= 0);
                    const bool newValue = UI::Checkbox('###'+ Id, enabled);
                    if (newValue != enabled) {
                        if (enabled) {
                            PacksManager::DisableInterface(Id);
                        } else {
                            PacksManager::EnableInterface(Id);
                        }
                    }
                }
                UI::EndTable();
            }
            
            UI::End();
        }
    }

    void RenderMenu() {
        if (UI::MenuItem(Icons::Television + ' Custom Interface Loader', "", G_RenderInterface)) {
            G_RenderInterface = !G_RenderInterface;
        }
    }

    void NotifyWarning(const string &in _Message) {
        UI::ShowNotification('Custom Interfaces Loader', _Message, vec4(0.9, 0.7, 0.2, 1.), 5000);
    }
}