import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { authorizeSystemOrAdmin } from "../_shared/auth.ts";
import { sendEmail } from "../_shared/email.ts";
import { corsHeaders, json } from "../_shared/http.ts";
import { buildLifecycleEmail } from "./templates/emails.ts";
import { LifecycleEmailEvent, SupportSettings, UserLifecyclePayload } from "./types.ts";

const EMAIL_EVENTS: LifecycleEmailEvent[] = ["APPROVED", "REJECTED", "DELETED"];

function roleLabel(role?: string): string {
  switch (role?.toUpperCase()) {
    case "GUARD":
      return "Bodyguard";
    case "COMPANY":
      return "Security Company";
    default:
      return "Customer";
  }
}

/** Deployed web host (admin Firebase Hosting), without a trailing slash. */
function normalizeBaseUrl(deeplinkBaseUrl?: string | null): string {
  return deeplinkBaseUrl?.trim().replace(/\/+$/, "") || "";
}

/** Reads support contacts and app links from admin_settings, with defaults. */
async function loadSupportSettings(
  supabaseAdmin: ReturnType<typeof createClient>,
): Promise<SupportSettings> {
  const settings: SupportSettings = {
    supportEmail: "support@guardup.com",
    supportPhone: "",
    supportWhatsapp: "",
    androidAppUrl: "",
    iosAppUrl: "",
    openAppUrl: "",
    logoUrl: "",
  };

  const { data, error } = await supabaseAdmin
    .from("admin_settings")
    .select(
      "support_email, support_call_phone_number, support_whatsapp_phone_number, android_app_url, ios_app_url, deeplink_base_url",
    )
    .limit(1)
    .maybeSingle();

  if (error) {
    console.warn("Could not read admin_settings, using defaults:", error.message);
    return settings;
  }

  // `/download` opens the installed app via App Links / Universal Links;
  // falls back to the Play Store URL when no base URL is set.
  // The logo is the web app icon hosted on the same domain.
  const baseUrl = normalizeBaseUrl(data?.deeplink_base_url);

  return {
    supportEmail: data?.support_email || settings.supportEmail,
    supportPhone: data?.support_call_phone_number || "",
    supportWhatsapp: data?.support_whatsapp_phone_number || "",
    androidAppUrl: data?.android_app_url || "",
    iosAppUrl: data?.ios_app_url || "",
    openAppUrl: baseUrl ? `${baseUrl}/download` : data?.android_app_url || "",
    logoUrl: baseUrl ? `${baseUrl}/icons/icon-192.png` : "",
  };
}

/**
 * user-lifecycle-events
 *
 * Sends lifecycle emails (approved / rejected / deleted). Called by the
 * trg_users_lifecycle_events trigger on public.users via pg_net. In-app and
 * push notifications for the same events are created by that trigger in SQL.
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

    const payload: UserLifecyclePayload = await req.json();
    const { event, user_id, email, name, role, rejection_reason, rejected_documents } = payload;

    if (!EMAIL_EVENTS.includes(event)) {
      return json(
        { success: false, error: `Invalid event. Must be one of: ${EMAIL_EVENTS.join(", ")}` },
        400,
      );
    }
    if (!user_id || !email || !email.includes("@")) {
      return json({ success: false, error: "Fields 'user_id' and a valid 'email' are required." }, 400);
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);
    const support = await loadSupportSettings(supabaseAdmin);

    const { subject, html } = buildLifecycleEmail({
      event,
      name: name || "there",
      roleLabel: roleLabel(role),
      support,
      rejectionReason: rejection_reason,
      rejectedDocuments: rejected_documents,
    });

    const result = await sendEmail({
      to: email,
      subject,
      html,
      replyTo: support.supportEmail,
    });

    console.log(`[LIFECYCLE] event=${event} user=${user_id} email provider=${result.provider}`);
    return json({ success: true, event, user_id, email: result });
  } catch (error) {
    console.error("user-lifecycle-events error:", error);
    return json(
      { success: false, error: error instanceof Error ? error.message : "Internal Server Error" },
      500,
    );
  }
});
