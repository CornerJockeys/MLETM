const SPREADSHEET_ID = "1rQkquXGSmPYdNRLPUBW7VBrz6eiHR3UV5A_JA3StacY";

function cellValue(cell) {
  return cell && cell.v !== undefined && cell.v !== null ? cell.v : null;
}

function escapeQueryString(value) {
  return String(value).replace(/'/g, "''");
}

async function querySheet(sheetName, query, options = {}) {
  const params = new URLSearchParams({
    tqx: "out:json",
    sheet: sheetName,
    headers: String(options.headers ?? 1),
    tq: query,
  });

  if (options.range) {
    params.set("range", options.range);
  }

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
    const message = payload.errors?.map((error) => error.detailed_message || error.message).filter(Boolean).join(" | ");
    throw new Error(message ? `Google Sheets query failed: ${message}` : "Google Sheets query failed.");
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

export async function getMapReferenceFromSheet(mapUid) {
  const rows = await querySheet("Map IDs", "select *", {
    headers: 0,
    range: "A1:Z8",
  });

  const sections = [
    { group: "AL", namesRow: 1, idsRow: 2, uidsRow: 3 },
    { group: "CL/ML", namesRow: 5, idsRow: 6, uidsRow: 7 },
  ];

  for (const section of sections) {
    const names = rows[section.namesRow]?.c ?? [];
    const ids = rows[section.idsRow]?.c ?? [];
    const uids = rows[section.uidsRow]?.c ?? [];
    const width = Math.max(names.length, ids.length, uids.length);

    for (let column = 0; column < width; column++) {
      const candidateUid = String(cellValue(uids[column]) ?? "");
      if (candidateUid !== mapUid) continue;

      const mapId = String(cellValue(ids[column]) ?? "");
      const name = String(cellValue(names[column]) ?? "");
      if (!mapId || !name) return null;

      return {
        mapId,
        mapUid,
        name,
        groups: [section.group],
      };
    }
  }

  return null;
}

export async function getLeaderboardFromSheet(mapUid, mapId, division) {
  // Read the raw A:N grid so the indexes below always correspond to the
  // spreadsheet's actual columns rather than GViz's projected column order.
  const rows = await querySheet("MLE Map Records", "select *", {
    headers: 0,
    range: "A2:N1746",
  });

  const records = [];
  for (const row of rows) {
    const cells = row.c ?? [];

    // A=0, C=2, F=5, H=7, K=10, N=13
    const rowDivision = String(cellValue(cells[5]) ?? "").trim();
    const rowMapId = String(cellValue(cells[7]) ?? "").trim();

    if (rowMapId !== mapId || rowDivision !== division) continue;

    const timeMs = sheetTimeToMs(cellValue(cells[10]));
    if (timeMs <= 0) continue;

    records.push({
      accountId: String(cellValue(cells[0]) ?? ""),
      mleName: String(cellValue(cells[2]) ?? ""),
      timeMs,
      respawns: Math.max(0, Math.round(Number(cellValue(cells[13]) ?? 0))),
    });
  }

  records.sort((a, b) => a.timeMs - b.timeMs);

  if (records.length === 0) return null;

  return {
    mapUid,
    division,
    records,
  };
}
