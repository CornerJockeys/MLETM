import mapsSnapshot from "../data/maps.json";
import playersSnapshot from "../data/players.json";
import mapRecordsSnapshot from "../data/map-records.json";
import clubTagsSnapshot from "../data/club-tags.json";

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

function getPlayerFromSnapshot(accountId) {
  return playersSnapshot.players?.[accountId] ?? null;
}

function getClubDisplayFromRoster(accountId) {
  const player = getPlayerFromSnapshot(accountId);

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
    records: records.map((record) => ({
      ...record,
      ...getClubDisplayFromRoster(record.accountId),
    })),
  };
}

export default {
  async fetch(request) {
    const url = new URL(request.url);

    try {
      if (request.method === "GET" && url.pathname === "/health") {
        return Response.json({
          status: "ok",
          service: "mle-tm-temp-api",
          source: "tm-data-master-lo",
        });
      }

      if (request.method === "GET" && url.pathname.startsWith("/players/")) {
        const accountId = decodeURIComponent(url.pathname.slice("/players/".length));
        const player = getPlayerFromSnapshot(accountId);

        if (!player) {
          return jsonError("player_not_found", 404, { accountId });
        }

        return Response.json(player);
      }

      if (request.method === "GET" && url.pathname.startsWith("/maps/")) {
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

      return jsonError("not_found", 404);
    } catch (error) {
      console.error("MLE TM temporary API error", error);
      return jsonError("sheet_source_unavailable", 502, {
        detail: error instanceof Error ? error.message : String(error),
      });
    }
  },
};
