# 🔔 GuardUp – Notifications, User Lifecycle & Triggers

This document explains, in simple words, how GuardUp sends notifications and emails
when something happens to a user account (for example, when an admin approves a bodyguard).

---

## 1. The Big Picture

Everything starts in the database. When a user's `status` changes, the database itself
reacts. Nobody has to remember to "send a notification" from the app.

```
Admin approves a user in the Admin Panel
        │
        ▼
public.users.status changes  (PENDING_APPROVAL → ACTIVE)
        │
        ▼
Trigger: trg_users_lifecycle_events
        │
        ├──► inserts a row in public.notifications   (in-app notification)
        │           │
        │           ▼
        │    Trigger: trigger_on_notification_inserted
        │           │
        │           ▼
        │    Edge Function: send-notification  ──►  Firebase (FCM)  ──►  user's phone
        │
        └──► Edge Function: user-lifecycle-events  ──►  email to the user
```

Two simple rules:

1. **Every notification is a row in `public.notifications`.** Inserting a row is enough:
   the push is sent automatically.
2. **Emails are only sent for important events** (approved, rejected, deleted).

How deleting users works is explained in [user_deletion.md](user_deletion.md).
How applications are reviewed (approve / reject with a reason) is explained in
[user_review_and_rejection.md](user_review_and_rejection.md).

---

## 2. User Statuses

Every user in `public.users` has a `status`:

| Status | Meaning |
|---|---|
| `INCOMPLETE` | Bodyguard / company signed up but has not finished their profile yet. |
| `PENDING_APPROVAL` | Profile submitted, waiting for an admin to review it. |
| `REJECTED` | An admin rejected the profile or one of its documents. The reason is in `users.rejection_reason` (profile) or `user_documents.rejection_reason` (document). |
| `ACTIVE` | Approved and allowed to use the app. Customers start here directly. |
| `BLOCKED` | Admin suspended the account. |
| `DELETED` | Account removed. The login is always deleted. The profile row is kept only for users who were approved before (see [user_deletion.md](user_deletion.md)). |

Rejecting an application sets `REJECTED` and keeps the user (nothing is deleted).
See [user_review_and_rejection.md](user_review_and_rejection.md).

---

## 3. What Happens on Each Status Change

| Status change | Who gets an in-app + push notification | Email sent? |
|---|---|---|
| `INCOMPLETE` → `PENDING_APPROVAL` | **All admins**: "New registration: {name}" | No |
| `PENDING_APPROVAL` / `REJECTED` → `ACTIVE` | The user: "Account approved" | ✅ Approved email |
| anything → `REJECTED` | The user: "Application not approved" with the reason, or the rejected document names | ✅ Rejected email (with reason/documents) |
| anything → `BLOCKED` | The user: "Account suspended" | No |
| `BLOCKED` → `ACTIVE` | The user: "Account restored" | No |
| `PENDING_APPROVAL` → `DELETED` **by an admin** | The user: "Application not approved" (push only, see below) | ✅ Rejected email |
| `INCOMPLETE` / `PENDING_APPROVAL` / `REJECTED` → `DELETED` otherwise | The user: "Account deleted" (push only; none for a self-delete) | ✅ Deleted email |
| `ACTIVE` / `BLOCKED` → `DELETED` | The user: "Account deleted" | ✅ Deleted email |

Notes:
- When the user was never approved, their row (with its notifications and devices) is
  removed in the same transaction, so no in-app notification is stored. The push is sent
  straight to their device tokens instead, and the email still goes out.
- "By an admin" means the change was not made by the user themselves (`auth.uid()`).
- Admin accounts never trigger these events.
- A customer signing up does **not** trigger anything (customers start as `ACTIVE`).
- If something fails (for example, the email service is down), the status change still
  succeeds. Problems are only written to the logs.

---

## 4. Notification Types

Stored in the `public.notification_type` enum. Both the mobile app and admin app mirror it in:
- `guardup/lib/features/notifications/data/enums/notification_type.enum.dart`
- `guardup_admin/lib/features/notifications/data/enums/notification_type.enum.dart`

