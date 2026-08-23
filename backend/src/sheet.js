const SPREADSHEET_ID = "1NBk-HBbEbsySgEBq3XTMVHnZHRfK5C1An14nfXetZmk";

function cellValue(cell) {
  return cell && cell.v !== undefined && cell.v !== null ? cell.v : null;
}

function escapeQueryString(value) {
  return String(value).replace(/'/g, "''");
}

async function querySheet(sheetName, query) {
  const params = new URLSearchParams({
    tqx: "out:json",
    sheet: sheetName,
    headers: "1",
    tq: query,
  });

  const url = `https://docs.google.com/spreadsheets/d/${SPREADSHEET_ID}/gviz/tq?${params}`;
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`Google Sheets request failed: HTTP ${response.status}`);
  }

  const text = await response.text();
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");

  if (start < 0 || end < start) {
    throw new Error("Google Sheets returned an unexpected response.");
  }

  const payload = JSON.parse(text.slice(start, end + 1));
  if (payload.status !== "ok") {
    throw new Error("Google Sheets query failed.");
  }

  return payload.table?.rows ?? [];
}

function divisionForLeague(league) {
  if (league === "ACADEMY") return "AL";
  if (league === "CHAMPION") return "CL";
  if (league === "MASTER") return "ML";
  return "";
}

function sheetTimeToMs(value) {
  const numeric = Number(value);
  if (!Number.isFinite(numeric) || numeric <= 0) return 0;

  // Google Sheets stores durations as fractions of a day.
  if (numeric < 1) return Math.round(numeric * 86400000);

  return Math.round(numeric);
}

export async function getPlayerFromSheet(accountId) {
  const safeAccountId = escapeQueryString(accountId);
  const rows = await querySheet(
    "Player Master",
    `select A,C,D,I,O,Q,R,S where I = '${safeAccountId}' limit 1`,
  );

  if (rows.length === 0) return null;

  const cells = rows[0].c ?? [];
  const rosterValue = String(cellValue(cells[4]) ?? "");
  const league = String(cellValue(cells[7]) ?? "");

  return {
    accountId: String(cellValue(cells[3]) ?? accountId),
    tmid: String(cellValue(cells[0]) ?? ""),
    mleName: String(cellValue(cells[1]) ?? ""),
    tmName: String(cellValue(cells[2]) ?? ""),
    team: rosterValue || "FA",
    rosterSlot: String(cellValue(cells[5]) ?? ""),
    salary: Number(cellValue(cells[6]) ?? 0),
    league,
    division: divisionForLeague(league),
    rostered: rosterValue !== "" && rosterValue !== "FA",
  };
}

export async function getMapMetadataFromSheet(mapUid, mapId) {
  const safeMapId = escapeQueryString(mapId);
  const rows = await querySheet(
    "MLE Map Records",
    `select G,H,I where H = '${safeMapId}' limit 1`,
  );

  if (rows.length === 0) return null;

  const cells = rows[0].c ?? [];
  const group = String(cellValue(cells[0]) ?? "");

  return {
    mapId: String(cellValue(cells[1]) ?? mapId),
    mapUid,
    name: String(cellValue(cells[2]) ?? ""),
    groups: group ? [group] : [],
  };
}

export async function getLeaderboardFromSheet(mapUid, mapId, division) {
  const safeMapId = escapeQueryString(mapId);
  const safeDivision = escapeQueryString(division);
  const rows = await querySheet(
    "MLE Map Records",
    `select A,C,K,N where H = '${safeMapId}' and F = '${safeDivision}' order by K asc`,
  );

  const records = [];
  for (const row of rows) {
    const cells = row.c ?? [];
    const timeMs = sheetTimeToMs(cellValue(cells[2]));
    if (timeMs <= 0) continue;

    records.push({
      accountId: String(cellValue(cells[0]) ?? ""),
      mleName: String(cellValue(cells[1]) ?? ""),
      timeMs,
      respawns: Math.max(0, Math.round(Number(cellValue(cells[3]) ?? 0))),
    });
  }

  if (records.length === 0) return null;

  return {
    mapUid,
    division,
    records,
  };
}
