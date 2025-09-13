const CLIENT_ID = "Ov23li5lrElFr3sMHxBA";
const CLIENT_SECRET = "891e47ef39fb6cf13a98226246552d5a227bba9a";

export default async function handler(request, response) {
  if (request.method !== 'POST') {
    response.setHeader('Allow', ['POST']);
    return response.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { code } = JSON.parse(request.body);
    if (!code) return response.status(400).json({ error: 'Code required' });

    const tokenResponse = await fetch('https://github.com/login/oauth/access_token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify({ client_id: CLIENT_ID, client_secret: CLIENT_SECRET, code })
    });

    const tokenData = await tokenResponse.json();
    if (tokenData.error) return response.status(400).json({ error: tokenData.error_description });

    response.status(200).json({
      access_token: tokenData.access_token,
      scope: tokenData.scope,
      token_type: tokenData.token_type
    });
  } catch (error) {
    console.error('OAuth error:', error);
    response.status(500).json({ error: 'Internal server error' });
  }
}
