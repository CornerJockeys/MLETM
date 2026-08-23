import {
  getLeaderboardFromSheet,
  getMapMetadataFromSheet,
  getPlayerFromSheet,
} from "./sheet.js";

const MAP_IDS_BY_UID = {
  q8FBp3dSzAftMGWLDB786ctTund: "a7decefc-ad24-477d-88d4-0a1f03ee3958",
};

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

export default {
  async fetch(request) {
    const url = new URL(request.url);

    try {
      if (request.method === "GET" && url.pathname === "/health") {
        return Response.json({
          status: "ok",
          service: "mle-tm-temp-api",
          source: "tm-data-master",
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
        const mapId = MAP_IDS_BY_UID[mapUid];

        if (!mapId) {
          return jsonError("map_uid_not_mapped", 404, { mapUid });
        }

        if (parts.length === 4 && parts[2] === "leaderboards") {
          const division = decodeURIComponent(parts[3]);
          const leaderboard = await getLeaderboardFromSheet(mapUid, mapId, division);

          if (!leaderboard) {
            return jsonError("leaderboard_not_found", 404, { mapUid, division });
          }

          return Response.json(leaderboard);
        }

        if (parts.length === 2) {
          const map = await getMapMetadataFromSheet(mapUid, mapId);

          if (!map) {
            return jsonError("map_not_found", 404, { mapUid, mapId });
          }

          return Response.json(map);
        }
      }

      return jsonError("not_found", 404);
    } catch (error) {
      console.error("MLE TM temporary API error", error);
      return jsonError("sheet_source_unavailable", 502);
    }
  },
};
