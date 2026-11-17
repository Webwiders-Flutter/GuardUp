import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { SendNotificationPayload } from "./types.ts";
import { authorizeSystemOrAdmin } from "../_shared/auth.ts";
import { getGoogleAccessToken } from "./services/fcm-auth.ts";
import { sendFcmHttpV1Message } from "./services/fcm-client.ts";
import {
  cleanupFailedTokens,
  sendFcmMulticastParallel,
} from "./services/multicast-dispatcher.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/**
 * send-notification
 *
 * Delivers FCM push notifications. Callable only by the database (x-internal-secret
 * header, e.g. the notifications INSERT trigger) or by an ADMIN user session.
 *
 * Actions:
 *  - send_to_user_ids (default): pushes to all active devices of the users,
 *    optionally saving in-app rows to public.notifications (save_to_db).
 *  - send_to_tokens: pushes to explicit FCM tokens.
 *  - send_to_topic: pushes to an FCM topic.
 *
 * Runs in simulation mode (logs only) when FIREBASE_SERVICE_ACCOUNT is not set.
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

    // 1. Authorize caller (system or admin)
    const auth = await authorizeSystemOrAdmin(req, supabaseUrl, supabaseServiceKey);
    if (!auth.authorized) {
      return json({ success: false, error: auth.error }, auth.status || 401);
    }

    // 2. Parse & validate payload
    const payload: SendNotificationPayload = await req.json();
    const {
      action = "send_to_user_ids",
      user_ids,
      topic,
      tokens,
      title = "",
      body = "",
      type = "SYSTEM",
      data = {},
      image_url,
      save_to_db = true,
      force = false,
    } = payload;

    if (!title || !body) {
      return json({ success: false, error: "Both title and body are required." }, 400);
    }

    // FCM data values must be strings
    const stringData: Record<string, string> = {};
    for (const [k, v] of Object.entries(data ?? {})) {
      if (k === "_push_handled") continue;
      stringData[k] = typeof v === "string" ? v : JSON.stringify(v);
    }
    stringData["type"] = type;

    const notification = { title, body, image: image_url };

    // 3. Google OAuth token for FCM HTTP v1
    const googleAuth = await getGoogleAccessToken();
    const isSimulated = !googleAuth.success || !googleAuth.token || !googleAuth.projectId;
    if (isSimulated) {
      console.warn(
        `[PUSH SIMULATION] FCM credentials unavailable: ${googleAuth.reason}. action=${action}, title="${title}"`,
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // -------------------------------------------------------------------------
    // ACTION: send_to_topic
    // -------------------------------------------------------------------------
    if (action === "send_to_topic") {
      if (!topic) {
        return json({ success: false, error: "Field 'topic' is required for action 'send_to_topic'." }, 400);
      }

      let sent = 1;
      let failed = 0;
      if (!isSimulated) {
        const res = await sendFcmHttpV1Message({
          projectId: googleAuth.projectId!,
          accessToken: googleAuth.token!,
          messagePayload: {
            topic,
            notification: {
              title,
              body,
              ...(image_url ? { image: image_url } : {}),
            },
            data: stringData,
          },
        });
        sent = res.success ? 1 : 0;
        failed = res.success ? 0 : 1;
      }

      return json({ success: true, action, topic, simulated: isSimulated, summary: { sent, failed } });
    }

    // -------------------------------------------------------------------------
    // ACTION: send_to_tokens
    // -------------------------------------------------------------------------
    if (action === "send_to_tokens") {
      if (!tokens || tokens.length === 0) {
        return json({ success: false, error: "Field 'tokens' is required for action 'send_to_tokens'." }, 400);
      }

      let summary = { sent: tokens.length, failed: 0, failedTokens: [] as string[] };
      if (!isSimulated) {
        summary = await sendFcmMulticastParallel({
          projectId: googleAuth.projectId!,
          accessToken: googleAuth.token!,
          tokens,
          notification,
          data: stringData,
        });
        await cleanupFailedTokens(supabaseAdmin, summary.failedTokens);
      }

      return json({
        success: true,
        action,
        simulated: isSimulated,
        summary: { sent: summary.sent, failed: summary.failed },
      });
    }

    // -------------------------------------------------------------------------
    // ACTION: send_to_user_ids (default)
    // -------------------------------------------------------------------------
    if (!user_ids || user_ids.length === 0) {
      return json({ success: false, error: "Field 'user_ids' is required for action 'send_to_user_ids'." }, 400);
    }

    // In-app rows are saved for every target user, even if push is disabled.
    if (save_to_db) {
      const rows = user_ids.map((uid) => ({
        user_id: uid,
        type,
        title,
        body,
        data: { ...data, _push_handled: "true" },
        image_url,
      }));
      const { error: insertError } = await supabaseAdmin.from("notifications").insert(rows);
      if (insertError) {
        console.warn("Could not save notifications:", insertError.message);
      }
    }

    // Skip users who turned push notifications off (unless forced)
    let targetUserIds = user_ids;
    if (!force) {
      const { data: users, error: userError } = await supabaseAdmin
        .from("users")
        .select("id")
        .in("id", user_ids)
        .eq("is_push_notification_enabled", true);

      if (!userError && users) {
        targetUserIds = users.map((u) => u.id);
      }
    }

    if (targetUserIds.length === 0) {
      return json({
        success: true,
        message: "All target users have push notifications disabled.",
        summary: { sent: 0, failed: 0 },
      });
    }

    const { data: devices, error: deviceError } = await supabaseAdmin
      .from("user_devices")
      .select("token")
      .in("user_id", targetUserIds)
      .eq("is_active", true);

    if (deviceError) {
      return json({ success: false, error: deviceError.message }, 500);
    }

    const deviceTokens = [...new Set((devices ?? []).map((d) => d.token).filter(Boolean))];

    let summary = { sent: deviceTokens.length, failed: 0, failedTokens: [] as string[] };
    if (!isSimulated && deviceTokens.length > 0) {
      summary = await sendFcmMulticastParallel({
        projectId: googleAuth.projectId!,
        accessToken: googleAuth.token!,
        tokens: deviceTokens,
        notification,
        data: stringData,
      });
      await cleanupFailedTokens(supabaseAdmin, summary.failedTokens);
    }

    return json({
      success: true,
      action,
      simulated: isSimulated,
      recipients_count: targetUserIds.length,
      devices_targeted: deviceTokens.length,
      summary: { sent: summary.sent, failed: summary.failed },
    });
  } catch (error) {
    console.error("send-notification error:", error);
    return json(
      { success: false, error: error instanceof Error ? error.message : "Internal Server Error" },
      500,
    );
  }
});
