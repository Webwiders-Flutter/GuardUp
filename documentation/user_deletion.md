# 🗑️ GuardUp – Deleting Users

How a user is deleted, what is removed, and which code does it.
Notifications and emails for these events are covered in
[notifications_and_user_lifecycle.md](notifications_and_user_lifecycle.md).
Rejecting an application (with a reason, without deleting) is covered in
[user_review_and_rejection.md](user_review_and_rejection.md).

---

## 1. The Rule

There is **one way** to delete a user: set `public.users.status = 'DELETED'`.
The database does everything else, based on the status the user had **before**:

| Status before | `public.users` row | Login (`auth.users`) | Uploaded files | Why |
|---|---|---|---|---|
| `INCOMPLETE` | ❌ Removed | ❌ Removed | ❌ Removed | Never approved, nothing worth keeping. |
| `PENDING_APPROVAL` | ❌ Removed | ❌ Removed | ❌ Removed | Same. |
| `REJECTED` | ❌ Removed | ❌ Removed | ❌ Removed | Same (never approved). |
| `ACTIVE` | ✅ Kept, `status = DELETED` | ❌ Removed | ✅ Kept | Keeps history (bookings, payments, documents). |
| `BLOCKED` | ✅ Kept, `status = DELETED` | ❌ Removed | ✅ Kept | Same. |

When the row is removed, everything linked to it goes too (`ON DELETE CASCADE`):
`user_documents`, `user_services`, `user_devices`, `notifications`.

In every case the email and phone number become free, so the person can register again.
(The unique indexes on email / phone ignore `DELETED` rows.)

> **Rejecting is not deleting.** The admin panel rejects by setting
> `status = REJECTED` (with a reason) and keeps the user
> ([user_review_and_rejection.md](user_review_and_rejection.md)).
> An admin *deleting* a `PENDING_APPROVAL` user still sends the "not approved" email and push.

---

## 2. Who Can Delete

Everyone goes through the **`delete_user`** RPC:

| Caller | Call | Allowed |
|---|---|---|
| A user (mobile app) | `rpc('delete_user')` (no params) | Their own account. |
| An admin (admin panel) | `rpc('delete_user', params: {'p_user_id': id})` | Any non-admin user. |
| Anyone else | | ❌ `Only admins can delete other users` |

- Admin accounts can't be deleted through the RPC (`Admin accounts cannot be deleted`).
- Calling it for a user who is already `DELETED` just makes sure their login is gone.
- Returns `{ "user_id", "previous_status", "hard_deleted" }`.

Deleting from the Supabase dashboard works too:
- **Table editor:** set `status` to `DELETED` → same rules.
- **Authentication → delete user:** the profile is marked `DELETED` → same rules.

Users **cannot** set their own `status` to `DELETED` (or anything else) with a plain
update. See section 6.

---

## 3. What the User Is Told

Decided by who did the deletion (`auth.uid()` = the user → self-delete):

| Case | Email | Push | In-app notification |
|---|---|---|---|
| Admin deletes a `PENDING_APPROVAL` user | "Application update – not approved" | "Application not approved" | – (row removed) |
| Any other deletion of an `INCOMPLETE` / `PENDING_APPROVAL` / `REJECTED` user | "Account deleted" | "Account deleted" (none for a self-delete) | – (row removed) |
| `ACTIVE` / `BLOCKED` user deleted | "Account deleted" | "Account deleted" | ✅ |

Because the devices are removed with the row, the trigger reads the device tokens
**first** and pushes to them directly (`send-notification`, action `send_to_tokens`).

---

## 4. How It Works

```
App / admin panel                              Supabase dashboard
  rpc('delete_user')                             delete auth user
        │                                               │
        ▼                                               ▼
  checks caller, then                    on_auth_user_deleted (BEFORE DELETE)
  UPDATE users SET status = 'DELETED'    sets a flag, then UPDATE users SET status = 'DELETED'
        │                                               │
        └──────────────────┬────────────────────────────┘
                           ▼
        trg_users_lifecycle_events  →  handle_user_lifecycle_events()
                           │
            A. notifications / email (failures only logged)
                           │
            B. deletion (failures roll back the whole change)
               ├─ DELETE auth.users          (skipped if the flag says it's already being deleted)
               └─ if it was INCOMPLETE / PENDING_APPROVAL / REJECTED:
                    ├─ purge_user_storage()  →  Edge Function purge-user-storage (async)
                    └─ DELETE public.users   (cascades to documents, services, devices, notifications)
```

Notifications and deletion live in **one** trigger so they always run in the right order:
the message is prepared while the row and device tokens still exist, then the row is removed.

The flag (`guardup.auth_deleting_user_id`) prevents deleting the same auth row twice
when the deletion starts from the auth side.

