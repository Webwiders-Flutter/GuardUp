import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { DispatchSummary } from "../types.ts";
import { sendFcmHttpV1Message } from "./fcm-client.ts";

/**
 * Sends a single chunk of tokens concurrently using Promise.all
 */
export async function sendMulticastChunk(params: {
  projectId: string;
  accessToken: string;
  tokens: string[];
  notification: { title: string; body: string; image?: string };
  data?: Record<string, string>;
}): Promise<Array<{ token: string; success: boolean; error?: string; status?: number }>> {
  const { projectId, accessToken, tokens, notification, data } = params;

  return await Promise.all(
    tokens.map(async (token) => {
      const messagePayload: Record<string, unknown> = {
        token,
        notification: {
          title: notification.title,
          body: notification.body,
          ...(notification.image ? { image: notification.image } : {}),
        },
        android: {
          priority: "HIGH",
          notification: {
            sound: "default",
            defaultSound: true,
            defaultVibrateTimings: true,
            channelId: "high_importance_channel",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      if (data && Object.keys(data).length > 0) {
        messagePayload.data = data;
      }

      const res = await sendFcmHttpV1Message({
        projectId,
        accessToken,
        messagePayload,
      });

      return {
        token,
        success: res.success,
        error: res.error,
        status: res.status,
      };
    }),
  );
}

/**
 * True when FCM reports the token itself as invalid / no longer registered,
 * i.e. it is safe to delete. Transient errors (quota, 5xx, auth) keep the token.
 */
function isDeadTokenError(status?: number, error?: string): boolean {
  const msg = error ?? "";
  return (
    status === 404 ||
    msg.includes("UNREGISTERED") ||
    (status === 400 && msg.includes("INVALID_ARGUMENT") && msg.toLowerCase().includes("token"))
  );
}

/**
 * Dispatches multicast messages across tokens in parallel chunks (up to 500 at a time)
 */
export async function sendFcmMulticastParallel(params: {
  projectId: string;
  accessToken: string;
  tokens: string[];
  notification: { title: string; body: string; image?: string };
  data?: Record<string, string>;
  chunkSize?: number;
}): Promise<DispatchSummary> {
  const { projectId, accessToken, tokens, notification, data, chunkSize = 500 } = params;

  if (tokens.length === 0) {
    return { sent: 0, failed: 0, failedTokens: [] };
  }

  // Split tokens into chunks
  const chunks: string[][] = [];
  for (let i = 0; i < tokens.length; i += chunkSize) {
    chunks.push(tokens.slice(i, i + chunkSize));
  }

  let sent = 0;
  let failed = 0;
  const failedTokens: string[] = [];

  const chunkResults = await Promise.all(
    chunks.map((chunk) =>
      sendMulticastChunk({
        projectId,
        accessToken,
        tokens: chunk,
        notification,
        data,
      }),
    ),
  );

  for (const chunkResult of chunkResults) {
    for (const r of chunkResult) {
      if (r.success) {
        sent++;
      } else {
        failed++;
        if (isDeadTokenError(r.status, r.error)) {
          failedTokens.push(r.token);
        } else {
          console.warn(`[PUSH] Transient FCM failure (HTTP ${r.status}): ${r.error}`);
        }
      }
    }
  }

  return { sent, failed, failedTokens };
}

/**
 * Removes dead (unregistered / invalid) FCM tokens from public.user_devices
 */
export async function cleanupFailedTokens(
  supabaseAdmin: ReturnType<typeof createClient>,
  failedTokens: string[],
): Promise<void> {
  if (failedTokens.length === 0) return;

  try {
    const { error } = await supabaseAdmin
      .from("user_devices")
      .delete()
      .in("token", failedTokens);

    if (error) {
      console.warn("Could not prune failed FCM tokens from user_devices:", error.message);
    } else {
      console.log(`[PUSH CLEANUP] Successfully removed ${failedTokens.length} dead token(s) from user_devices.`);
    }
  } catch (err) {
    console.warn("Exception pruning failed FCM tokens:", err);
  }
}
