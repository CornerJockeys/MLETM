void Main() {
    trace("MLE TM plugin loaded.");

    MedalTarget::Initialize();

    if (!PlayerDirectory::Initialize()) {
        error("MLE TM: player directory failed to initialize.");
        return;
    }

    if (!MapDirectory::Initialize()) {
        error("MLE TM: map directory failed to initialize.");
        return;
    }

    startnew(RuntimeState::MonitorLoop);
    startnew(PBMonitor::MonitorLoop);
    startnew(ApiClient::HealthCheck);
}

string FormatRaceTime(uint timeMs) {
    uint minutes = timeMs / 60000;
    uint seconds = (timeMs % 60000) / 1000;
    uint millis = timeMs % 1000;

    string secondsText = Text::Format("%d", seconds);
    if (seconds < 10) secondsText = "0" + secondsText;

    string millisText = Text::Format("%d", millis);
    if (millis < 100) millisText = "0" + millisText;
    if (millis < 10) millisText = "0" + millisText;

    return Text::Format("%d", minutes) + ":" + secondsText + "." + millisText;
}