---

## 5. Uploaded Files

Files live in the `documents` and `avatars` buckets under a folder named after the user id
(`<user_id>/...`). Storage can't be cleaned with SQL, so the database calls the
**`purge-user-storage`** Edge Function, which deletes everything in `<user_id>/` in both buckets.

- Runs in the background (`pg_net`). A failure never blocks the deletion; check the
  function logs (`[PURGE] user=... removed=... errors=...`).
- Only runs when the row is removed. Kept (`ACTIVE` / `BLOCKED`) users keep their files.
- Rejects anything that isn't a valid UUID, so it can never empty a whole bucket.
- New bucket with per-user folders? Add it to `USER_BUCKETS` in
  `supabase/functions/purge-user-storage/index.ts`.

---

## 6. Security Guards

| Guard | What it stops |
|---|---|
| `trg_users_guard_status_and_role` (BEFORE UPDATE on `users`) | A user changing their own `role` or `rejection_reason`, or their own `status` except `INCOMPLETE` → `PENDING_APPROVAL` (submitting the application). Without it, the "update own profile" RLS policy would let a user approve themselves or make themselves admin. Admins, the dashboard, the service role and `SECURITY DEFINER` functions are not affected. |
| `delete_user` checks | Users can only delete themselves; admins can't be deleted. |
| `check_registration_conflict` | During signup, an existing account with the same email / phone is only cleaned up if it is an **abandoned signup** (email never confirmed **and** `INCOMPLETE`). Anything else is reported as a conflict, so a stranger can't wipe a pending applicant by signing up with their email. |

---

## 7. App Code

**Mobile app (`guardup/`)**
- `SupabaseAuthRepository.deleteAccount()` calls `delete_user`, then clears the local session.
- Profile → Delete Account confirms, calls `deleteAccount()`, then signs out.
  On failure it shows `deleteAccountFailed`.
- Approval screen: if the profile no longer exists, the application was rejected →
  shows `applicationNotApproved` and signs out.

**Admin panel (`guardup_admin/`)**
- `UsersRepository.delete(id)` → `delete_user` with `p_user_id`.
  The controller removes the user from the list; the details screen closes.
- Rejecting no longer deletes: see `UserReviewRepository`
  ([user_review_and_rejection.md](user_review_and_rejection.md)).

---

## 8. Files

| File | What |
|---|---|
| `supabase/migrations/20261117000015_remove_rejected_user_status.sql` | Removed `REJECTED` from `user_status` (added back by `20261118000000`). |
| `supabase/migrations/20261117000016_user_deletion_rules.sql` | Lifecycle + deletion trigger, auth-delete trigger, `purge_user_storage`, `delete_user`. |
| `supabase/migrations/20261117000017_protect_user_status_and_role.sql` | Status / role guard. |
| `supabase/migrations/20261117000018_restrict_registration_conflict_cleanup.sql` | Safer signup cleanup. |
| `supabase/migrations/20261118000001_user_rejection_flow.sql` | `REJECTED` users are hard deleted; `rejection_reason` guard. |
| `supabase/functions/purge-user-storage/` | File cleanup Edge Function. |

Deploy: `supabase db push`, then `supabase functions deploy purge-user-storage`
(and `user-lifecycle-events`, whose rejected email text changed).

---

## 9. Testing Checklist

Run as the right user (app / admin panel), then check with SQL:

```sql
-- Profile row (gone for a hard delete)
select id, status from public.users where id = '<user-id>';
-- Login (always gone)
select id from auth.users where id = '<user-id>';
-- Files (gone for a hard delete, after a few seconds)
select bucket_id, name from storage.objects where name like '<user-id>/%';
-- Calls to Edge Functions
select status_code, content, created from net._http_response order by created desc limit 5;
```

| Scenario | Expected |
|---|---|
| Admin deletes a `PENDING_APPROVAL` user | Row, login and files gone. "Not approved" email + push. Same email can register again. |
| Admin deletes a `REJECTED` user | Row, login and files gone. "Account deleted" email + push. |
| Pending user deletes their own account | Row, login and files gone. "Account deleted" email, no push. |
| `ACTIVE` user deletes their own account | Row kept as `DELETED`, login gone, files kept. "Account deleted" email + notification. |
| Admin deletes a `BLOCKED` user | Same as above. |
| Delete an auth user from the dashboard | Same rules as the row's status before. |
| User runs `update users set status = 'ACTIVE'` on themselves | Fails: `You cannot change your status`. |
| User runs `update users set role = 'ADMIN'` on themselves | Fails: `You cannot change your role`. |
| Sign up with the email of a pending applicant | Conflict returned, applicant untouched. |
