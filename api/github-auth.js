// TEMPORARY HARDCODE - OMNI-DAN-V3 EMERGENCY FIX
const CLIENT_ID = "Ov23li5lrElFr3sMHxBA";
const CLIENT_SECRET = "891e47ef39fb6cf13a98226246552d5a227bba9a";

// KEEP THE REST OF YOUR ORIGINAL CODE BELOW
export default async function handler(request, response) {
  if (request.method !== "POST") {
    response.setHeader("Allow", ["POST"]);
    return response.status(405).json({ error: "Method not allowed." });
  }
// ... rest of your original code
console.log("API Called - Environment:", process.env.NODE_ENV);
console.log("Client ID:", process.env.GITHUB_OAUTH_CLIENT_ID || "NOT SET");
console.log("Client Secret:", process.env.GITHUB_OAUTH_CLIENT_SECRET ? "SET" : "NOT SET");