| Type | Used for |
|---|---|
| `ACCOUNT_APPROVED` | User was approved |
| `ACCOUNT_REJECTED` | Application rejected: in-app + push when the status becomes `REJECTED`; push only when a pending user is deleted by an admin |
| `ACCOUNT_BLOCKED` | User was blocked |
| `ACCOUNT_UNBLOCKED` | User was unblocked |
| `ACCOUNT_DELETED` | User was deleted |
| `NEW_USER_REGISTRATION` | Sent to admins when someone submits their profile |
| `SYSTEM` | General / manual messages (and fallback for unknown types in the app) |

---

## 5. Database Tables

### `public.notifications` – the in-app inbox

| Column | What it holds |
|---|---|
| `user_id` | Who receives it |
| `type` | One of the notification types above |
| `title`, `body` | The text shown to the user |
| `data` | Extra JSON (e.g. which user it is about). Sent to the phone with the push. |
| `image_url` | Optional image |
| `is_read`, `read_at` | Read status. `read_at` is filled automatically when `is_read` becomes true. |

Who can do what:
- Users can **see, mark as read and delete** their own notifications.
- Only **admins** (and the system) can **create** notifications.
- Realtime is enabled, so the app can show new notifications instantly.

### `public.user_devices` – where to send pushes

One row per phone (FCM token).

| Column | What it holds |
|---|---|
| `user_id` | Owner of the device |
| `token` | Firebase Cloud Messaging token (unique) |
| `platform` | `android`, `ios` or `web` |
| `language_code` | Language this device gets pushes in (`en`, `hi`, …). Default `en`. |
| `is_active` | Only active devices receive pushes |
| `last_active_at` | Last time the app registered this device |

The app should call the database function
**`register_user_device(p_token, p_platform, p_language_code)`** after login and whenever
Firebase gives a new token. Everything is keyed on the **token** (one token = one device):

| Situation | What happens |
|---|---|
| Token not in the table yet | A new row is created with the user, platform and language. |
| Token already in the table | The row moves to the logged-in user (two people on one phone), is re-activated and gets the language sent. If no language is sent, it keeps its current one. |
| User changes the app language | The app calls **`update_user_device_language(p_token, p_language_code)`**. Only that device's row changes. If the token is not registered yet, the app registers it instead. |
| Two devices with different languages | Two rows, each with its own language. A user can get English on one phone and Hindi on another. |
| Firebase gives a new token | It is registered as a new row. The old token is deleted after its first failed push. |

Language codes are stored lower-case and without the region (`en-US` → `en`).

Dead tokens (uninstalled app, expired token) are deleted automatically after a failed push.

### `public.users.is_push_notification_enabled`

If a user turns this off, they still get in-app notifications, but no push.

---

## 6. Database Functions & Triggers

| Name | Type | What it does |
|---|---|---|
| `trg_users_lifecycle_events` → `handle_user_lifecycle_events()` | Trigger on `users` | Watches `status` changes: notifications / emails (section 3) **and** the deletion rules in [user_deletion.md](user_deletion.md). |
| `trigger_on_notification_inserted` → `handle_notification_inserted()` | Trigger on `notifications` | Every new row → asks `send-notification` to push it. |
| `invoke_edge_function(name, payload)` | Internal helper | Calls an Edge Function in the background. Only the database can use it. |
| `create_and_send_notification(user_ids[], title, body, type, data, image_url)` | RPC (admins only) | Sends the same notification to many users at once. |
| `register_user_device(token, platform, language_code)` | RPC (logged-in users) | Creates / updates the current user's device row for this token. |
| `update_user_device_language(token, language_code)` | RPC (logged-in users) | Changes the push language of one of your devices. |
| `handle_notification_read_at()` | Trigger on `notifications` | Fills / clears `read_at` when `is_read` changes. |
| `delete_user(p_user_id)` | RPC (logged-in users) | Deletes your own account, or any non-admin user if you are an admin. See [user_deletion.md](user_deletion.md). |
| `trg_users_guard_status_and_role` | Trigger on `users` | Stops users changing their own `status` / `role` (only `INCOMPLETE` → `PENDING_APPROVAL` is allowed). |

