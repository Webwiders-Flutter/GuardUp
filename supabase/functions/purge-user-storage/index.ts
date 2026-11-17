import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { authorizeSystemOrAdmin } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/http.ts";

/** Buckets whose files live under a "<user_id>/" folder. */
const USER_BUCKETS = ["documents", "avatars"];

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Storage list() page size and remove() batch size. */
const PAGE_SIZE = 1000;

type StorageClient = ReturnType<typeof createClient>["storage"];

/** Recursively collects every object path under [prefix] in [bucket]. */
async function listAllPaths(storage: StorageClient, bucket: string, prefix: string): Promise<string[]> {
  const paths: string[] = [];
  let offset = 0;

  while (true) {
    const { data, error } = await storage.from(bucket).list(prefix, { limit: PAGE_SIZE, offset });
    if (error) throw new Error(`list ${bucket}/${prefix}: ${error.message}`);
    if (!data || data.length === 0) break;

    for (const item of data) {
      const path = `${prefix}/${item.name}`;
      // Folders have no id; files do.
      if (item.id === null) {
        paths.push(...(await listAllPaths(storage, bucket, path)));
      } else {
        paths.push(path);
      }
    }

    if (data.length < PAGE_SIZE) break;
    offset += PAGE_SIZE;
  }

  return paths;
}

/**
 * purge-user-storage
 *
 * Deletes every file under "<user_id>/" in the user buckets. Called by the
 * database (public.purge_user_storage) when a user who was never approved is
 * hard-deleted. See documentation/user_deletion.md.
 *
 * Body: { "user_id": "<uuid>" }
 */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
    if (!supabaseUrl || !supabaseServiceKey) {
      return json({ success: false, error: "Missing Supabase server credentials" }, 500);
    }

    const auth = await authorizeSystemOrAdmin(req, supabaseUrl, supabaseServiceKey);
    if (!auth.authorized) {
      return json({ success: false, error: auth.error }, auth.status || 401);
    }

    const { user_id } = await req.json();
    // Strict check: an empty or malformed id would target the bucket root.
    if (typeof user_id !== "string" || !UUID_PATTERN.test(user_id)) {
      return json({ success: false, error: "Field 'user_id' must be a valid UUID." }, 400);
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);
    const removed: Record<string, number> = {};
    const errors: string[] = [];

    for (const bucket of USER_BUCKETS) {
      try {
        const paths = await listAllPaths(supabaseAdmin.storage, bucket, user_id);
        for (let i = 0; i < paths.length; i += PAGE_SIZE) {
          const { error } = await supabaseAdmin.storage.from(bucket).remove(paths.slice(i, i + PAGE_SIZE));
          if (error) throw new Error(`remove ${bucket}: ${error.message}`);
        }
        removed[bucket] = paths.length;
      } catch (error) {
        errors.push(error instanceof Error ? error.message : String(error));
      }
    }

    console.log(`[PURGE] user=${user_id} removed=${JSON.stringify(removed)} errors=${errors.length}`);
    return json({ success: errors.length === 0, user_id, removed, errors }, errors.length ? 207 : 200);
  } catch (error) {
    console.error("purge-user-storage error:", error);
    return json(
      { success: false, error: error instanceof Error ? error.message : "Internal Server Error" },
      500,
    );
  }
});
