import mapsSnapshot from "../data/maps.json";

import {
  getLeaderboardFromSheet,
  getPlayerFromSheet,
} from "./sheet.js";

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
        const player = await getPlayerFromSheet(accountId);

        if (!player) {
          return jsonError("player_not_found", 404, { accountId });
        }

        return Response.json(player);
      }

      if (request.method === "GET" && url.pathname.startsWith("/maps/")) {
        const parts = url.pathname.split("/").filter(Boolean);
        const mapUid = parts.length >= 2 ? decodeURIComponent(parts[1]) : "";
        const map = await getMapReferenceFromSheet(mapUid);

        if (!map) {
          return jsonError("map_not_found", 404, { mapUid });
        }

        if (parts.length === 4 && parts[2] === "leaderboards") {
          const division = decodeURIComponent(parts[3]);
          const leaderboard = await getLeaderboardFromSheet(mapUid, map.mapId, division);

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
