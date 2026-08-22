import mapsSnapshot from "../../plugin/data/maps.json";

const PLAYERS = {
  "971ea404-8900-4748-9acc-6c57b02ae2a5": {
    accountId: "971ea404-8900-4748-9acc-6c57b02ae2a5",
    tmid: "T0159",
    mleName: "Corners",
    tmName: "Corners-",
    team: "Jets",
    rosterSlot: "D",
    salary: 5,
    league: "ACADEMY",
    division: "AL",
    rostered: true,
  },
};

const MAPS = {
  q8FBp3dSzAftMGWLDB786ctTund: {
    mapId: "a7decefc-ad24-477d-88d4-0a1f03ee3958",
    mapUid: "q8FBp3dSzAftMGWLDB786ctTund",
    name: "MLE - Anglioni [E]",
    groups: ["AL"],
  },
};

export default {
  async fetch(request) {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/health") {
      return Response.json({
        status: "ok",
        service: "mle-tm-temp-api",
      });
    }

    if (request.method === "GET" && url.pathname.startsWith("/players/")) {
      const accountId = decodeURIComponent(url.pathname.slice("/players/".length));
      const player = PLAYERS[accountId];

      if (!player) {
        return Response.json(
          {
            status: "error",
            error: "player_not_found",
            accountId,
          },
          { status: 404 },
        );
      }

      return Response.json(player);
    }

    if (request.method === "GET" && url.pathname.startsWith("/maps/")) {
      const parts = url.pathname.split("/").filter(Boolean);
      const mapUid = parts.length >= 2 ? decodeURIComponent(parts[1]) : "";

      if (parts.length === 4 && parts[2] === "leaderboards") {
        const division = decodeURIComponent(parts[3]);
        const mapSnapshot = mapsSnapshot.maps?.[mapUid];
        const records = mapSnapshot?.leaderboards?.[division];

        if (!records) {
          return Response.json(
            {
              status: "error",
              error: "leaderboard_not_found",
              mapUid,
              division,
            },
            { status: 404 },
          );
        }

        return Response.json({
          mapUid,
          division,
          records,
        });
      }

      if (parts.length === 2) {
        const map = MAPS[mapUid];

        if (!map) {
          return Response.json(
            {
              status: "error",
              error: "map_not_found",
              mapUid,
            },
            { status: 404 },
          );
        }

        return Response.json(map);
      }
    }

    return Response.json(
      {
        status: "error",
        error: "not_found",
      },
      { status: 404 },
    );
  },
};