Migrations (in `supabase/migrations/`):

| File | Adds |
|---|---|
| `20261117000010_create_user_devices_table.sql` | `user_devices` + `register_user_device` |
| `20261117000011_create_notifications_table.sql` | `notifications`, base types, `is_push_notification_enabled` |
| `20261117000012_notification_push_trigger.sql` | `invoke_edge_function`, push trigger, `create_and_send_notification` |
| `20261117000013_add_lifecycle_notification_types.sql` | Lifecycle notification types |
| `20261117000014_user_lifecycle_events_trigger.sql` | The user lifecycle trigger (first version) |
| `20261117000015_remove_rejected_user_status.sql` | Removed `REJECTED` from `user_status` (added back later) |
| `20261117000016_user_deletion_rules.sql` | Lifecycle trigger, deletion rules, `delete_user` |
| `20261117000017_protect_user_status_and_role.sql` | Status / role guard |
| `20261117000018_restrict_registration_conflict_cleanup.sql` | Safer signup cleanup |
| `20261118000000_add_rejected_user_status.sql` | Adds `REJECTED` back to `user_status` |
| `20261118000001_user_rejection_flow.sql` | Current lifecycle trigger (`REJECTED` notification), `rejection_reason`, review triggers |
| `20261118000011_add_language_code_to_user_devices.sql` | `user_devices.language_code`, `register_user_device` with language, `update_user_device_language` |
| `20261118000014_allow_rejected_user_to_resubmit_profile.sql` | Allows rejected users to update bio/services/documents to resubmit profile |
| `20261119000015_send_email_on_profile_rejection.sql` | Sends notification email on application rejection with reason/documents |
| `20261123000018_add_deeplink_base_url_to_admin_settings.sql` | Adds `admin_settings.deeplink_base_url` used by the "Open GuardUp" email buttons |

---

## 7. Edge Functions

Located in `supabase/functions/`.

| Function | Job |
|---|---|
| `send-notification` | Sends push notifications through Firebase (FCM). Can target user ids, raw tokens or a topic. |
| `user-lifecycle-events` | Sends the approved / rejected / deleted emails (dark GuardUp theme). |
| `purge-user-storage` | Deletes a removed user's uploaded files (see [user_deletion.md](user_deletion.md)). |
| `_shared/` | Code used by all of them: security check, email sending, small helpers. |

Email templates live in `supabase/functions/user-lifecycle-events/templates/`.
Support email, phone, WhatsApp and app link in the emails come from the
`admin_settings` table, so the admin can change them without a deploy.

**"Open GuardUp" button:** links to `<deeplink_base_url>/download`
(Admin → Settings → Mobile Apps → Deep Linking). That host serves
`/.well-known/assetlinks.json` (Android App Links) and
`/.well-known/apple-app-site-association` (iOS Universal Links) for the
`/download` path, so the link opens the installed app directly; without the app
it shows the web `/download` page. If `deeplink_base_url` is empty the button
falls back to `android_app_url` (Play Store).

**Email logo:** the header shows the app logo from
`<deeplink_base_url>/icons/icon-192.png` (served from `guardup_admin/web/icons/`).
If `deeplink_base_url` is empty, a shield emoji badge is shown instead.

**Simulation mode:** if Firebase or email credentials are missing, the functions do not
fail. They just write what they *would* have sent to the logs. Handy for testing.

---

## 8. Security (who is allowed to call the functions)

The Edge Functions accept only two kinds of callers:

1. **The database** – it sends a secret header `x-internal-secret`. The same secret is
   stored in two places that must always match:
   - Supabase **Vault** as `internal_function_secret` (read by the database)
   - Edge Function secret `INTERNAL_FUNCTION_SECRET` (read by the functions)
2. **A logged-in admin** – using their normal login session.

