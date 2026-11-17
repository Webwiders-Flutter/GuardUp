/**
 * Sends a single message using FCM HTTP v1 API
 */
export async function sendFcmHttpV1Message(params: {
  projectId: string;
  accessToken: string;
  messagePayload: Record<string, unknown>;
}): Promise<{ success: boolean; error?: string; status?: number }> {
  const { projectId, accessToken, messagePayload } = params;
  const endpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const res = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({ message: messagePayload }),
  });

  if (!res.ok) {
    const errorBody = await res.text();
    return {
      success: false,
      error: errorBody,
      status: res.status,
    };
  }

  return { success: true };
}
