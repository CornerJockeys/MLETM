import mapsSnapshot from "../../data/maps.json";
import playersSnapshot from "../../data/players.json";
import mapRecordsSnapshot from "../../data/map-records.json";
import clubTagsSnapshot from "../../data/club-tags.json";
import prodWhitelistSnapshot from "../../data/prod-whitelist.json";
import { handleRuntimeArchivePost } from "./runtime-archive.js";

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

function getMapFromSnapshot(mapUid) {
  const map = mapsSnapshot.maps?.[mapUid];

  if (!map) {
    return null;
  }

  return {
    mapId: map.mapId,
    mapUid,
    name: map.name,
    groups: map.groups ?? [],
  };
}

function getAllPlayers() {
  return Object.values(playersSnapshot.players ?? {});
}

function getPlayerByAccountId(accountId) {
  return playersSnapshot.players?.[accountId] ?? null;
}

function getPlayerByDiscordId(discordId) {
  const normalizedDiscordId = String(discordId || "").trim();

  if (!normalizedDiscordId) {
    return null;
  }

  return (
    getAllPlayers().find(
      (player) => String(player?.discordId ?? "").trim() === normalizedDiscordId,
    ) ?? null
  );
}

function getPlayerByTmid(tmid) {
  const normalizedTmid = String(tmid || "").trim().toUpperCase();

  if (!normalizedTmid) {
    return null;
  }

  return (
    getAllPlayers().find(
      (player) => String(player?.tmid ?? "").trim().toUpperCase() === normalizedTmid,
    ) ?? null
  );
}

function getPlayerByMleName(mleName) {
  const normalizedMleName = String(mleName || "").trim().toLocaleLowerCase("en-US");

  if (!normalizedMleName) {
    return null;
  }

  return (
    getAllPlayers().find(
      (player) =>
        String(player?.mleName ?? "").trim().toLocaleLowerCase("en-US") ===
        normalizedMleName,
    ) ?? null
  );
}

function searchPlayers(query, limit = 25) {
  const normalizedQuery = String(query || "").trim().toLocaleLowerCase("en-US");
  const safeLimit = Math.max(1, Math.min(Number(limit) || 25, 25));

  const candidates = getAllPlayers()
    .map((player) => {
      const mleName = String(player?.mleName ?? "").trim();
      const tmName = String(player?.tmName ?? "").trim();
      const mleLower = mleName.toLocaleLowerCase("en-US");
      const tmLower = tmName.toLocaleLowerCase("en-US");

      let score = 4;
      if (!normalizedQuery) score = 3;
      else if (mleLower === normalizedQuery) score = 0;
      else if (mleLower.startsWith(normalizedQuery)) score = 1;
      else if (tmLower.startsWith(normalizedQuery)) score = 2;
      else if (mleLower.includes(normalizedQuery) || tmLower.includes(normalizedQuery)) score = 3;
      else return null;

      return { player, score, mleName, tmName };
    })
    .filter(Boolean)
    .sort((a, b) => a.score - b.score || a.mleName.localeCompare(b.mleName))
    .slice(0, safeLimit);

  return candidates.map(({ player, mleName, tmName }) => ({
    tmid: String(player?.tmid ?? ""),
    mleName,
    tmName,
    team: String(player?.team ?? "FA"),
    division: String(player?.division ?? ""),
    rostered: Boolean(player?.rostered),
  }));
}

function getTeamsFromSnapshot() {
  return Object.keys(clubTagsSnapshot.teams ?? {}).sort((a, b) =>
    a.localeCompare(b),
  );
}

function getClubDisplayFromRoster(accountId) {
  const player = getPlayerByAccountId(accountId);

  const team =
    player?.rostered && player?.team && player.team !== "FA"
      ? player.team
      : "FA";

  const club =
    team === "FA"
      ? clubTagsSnapshot.defaultClub
      : clubTagsSnapshot.teams?.[team] ?? clubTagsSnapshot.defaultClub;

  return {
    team,
    clubTag: club?.normalizedTag ?? "",
    clubTagFormat: club?.tagFormat ?? "",
    clubId: club?.clubId ?? "",
  };
}

function getLeaderboardFromSnapshot(mapUid, mapId, division) {
  const normalizedDivision = String(division || "")
    .trim()
    .toUpperCase();

  const map = mapRecordsSnapshot.maps?.[mapId];

  if (!map) {
    return null;
  }

  const records = map.divisions?.[normalizedDivision];

  if (!Array.isArray(records) || records.length === 0) {
    return null;
  }

  return {
    mapUid,
    division: normalizedDivision,
    records: records.map((record) => {
      const player = getPlayerByAccountId(record.accountId);
      const salary = player?.salary;

      return {
        ...record,
        ...getClubDisplayFromRoster(record.accountId),
        ...(typeof salary === "number" ? { salary } : {}),
      };
    }),
  };
}

function getProdAccess(accountId) {
  const normalizedAccountId = String(accountId || "").trim();
  const member = prodWhitelistSnapshot.members?.[normalizedAccountId] ?? null;
  const authorized = member?.authorized === true;

  return {
    accountId: normalizedAccountId,
    authorized,
    advancedStats: authorized && member?.advancedStats === true,
    role: authorized ? String(member?.role ?? "prod") : "",
    authMode: "account_allowlist_v1",
    whitelistSchemaVersion: prodWhitelistSnapshot.schemaVersion ?? 1,
  };
}

