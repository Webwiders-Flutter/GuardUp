/** Events that send an email. In-app + push notifications are created in SQL. */
export type LifecycleEmailEvent = "APPROVED" | "REJECTED" | "DELETED";

export interface UserLifecyclePayload {
  event: LifecycleEmailEvent;
  user_id: string;
  email: string;
  name?: string;
  role?: string;
  rejection_reason?: string;
  rejected_documents?: string;
}

export interface SupportSettings {
  supportEmail: string;
  supportPhone: string;
  supportWhatsapp: string;
  androidAppUrl: string;
  iosAppUrl: string;
  /** `<deeplink_base_url>/download` – opens the installed app (App/Universal Link). */
  openAppUrl: string;
  /** `<deeplink_base_url>/icons/icon-192.png` – app logo for the email header. */
  logoUrl: string;
}
