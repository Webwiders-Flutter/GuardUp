import nodemailer from "npm:nodemailer@6.9.16";

export interface EmailMessage {
  to: string | string[];
  subject: string;
  html: string;
  text?: string;
  replyTo?: string;
}

export interface EmailResult {
  provider: "resend" | "smtp" | "simulated";
  messageId?: string;
}

/**
 * Sends an email through the first configured provider:
 *   1. Resend  (RESEND_API_KEY)
 *   2. SMTP    (SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD)
 *   3. Simulation (logs only) when neither is configured.
 *
 * Sender address comes from EMAIL_FROM, e.g. "GuardUp <no-reply@yourdomain.com>".
 */
export async function sendEmail(message: EmailMessage): Promise<EmailResult> {
  const to = Array.isArray(message.to) ? message.to : [message.to];
  const from = Deno.env.get("EMAIL_FROM") || "GuardUp <no-reply@guardup.com>";
  const text = message.text || message.html.replace(/<[^>]*>?/gm, "");

  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  if (resendApiKey) {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${resendApiKey}`,
      },
      body: JSON.stringify({
        from,
        to,
        subject: message.subject,
        html: message.html,
        text,
        ...(message.replyTo ? { reply_to: message.replyTo } : {}),
      }),
    });

    if (!res.ok) {
      throw new Error(`Resend error (${res.status}): ${await res.text()}`);
    }
    const data = await res.json();
    return { provider: "resend", messageId: data.id };
  }

  const smtpUser = Deno.env.get("SMTP_USER");
  const smtpPass = Deno.env.get("SMTP_PASSWORD");
  if (smtpUser && smtpPass) {
    const host = Deno.env.get("SMTP_HOST") || "smtp.gmail.com";
    const port = Number(Deno.env.get("SMTP_PORT") || 465);

    const transporter = nodemailer.createTransport({
      host,
      port,
      secure: port === 465,
      auth: { user: smtpUser, pass: smtpPass },
    });

    const info = await transporter.sendMail({
      from,
      to: to.join(", "),
      replyTo: message.replyTo,
      subject: message.subject,
      text,
      html: message.html,
    });
    return { provider: "smtp", messageId: info.messageId };
  }

  console.log(
    `[EMAIL SIMULATION] No RESEND_API_KEY or SMTP credentials configured.\n` +
      `  From: ${from}\n  To: ${to.join(", ")}\n  Subject: ${message.subject}`,
  );
  return { provider: "simulated" };
}
