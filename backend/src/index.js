export default {
  async fetch(request) {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/health") {
      return Response.json({
        status: "ok",
        service: "mle-tm-temp-api",
      });
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
