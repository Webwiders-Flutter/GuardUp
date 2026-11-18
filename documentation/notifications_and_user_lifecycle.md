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
| anything → `REJECTED` | The user: "Application not approved" with the reason, or the rejected document names | No |
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

Stored in the `public.notification_type` enum. The admin app mirrors it in
`guardup_admin/lib/features/notifications/data/enums/notification_type.enum.dart`.

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
| `is_active` | Only active devices receive pushes |
| `last_active_at` | Last time the app registered this device |

The app should call the database function **`register_user_device(p_token, p_platform)`**
after login and whenever Firebase gives a new token. It safely moves the token to the
current user (useful when two people log in on the same phone).

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
| `register_user_device(token, platform)` | RPC (logged-in users) | Saves / updates the current user's device token. |
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

## 12. Not Done Yet

- The **mobile app** does not yet register device tokens (`register_user_device`), so pushes
  only reach users after that is added. In-app notification rows are already created.
- Notifications and emails are **English only** for now.
- Booking / payment notifications will be added as those features are built.