Why a separate secret instead of the `service_role` key? The service role key can do
anything in the database. The internal secret can only call our functions, so if it ever
leaks, the damage is small. It also keeps working when Supabase changes its key formats.

Because of this, `supabase/config.toml` turns off Supabase's built-in JWT check
(`verify_jwt = false`) for these functions. The functions do the check themselves.

---

## 9. Secrets & Setup

All function secrets live in `supabase/.env` (never committed; see `supabase/.env.example`).

| Secret | Needed for |
|---|---|
| `INTERNAL_FUNCTION_SECRET` | Database → function calls. Generate with `openssl rand -hex 32`. |
| `FIREBASE_SERVICE_ACCOUNT` | Push notifications (Firebase service account JSON, on one line). |
| `EMAIL_FROM` | Sender of emails, e.g. `GuardUp <address>`. Must be allowed by your email provider. |
| `RESEND_API_KEY` **or** `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASSWORD` | Sending emails. |

The database cannot read `.env`, so the internal secret must **also** be added to Vault once:

```sql
select vault.create_secret('<same value as INTERNAL_FUNCTION_SECRET>', 'internal_function_secret');
```

### Deploy

Run from the repository root:

```bash
supabase db push
supabase secrets set --env-file ./supabase/.env
supabase functions deploy send-notification
supabase functions deploy user-lifecycle-events
supabase functions deploy purge-user-storage
```

Changed only a secret? Run `supabase secrets set ...` again; no redeploy needed.
Changed function code or email templates? Redeploy that function.

---

## 10. Common Tasks

### Send a notification to some users (admin)

```sql
select * from create_and_send_notification(
  array['<user-uuid-1>', '<user-uuid-2>']::uuid[],
  'Scheduled maintenance',
  'GuardUp will be unavailable tonight from 2 AM to 4 AM.'
);
```

Or simply insert a row into `public.notifications`; the push is sent automatically.

### Add a new notification type

1. New migration: `ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'MY_TYPE';`
   (keep it in its own migration file; Postgres needs it committed before it can be used).
2. Add the value to `notification_type.enum.dart` in the admin app (and the mobile app
   when it has one). Unknown types show as `SYSTEM` in older app versions, so nothing crashes.
3. Insert notifications with the new type wherever needed.

### Change an email's text or design

Edit `supabase/functions/user-lifecycle-events/templates/emails.ts` (text) or
`layout.ts` (design), then redeploy `user-lifecycle-events`.

---

## 11. Troubleshooting

| Problem | Where to look / what to check |
|---|---|
| No notification row created | Did the `status` really change? Admin users are ignored. A user who was never approved is removed, so they get a push but no row. Check Postgres logs for `User lifecycle notification failed`. |
| Row created but no push | Does the user have an active row in `user_devices`? Is `is_push_notification_enabled` true? Check `send-notification` logs. |
| Push log says "simulation" | `FIREBASE_SERVICE_ACCOUNT` is missing or invalid. |
| Email not received | Check `user-lifecycle-events` logs. "Simulation" = no email provider set. Also check spam, and that `EMAIL_FROM` matches your provider. |
| Logs say `Invalid internal secret` (401) | Vault `internal_function_secret` and `INTERNAL_FUNCTION_SECRET` are different. |
| Postgres warning `internal_function_secret is not set` | Add the secret to Vault (section 9). |

See the last calls the database made to the functions:

```sql
select status_code, content, created
from net._http_response
order by created desc
limit 10;
```

---

## 12. Implementation Status & Next Steps

- ✅ **Mobile app device registration & notifications**: The mobile app (`guardup`) automatically registers device tokens (`register_user_device`), updates language preferences (`update_user_device_language`), and displays notifications via BLoC (`NotificationsBloc`, `UnreadNotificationCountCubit`, `UserDeviceCubit`).
- Notifications and emails are **English only** for now. Each device already stores its
  `language_code`, but `send-notification` sends the same text to every device. Sending
  translated text per language (like Supplr's English/Hindi groups) needs translated
  title/body fields first.
- Booking / payment notifications will be added as those features are built.