function handleProdAccessLookup(parts) {
  if (
    parts.length !== 5 ||
    parts[0] !== "v1" ||
    parts[1] !== "prod" ||
    parts[2] !== "access" ||
    parts[3] !== "account"
  ) {
    return jsonError("not_found", 404);
  }

  const accountId = decodeURIComponent(parts[4]);
  if (!accountId) {
    return jsonError("account_id_required", 400);
  }

  return Response.json(getProdAccess(accountId));
}

function handlePlayerLookup(parts) {
  if (parts.length !== 4) {
    return jsonError("not_found", 404);
  }

  const lookupType = parts[2];
  const lookupValue = decodeURIComponent(parts[3]);

  let player = null;
  let extra = {};

  if (lookupType === "account") {
    player = getPlayerByAccountId(lookupValue);
    extra = { accountId: lookupValue };
  } else if (lookupType === "discord") {
    player = getPlayerByDiscordId(lookupValue);
    extra = { discordId: lookupValue };
  } else if (lookupType === "tmid") {
    player = getPlayerByTmid(lookupValue);
    extra = { tmid: lookupValue };
  } else if (lookupType === "name") {
    player = getPlayerByMleName(lookupValue);
    extra = { mleName: lookupValue };
  } else {
    return jsonError("not_found", 404);
  }

  if (!player) {
    return jsonError("player_not_found", 404, extra);
  }

  return Response.json(player);
}

function handleMapLookup(parts) {
  if (parts.length < 3) {
    return jsonError("not_found", 404);
  }

  const mapUid = decodeURIComponent(parts[2]);
  const map = getMapFromSnapshot(mapUid);

  if (!map) {
    return jsonError("map_not_found", 404, { mapUid });
  }

  if (parts.length === 5 && parts[3] === "leaderboards") {
    const division = decodeURIComponent(parts[4]);
    const leaderboard = getLeaderboardFromSnapshot(mapUid, map.mapId, division);

    if (!leaderboard) {
      return jsonError("leaderboard_not_found", 404, { mapUid, division });
    }

    return Response.json(leaderboard);
  }

  if (parts.length === 3) {
    return Response.json(map);
  }

  return jsonError("not_found", 404);
}

function handleV1Get(url) {
  const parts = url.pathname.split("/").filter(Boolean);

  if (url.pathname === "/v1/health") {
    return Response.json({
      status: "ok",
      service: "mle-tm-api",
      apiVersion: "v1",
      playerSchemaVersion: playersSnapshot.schemaVersion ?? null,
      prodWhitelistSchemaVersion: prodWhitelistSnapshot.schemaVersion ?? null,
      source: playersSnapshot.source ?? "repository-snapshots",
    });
  }

  if (url.pathname === "/v1/teams") {
    return Response.json({ teams: getTeamsFromSnapshot() });
  }

  if (url.pathname === "/v1/players/search") {
    return Response.json({
      players: searchPlayers(url.searchParams.get("q"), url.searchParams.get("limit")),
    });
  }

  if (parts[0] === "v1" && parts[1] === "prod") {
    return handleProdAccessLookup(parts);
  }

  if (parts[0] === "v1" && parts[1] === "players") {
    return handlePlayerLookup(parts);
  }

  if (parts[0] === "v1" && parts[1] === "maps") {
    return handleMapLookup(parts);
  }

  return null;
}

function handleLegacyGet(url) {
  if (url.pathname === "/health") {
    return Response.json({
      status: "ok",
      service: "mle-tm-temp-api",
      source: "tm-data-master-lo",
    });
  }

  if (url.pathname === "/teams") {
    return Response.json({ teams: getTeamsFromSnapshot() });
  }

  if (url.pathname.startsWith("/players/")) {
    const accountId = decodeURIComponent(url.pathname.slice("/players/".length));
    const player = getPlayerByAccountId(accountId);

    if (!player) {
      return jsonError("player_not_found", 404, { accountId });
    }

    return Response.json(player);
  }

  if (url.pathname.startsWith("/maps/")) {
    const parts = url.pathname.split("/").filter(Boolean);
    const mapUid = parts.length >= 2 ? decodeURIComponent(parts[1]) : "";
    const map = getMapFromSnapshot(mapUid);

    if (!map) {
      return jsonError("map_not_found", 404, { mapUid });
    }

    if (parts.length === 4 && parts[2] === "leaderboards") {
      const division = decodeURIComponent(parts[3]);
      const leaderboard = getLeaderboardFromSnapshot(mapUid, map.mapId, division);

      if (!leaderboard) {
        return jsonError("leaderboard_not_found", 404, { mapUid, division });
      }

      return Response.json(leaderboard);
    }

    if (parts.length === 2) {
      return Response.json(map);
    }
  }

  return null;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    try {
      if (request.method === "GET") {
        const v1Response = handleV1Get(url);
        if (v1Response) {
          return v1Response;
        }

        const legacyResponse = handleLegacyGet(url);
        if (legacyResponse) {
          return legacyResponse;
        }

        return jsonError("not_found", 404);
      }

      if (request.method === "POST") {
        const runtimeResponse = await handleRuntimeArchivePost(request, url, env);
        return runtimeResponse ?? jsonError("not_found", 404);
      }

      return jsonError("method_not_allowed", 405);
    } catch (error) {
      console.error("MLE TM API error", error);
      return jsonError("internal_error", 500, {
        detail: error instanceof Error ? error.message : String(error),
      });
    }
  },
};
