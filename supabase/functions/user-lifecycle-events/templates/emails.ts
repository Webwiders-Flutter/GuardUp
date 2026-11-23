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
  rejectionReason?: string;
  rejectedDocuments?: string;
}): EmailContent {
  const { event, support, rejectionReason, rejectedDocuments } = params;
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
            support.openAppUrl ? button("Open GuardUp", support.openAppUrl) : "",
          ].join(""),
        }),
      };

    case "REJECTED": {
      const reasonDetail = rejectionReason
        ? `Reason: ${escapeHtml(rejectionReason)}`
        : rejectedDocuments
        ? `Rejected documents: ${escapeHtml(rejectedDocuments)}`
        : "";

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
            reasonDetail
              ? paragraph(
                  `<strong>${reasonDetail}</strong><br><br>Please open the GuardUp app to update your details or re-upload the required documents to resubmit your profile for review.`,
                )
              : paragraph(
                  "This is usually due to missing, unclear or expired documents. Please open the GuardUp app to review your submission and re-upload any required documents.",
                ),
            support.openAppUrl ? button("Open GuardUp App", support.openAppUrl) : "",
          ].join(""),
        }),
      };
    }

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
