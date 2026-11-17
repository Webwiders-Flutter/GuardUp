import { escapeHtml } from "../../_shared/http.ts";
import { SupportSettings } from "../types.ts";

/**
 * GuardUp dark email theme (matches the Supabase Auth verification email).
 *
 * Styles are inline and the layout is table-based on purpose: Gmail and
 * Outlook strip or ignore <style> blocks, so classes would render unstyled.
 * Gradients always have a solid background-color fallback for Outlook.
 */
const theme = {
  page: "#0F1015",
  card: "#161822",
  cardBorder: "#2A2D3D",
  divider: "#232738",
  headerFrom: "#1A1D2B",
  inset: "#0D0E14",
  footer: "#12141C",
  gold: "#D4AF37",
  goldLight: "#ECC870",
  goldDark: "#B88E28",
  heading: "#FFFFFF",
  text: "#94A3B8",
  muted: "#64748B",
  faint: "#475569",
  font: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
};

/** Status colours used for the highlight box on each email. */
export const accents = {
  gold: theme.gold,
  success: "#22C55E",
  danger: "#EF4444",
  neutral: "#64748B",
};

/**
 * Wraps `contentHtml` (already escaped) in the GuardUp shell:
 * brand header, heading, highlight box, body, support block and footer.
 */
export function renderLayout(params: {
  /** Browser / inbox preview title. */
  title: string;
  /** Large heading inside the card. */
  heading: string;
  /** Highlighted status box (like the OTP box) under the heading. */
  highlight: { label: string; value: string; accent: string };
  contentHtml: string;
  support: SupportSettings;
}): string {
  const { title, heading, highlight, contentHtml, support } = params;
  const supportEmail = escapeHtml(support.supportEmail);
  const supportPhone = escapeHtml(support.supportPhone);
  const whatsappDigits = support.supportWhatsapp.replace(/[^0-9]/g, "");
  const linkStyle = `color:${theme.goldLight};text-decoration:none;`;

  const supportLines = [
    `Email: <a href="mailto:${supportEmail}" style="${linkStyle}">${supportEmail}</a>`,
    supportPhone
      ? `Call: <a href="tel:${supportPhone}" style="${linkStyle}">${supportPhone}</a>`
      : "",
    whatsappDigits
      ? `WhatsApp: <a href="https://wa.me/${whatsappDigits}" style="${linkStyle}">${escapeHtml(support.supportWhatsapp)}</a>`
      : "",
  ].filter(Boolean).join("<br/>");

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="dark">
  <meta name="supported-color-schemes" content="dark">
  <title>${escapeHtml(title)}</title>
</head>
<body style="margin:0;padding:0;background-color:${theme.page};font-family:${theme.font};color:#E2E8F0;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color:${theme.page};padding:40px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:500px;background-color:${theme.card};border:1px solid ${theme.cardBorder};border-radius:16px;overflow:hidden;">

          <!-- Header -->
          <tr>
            <td align="center" style="padding:32px 24px 20px 24px;background-color:${theme.headerFrom};background-image:linear-gradient(180deg, ${theme.headerFrom} 0%, ${theme.card} 100%);border-bottom:1px solid ${theme.divider};">
              <div style="display:inline-block;width:52px;height:52px;line-height:52px;border-radius:14px;background-color:${theme.goldLight};background-image:linear-gradient(135deg, ${theme.goldLight} 0%, ${theme.goldDark} 100%);font-size:26px;text-align:center;margin-bottom:12px;">&#128737;&#65039;</div>
              <h1 style="margin:0;font-size:22px;font-weight:700;color:${theme.heading};">GuardUp Security</h1>
              <div style="margin-top:4px;font-size:12px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:${theme.gold};">Elite Protection Platform</div>
            </td>
          </tr>

          <!-- Content -->
          <tr>
            <td align="center" style="padding:32px 28px;">
              <h2 style="margin:0 0 20px 0;font-size:20px;font-weight:700;color:${theme.heading};">${escapeHtml(heading)}</h2>

              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin:0 0 24px 0;">
                <tr>
                  <td align="center" style="background-color:${theme.inset};border:2px dashed ${highlight.accent};border-radius:12px;padding:18px;">
                    <div style="font-size:12px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:${theme.muted};margin-bottom:6px;">${escapeHtml(highlight.label)}</div>
                    <div style="font-size:22px;font-weight:800;letter-spacing:3px;color:${highlight.accent};">${escapeHtml(highlight.value)}</div>
                  </td>
                </tr>
              </table>

              ${contentHtml}

              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-top:8px;">
                <tr>
                  <td style="border-top:1px solid ${theme.divider};padding-top:20px;text-align:center;">
                    <p style="margin:0 0 8px 0;font-size:13px;color:${theme.muted};">Need help? Our support team is here for you.</p>
                    <p style="margin:0;font-size:13px;line-height:1.8;color:${theme.text};">${supportLines}</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:20px 24px;border-top:1px solid ${theme.divider};background-color:${theme.footer};font-size:12px;color:${theme.faint};">
              &copy; ${new Date().getFullYear()} GuardUp Global Security Services. All rights reserved.
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

/** Body paragraph in the muted body colour. Pass already-escaped HTML. */
export function paragraph(html: string, options: { small?: boolean } = {}): string {
  const size = options.small ? 13 : 15;
  return `<p style="margin:0 0 20px 0;font-size:${size}px;line-height:1.6;color:${theme.text};">${html}</p>`;
}

/** Bold white inline text, for names and roles inside paragraphs. */
export function strong(text: string): string {
  return `<strong style="color:#FFFFFF;">${text}</strong>`;
}

/** Gold call-to-action button. */
export function button(label: string, url: string): string {
  return `<table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin:4px auto 24px auto;">
  <tr>
    <td align="center" style="border-radius:10px;background-color:${theme.goldLight};background-image:linear-gradient(135deg, ${theme.goldLight} 0%, ${theme.goldDark} 100%);">
      <a href="${escapeHtml(url)}" target="_blank" style="display:inline-block;padding:13px 30px;font-size:15px;font-weight:700;color:${theme.page};text-decoration:none;border-radius:10px;">${escapeHtml(label)}</a>
    </td>
  </tr>
</table>`;
}
