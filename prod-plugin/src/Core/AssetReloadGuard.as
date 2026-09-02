namespace AssetReloadGuard {
    bool Pending = false;
    array<TeamLogoAsset@> RetiredTeamLogos;
    array<UI::Texture@> RetiredBrandingTextures;

    void Request() {
        Pending = true;
        OverlayTheme::Status = "Asset reload queued";
    }

    void RetainCurrentTextures() {
        auto keys = OverlayTheme::Logos.GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            TeamLogoAsset@ asset = null;
            if (OverlayTheme::Logos.Get(keys[i], @asset) && asset !is null && asset.texture !is null) {
                RetiredTeamLogos.InsertLast(asset);
            }
        }

        if (BrandingLogo::LogoTexture !is null) {
            RetiredBrandingTextures.InsertLast(BrandingLogo::LogoTexture);
        }
    }

    void Update() {
        if (!Pending) return;
        Pending = false;

        // Keep previous GPU texture handles alive, then rebuild the active cache from
        // Update() rather than from a UI render callback. This favors broadcast safety
        // over reclaiming a few KB when production hot-swaps graphics.
        RetainCurrentTextures();
        OverlayTheme::Reload();
        BrandingLogo::Reload();
    }
}
