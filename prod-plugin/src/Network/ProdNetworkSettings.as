[Setting category="PROD Network" name="MLE TM API Base URL" description="Base URL for PROD identity/access and MLE record lookups."]
string S_ProdApiBaseUrl = "https://mle-tm-temp-api.mschifanoiii.workers.dev";

[Setting category="PROD Records" name="Use live record data" description="OFF by default until validated. Overall WR comes from Nadeo Live Services; division WR comes from the MLE TM backend."]
bool S_UseLiveRecords = false;
