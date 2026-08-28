const RUNTIME_REPOSITORY = {
  owner: "CornerJockeys",
  repo: "MLETM",
  branch: "main",
};

const SCRIM_ARCHIVE_STAGES = new Set(["session", "submission", "result"]);

function jsonError(error, status = 500, extra = {}) {
  return Response.json(
    {
      status: "error",
      error,
      ...extra,
    },
    { status },
  );
}

function encodeBase64Utf8(value) {
  const bytes = new TextEncoder().encode(value);
  let binary = "";
  const chunkSize = 0x8000;

  for (let offset = 0; offset < bytes.length; offset += chunkSize) {
    binary += String.fromCharCode(...bytes.subarray(offset, offset + chunkSize));
  }

  return btoa(binary);
}

function getBearerToken(request) {
  const authorization = request.headers.get("Authorization") ?? "";
  return authorization.startsWith("Bearer ") ? authorization.slice(7).trim() : "";
}

function runtimeGitHubHeaders(token) {
  return {
    Accept: "application/vnd.github+json",
    Authorization: `Bearer ${token}`,
    "X-GitHub-Api-Version": "2022-11-28",
    "User-Agent": "mle-tm-api",
  };
}

async function writeRuntimeArtifact(env, path, document) {
  const githubToken = String(env?.GITHUB_RUNTIME_TOKEN ?? "").trim();
  if (!githubToken) {
    throw new Error("github_runtime_token_not_configured");
  }

  const encodedPath = path.split("/").map(encodeURIComponent).join("/");
  const apiUrl = `https://api.github.com/repos/${RUNTIME_REPOSITORY.owner}/${RUNTIME_REPOSITORY.repo}/contents/${encodedPath}`;
  const headers = runtimeGitHubHeaders(githubToken);

  const existingResponse = await fetch(
    `${apiUrl}?ref=${encodeURIComponent(RUNTIME_REPOSITORY.branch)}`,
    { headers },
  );

  let sha = null;
  if (existingResponse.ok) {
    const existing = await existingResponse.json();
    sha = existing.sha ?? null;
  } else if (existingResponse.status !== 404) {
    throw new Error(`github_runtime_read_failed_${existingResponse.status}`);
  }

  const body = {
    message: `Archive ${document.scrimUid} ${document.artifact}`,
    content: encodeBase64Utf8(`${JSON.stringify(document, null, 2)}\n`),
    branch: RUNTIME_REPOSITORY.branch,
    ...(sha ? { sha } : {}),
  };

  const writeResponse = await fetch(apiUrl, {
    method: "PUT",
    headers: {
      ...headers,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!writeResponse.ok) {
    const detail = await writeResponse.text();
    throw new Error(`github_runtime_write_failed_${writeResponse.status}: ${detail}`);
  }

  return writeResponse.json();
}

export async function handleRuntimeArchivePost(request, url, env) {
  const parts = url.pathname.split("/").filter(Boolean);
  if (
    parts.length !== 5 ||
    parts[0] !== "v1" ||
    parts[1] !== "runtime" ||
    parts[2] !== "scrims"
  ) {
    return null;
  }

  const expectedToken = String(env?.MLETM_WRITE_TOKEN ?? "").trim();
  const githubToken = String(env?.GITHUB_RUNTIME_TOKEN ?? "").trim();

  if (!expectedToken || !githubToken) {
    return jsonError("runtime_archive_not_configured", 503);
  }

  if (getBearerToken(request) !== expectedToken) {
    return jsonError("unauthorized", 401);
  }

  const scrimUid = decodeURIComponent(parts[3]);
  const artifact = decodeURIComponent(parts[4]);

  if (!/^[A-Za-z0-9_-]{1,64}$/.test(scrimUid)) {
    return jsonError("invalid_scrim_uid", 400);
  }

  if (!SCRIM_ARCHIVE_STAGES.has(artifact)) {
    return jsonError("invalid_scrim_artifact", 400, { artifact });
  }

  let payload;
  try {
    payload = await request.json();
  } catch {
    return jsonError("invalid_json", 400);
  }

  const document = {
    schemaVersion: 1,
    source: "scrim-bot",
    artifact,
    scrimUid,
    capturedAt: new Date().toISOString(),
    payload,
  };
  const path = `runtime/scrims/${scrimUid}/${artifact}.json`;
  const result = await writeRuntimeArtifact(env, path, document);

  return Response.json({
    status: "ok",
    scrimUid,
    artifact,
    path,
    commitSha: result?.commit?.sha ?? null,
  });
}
