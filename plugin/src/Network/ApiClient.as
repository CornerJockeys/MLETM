[Setting category="MLE TM" name="API Base URL" description="Base URL for the MLE TM backend API. Leave blank to use local snapshot data only."]
string S_ApiBaseUrl = "";

namespace ApiClient {
    bool HealthCheckRunning = false;
    bool LastHealthCheckOk = false;
    int LastHealthStatusCode = 0;
    string LastHealthResponse = "";

    string NormalizeBaseUrl() {
        string baseUrl = S_ApiBaseUrl;
        while (baseUrl.EndsWith("/")) {
            baseUrl = baseUrl.SubStr(0, baseUrl.Length - 1);
        }
        return baseUrl;
    }

    bool IsConfigured() {
        return NormalizeBaseUrl().Length > 0;
    }

    Net::HttpRequest@ Get(const string &in path) {
        if (!path.StartsWith("/")) {
            throw("MLE TM API request path must start with '/'.");
        }

        string baseUrl = NormalizeBaseUrl();
        if (baseUrl.Length == 0) {
            throw("MLE TM API base URL is not configured.");
        }

        auto req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Get;
        req.Url = baseUrl + path;
        req.Start();
        return req;
    }

    void HealthCheck() {
        if (HealthCheckRunning) return;

        if (!IsConfigured()) {
            trace("MLE TM API not configured; local snapshots active.");
            return;
        }

        HealthCheckRunning = true;
        LastHealthCheckOk = false;
        LastHealthStatusCode = 0;
        LastHealthResponse = "";

        try {
            auto req = Get("/health");
            trace("MLE TM API health check: " + req.Url);

            while (!req.Finished()) {
                yield();
            }

            LastHealthStatusCode = req.ResponseCode();
            LastHealthResponse = req.String();
            LastHealthCheckOk = LastHealthStatusCode >= 200 && LastHealthStatusCode < 300;

            if (LastHealthCheckOk) {
                trace(
                    "MLE TM API health check passed: HTTP "
                    + Text::Format("%d", LastHealthStatusCode)
                    + " - "
                    + LastHealthResponse
                );
            } else {
                warn(
                    "MLE TM API health check failed: HTTP "
                    + Text::Format("%d", LastHealthStatusCode)
                    + " - "
                    + LastHealthResponse
                );
            }
        } catch {
            error("MLE TM API health check threw an exception.");
        }

        HealthCheckRunning = false;
    }
}
