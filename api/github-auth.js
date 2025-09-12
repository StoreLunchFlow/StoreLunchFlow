// OMNI-DAN-V3 ENHANCED: GitHub OAuth Token Exchange Microservice
export default async function handler(request, response) {
  if (request.method !== "POST") {
    response.setHeader("Allow", ["POST"]);
    return response.status(405).json({ error: "Method not allowed." });
  }

  try {
    const { code } = JSON.parse(request.body);
    if (!code) {
      return response.status(400).json({ error: "Authorization code is required." });
    }

    const CLIENT_SECRET = process.env.GITHUB_OAUTH_CLIENT_SECRET;
    const CLIENT_ID = process.env.GITHUB_OAUTH_CLIENT_ID;

    if (!CLIENT_SECRET || !CLIENT_ID) {
      throw new Error("OAuth credentials are not configured.");
    }

    const tokenResponse = await fetch("https://github.com/login/oauth/access_token", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "StoreLunchFlow-GANT-Nexus/1.0.0"
      },
      body: JSON.stringify({
        client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET,
        code: code
      })
    });

    const tokenData = await tokenResponse.json();
    
    if (!tokenResponse.ok || tokenData.error) {
      console.error("GitHub OAuth error:", tokenData);
      return response.status(400).json({ error: tokenData.error_description || "OAuth exchange failed." });
    }

    response.status(200).json({ 
      access_token: tokenData.access_token,
      scope: tokenData.scope,
      token_type: tokenData.token_type
    });

  } catch (error) {
    console.error("Unhandled exception in /api/github-auth:", error);
    response.status(500).json({ error: "An internal authentication error occurred." });
  }
}
