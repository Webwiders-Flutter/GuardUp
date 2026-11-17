import { escapeHtml } from "../../_shared/http.ts";
import { LifecycleEmailEvent, SupportSettings } from "../types.ts";
import { accents, button, paragraph, renderLayout, strong } from "./layout.ts";

export interface EmailContent {
  subject: string;
  html: string;
}

/** Builds the subject + HTML for a lifecycle email. */
export function buildLifecycleEmail(params: {
  event: LifecycleEmailEvent;
  name: string;
  roleLabel: string;
  support: SupportSettings;
}): EmailContent {
  const { event, support } = params;
  const name = strong(escapeHtml(params.name));
  const roleLabel = strong(escapeHtml(params.roleLabel));
  const greeting = paragraph(`Hello ${name},`);

  switch (event) {
    case "APPROVED":
      return {
        subject: "Your GuardUp account has been approved",
        html: renderLayout({
          title: "Account approved - GuardUp",
          heading: "Welcome to GuardUp",
          highlight: { label: "Account status", value: "APPROVED", accent: accents.success },
          support,
          contentHtml: [
            greeting,
            paragraph(
              `Great news! Your ${roleLabel} profile has been verified and approved by our team. You can now start receiving bookings on GuardUp.`,
            ),
            support.androidAppUrl ? button("Open GuardUp", support.androidAppUrl) : "",
          ].join(""),
        }),
      };

    case "REJECTED":
      return {
        subject: "Update on your GuardUp application",
        html: renderLayout({
          title: "Application update - GuardUp",
          heading: "Application update",
          highlight: { label: "Account status", value: "NOT APPROVED", accent: accents.danger },
          support,
          contentHtml: [
            greeting,
            paragraph(
              `Thank you for applying to join GuardUp as a ${roleLabel}. After reviewing your profile and documents, we are unable to approve your application at this time.`,
            ),
            paragraph(
              "This is usually due to missing, unclear or expired documents. Your application and uploaded documents have been removed, so you are welcome to register again with the same email and phone number. Please contact our support team if you would like to know what is needed before re-applying.",
              { small: true },
            ),
          ].join(""),
        }),
      };

    case "DELETED":
      return {
        subject: "Your GuardUp account has been deleted",
        html: renderLayout({
          title: "Account deleted - GuardUp",
          heading: "Account deleted",
          highlight: { label: "Account status", value: "DELETED", accent: accents.neutral },
          support,
          contentHtml: [
            greeting,
            paragraph(
              "This email confirms that your GuardUp account has been deleted and you can no longer sign in.",
            ),
            paragraph(
              "Some records, such as completed transactions, may be kept for the period required by law. If you did not request this, please contact our support team immediately.",
              { small: true },
            ),
          ].join(""),
        }),
      };
  }
}
