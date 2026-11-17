/** Events that send an email. In-app + push notifications are created in SQL. */
export type LifecycleEmailEvent = "APPROVED" | "REJECTED" | "DELETED";

export interface UserLifecyclePayload {
  event: LifecycleEmailEvent;
  user_id: string;
  email: string;
  name?: string;
  role?: string;
}

export interface SupportSettings {
  supportEmail: string;
  supportPhone: string;
  supportWhatsapp: string;
  androidAppUrl: string;
  iosAppUrl: string;
}
