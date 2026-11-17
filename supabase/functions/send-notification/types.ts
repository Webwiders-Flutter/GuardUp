export interface SendNotificationPayload {
  action?: "send_to_user_ids" | "send_to_topic" | "send_to_tokens";

  // Targeting options
  user_ids?: string[];
  topic?: string;
  tokens?: string[];

  // Content
  title?: string;
  body?: string;

  // Metadata & payload
  type?: string;
  data?: Record<string, unknown>;
  image_url?: string;

  // Options
  /** Insert rows into public.notifications (send_to_user_ids only). */
  save_to_db?: boolean;
  /** Ignore users.is_push_notification_enabled. */
  force?: boolean;
}

export interface GoogleAuthResult {
  success: boolean;
  token?: string;
  projectId?: string;
  reason?: string;
}

export interface DispatchSummary {
  sent: number;
  failed: number;
  failedTokens: string[];
}
