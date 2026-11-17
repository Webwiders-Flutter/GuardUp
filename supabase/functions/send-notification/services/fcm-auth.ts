import { GoogleAuthResult } from "../types.ts";
import { signJwtWithWebCrypto } from "../utils/crypto.ts";

// In-memory cache for Google OAuth 2.0 access token to avoid re-authenticating on every request
let cachedAccessToken: { token: string; projectId: string; expiresAt: number } | null = null;

export async function getGoogleAccessToken(): Promise<GoogleAuthResult> {
  const now = Math.floor(Date.now() / 1000);

  // Return cached token if still valid (with 60-second grace window)
  if (cachedAccessToken && cachedAccessToken.expiresAt > now + 60) {
    return {
      success: true,
      token: cachedAccessToken.token,
      projectId: cachedAccessToken.projectId,
    };
  }

  const rawSecret = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!rawSecret) {
    return {
      success: false,
      reason: "FIREBASE_SERVICE_ACCOUNT secret is missing in Supabase Edge Function environment.",
    };
  }

  let serviceAccount: {
    client_email?: string;
    private_key?: string;
    project_id?: string;
  };

  try {
    serviceAccount = JSON.parse(rawSecret);
  } catch (err) {
    return {
      success: false,
      reason: `Failed to parse FIREBASE_SERVICE_ACCOUNT JSON: ${err instanceof Error ? err.message : String(err)}`,
    };
  }

  const { client_email, private_key, project_id } = serviceAccount;
  if (!client_email || !private_key || !project_id) {
    return {
      success: false,
      reason: "FIREBASE_SERVICE_ACCOUNT is missing client_email, private_key, or project_id.",
    };
  }

  try {
    const header = { alg: "RS256", typ: "JWT" };
    const payload = {
      iss: client_email,
      sub: client_email,
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
    };

    const signedJwt = await signJwtWithWebCrypto(header, payload, private_key);

    const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: signedJwt,
      }),
    });

    if (!tokenRes.ok) {
      const errText = await tokenRes.text();
      return {
        success: false,
        reason: `Google OAuth2 token endpoint returned HTTP ${tokenRes.status}: ${errText}`,
      };
    }

    const tokenData = await tokenRes.json();
    cachedAccessToken = {
      token: tokenData.access_token,
      projectId: project_id,
      expiresAt: now + (tokenData.expires_in || 3600),
    };

    return {
      success: true,
      token: cachedAccessToken.token,
      projectId: cachedAccessToken.projectId,
    };
  } catch (err) {
    return {
      success: false,
      reason: `Unexpected error generating Google OAuth access token: ${err instanceof Error ? err.message : String(err)}`,
    };
  }
}
