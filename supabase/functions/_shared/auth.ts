import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/** Header the database triggers send (see public.invoke_edge_function). */
export const INTERNAL_SECRET_HEADER = "x-internal-secret";

/** Compares two strings in constant time to avoid timing attacks. */
function timingSafeEqual(a: string, b: string): boolean {
  const encoder = new TextEncoder();
  const aBytes = encoder.encode(a);
  const bBytes = encoder.encode(b);
  if (aBytes.length !== bBytes.length) return false;

  let diff = 0;
  for (let i = 0; i < aBytes.length; i++) {
    diff |= aBytes[i] ^ bBytes[i];
  }
  return diff === 0;
}

/**
 * Allows a request when it comes from:
 *   1. The database (x-internal-secret header equals INTERNAL_FUNCTION_SECRET), or
 *   2. A signed-in user whose public.users.role is ADMIN (Authorization: Bearer <user JWT>).
 *
 * Functions using this are deployed with verify_jwt = false (supabase/config.toml),
 * so this check is the only gate: never trust unverified JWT claims here.
 */
export async function authorizeSystemOrAdmin(
  req: Request,
  supabaseUrl: string,
  serviceKey: string,
): Promise<{ authorized: boolean; error?: string; status?: number }> {
  // 1. System call from a database trigger
  const internalSecret = Deno.env.get("INTERNAL_FUNCTION_SECRET") || "";
  const providedSecret = req.headers.get(INTERNAL_SECRET_HEADER) || "";
  if (providedSecret) {
    if (internalSecret && timingSafeEqual(providedSecret, internalSecret)) {
      return { authorized: true };
    }
    return { authorized: false, error: "Invalid internal secret", status: 401 };
  }

  // 2. Admin user session (signature verified by Supabase Auth)
  const authHeader = req.headers.get("Authorization") || "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) {
    return { authorized: false, error: "Missing credentials", status: 401 };
  }

  const supabaseClient = createClient(supabaseUrl, serviceKey);
  const {
    data: { user },
    error: authError,
  } = await supabaseClient.auth.getUser(token);

  if (authError || !user) {
    return { authorized: false, error: "Invalid or expired session", status: 401 };
  }

  const { data: profile, error: profileError } = await supabaseClient
    .from("users")
    .select("role")
    .eq("id", user.id)
    .single();

  if (profileError || !profile || profile.role?.toUpperCase() !== "ADMIN") {
    return {
      authorized: false,
      error: "Unauthorized: only system or admin can call this function",
      status: 403,
    };
  }

  return { authorized: true };
}
