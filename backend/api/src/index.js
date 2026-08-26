import mapsSnapshot from "../../data/maps.json";
import playersSnapshot from "../../data/players.json";
import mapRecordsSnapshot from "../../data/map-records.json";
import clubTagsSnapshot from "../../data/club-tags.json";

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
      source: playersSnapshot.source ?? "repository-snapshots",
    });
  }

  if (url.pathname === "/v1/teams") {
    return Response.json({ teams: getTeamsFromSnapshot() });
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
  async fetch(request) {
    const url = new URL(request.url);

    try {
      if (request.method !== "GET") {
        return jsonError("method_not_allowed", 405);
      }

      const v1Response = handleV1Get(url);
      if (v1Response) {
        return v1Response;
      }

      // Temporary compatibility aliases for the current plugin/leaderboard work.
      // New consumers should use /v1 routes.
      const legacyResponse = handleLegacyGet(url);
      if (legacyResponse) {
        return legacyResponse;
      }

      return jsonError("not_found", 404);
    } catch (error) {
      console.error("MLE TM API error", error);
      return jsonError("internal_error", 500, {
        detail: error instanceof Error ? error.message : String(error),
      });
    }
  },
};
