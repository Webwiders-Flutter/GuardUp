# ✅ GuardUp – Reviewing Applications (Approve / Reject)

How an admin reviews a bodyguard or company application: approving and rejecting
documents, approving and rejecting the profile, where the rejection reason is stored,
and what the user is told.

Deleting users is a separate action, covered in [user_deletion.md](user_deletion.md).
Bodyguards added by a company have no account to approve; an admin can review their
documents at any time ([user_profiles.md](user_profiles.md#documents-of-a-company-managed-bodyguard)).
Notifications in general are covered in
[notifications_and_user_lifecycle.md](notifications_and_user_lifecycle.md).

---

## 1. The Rules

An application can be reviewed while the user is **`PENDING_APPROVAL`** or **`REJECTED`**.

| Action | What changes | User status |
|---|---|---|
| Approve a document | `user_documents.status = APPROVED`, `rejection_reason` cleared | Unchanged |
| Reject a document (reason required) | `user_documents.status = REJECTED`, `user_documents.rejection_reason = <reason>` | → `REJECTED` |
| Reject the profile (reason required) | `users.rejection_reason = <reason>` | → `REJECTED` |
| Approve the profile | `users.rejection_reason` cleared | → `ACTIVE` |
| Rejected document back to `PENDING` (re-submitted) | `user_documents.status = PENDING`, `rejection_reason` **kept** | `REJECTED` → `PENDING_APPROVAL` once no document is still `REJECTED` |
| Approve a rejected document | `user_documents.status = APPROVED`, `rejection_reason` cleared | `REJECTED` → `PENDING_APPROVAL` once no document is still `REJECTED` |

- **The owner can re-upload a rejected document.** The app updates the row (new file,
  `status = PENDING`); the RLS policy allows the owner to update a `PENDING` or
  `REJECTED` document as long as it ends `PENDING`. Any client write is forced to
  `PENDING` and keeps the admin's last reason (`guard_user_document_review`), so a user
  can never approve a document or edit its reason. (Before migration
  `20261124000019` only `PENDING` rows matched, so re-uploads silently changed nothing.)
- **One rejected document is enough** to move the user to `REJECTED`.
- **The profile can only be approved once every document is `APPROVED`.** The database
  refuses otherwise (`All documents must be approved before the profile can be approved`).
- A document going `REJECTED → PENDING` or `REJECTED → APPROVED` moves a `REJECTED`
  user back to `PENDING_APPROVAL`, but only when **no other document is still
  `REJECTED`**. No notification is sent for this move. The admin then approves (or
  rejects) the profile again.
- **Rejection reasons are cleared only on approval:** a document's reason when it is
  `APPROVED`, the profile's reason when the user becomes `ACTIVE`. Every other change
  (e.g. `REJECTED → PENDING`) keeps the last reason.
- Rejecting the profile of an already `REJECTED` user only updates the reason (no second
  notification).
- Rejection **does not delete anything**. The user keeps their login, profile and files.
  (Deleting is still possible through `delete_user`; see section 5.)

Where the reason goes:

| Rejected | Reason stored in |
|---|---|
| A document | `public.user_documents.rejection_reason` (that document only) |
| The profile | `public.users.rejection_reason` |

---

## 2. What the User Is Told

Moving to `REJECTED` sends an **in-app notification** (type `ACCOUNT_REJECTED`,
title "Application not approved"), a **push notification** via FCM, and an **email**
explaining the rejection reason (with guidance to update and resubmit their profile).
Nothing is deleted.

The message and email content depend on why the user was rejected:

| Case | Body | Email Details |
|---|---|---|
| Profile rejected | "Your application was not approved. Reason: {reason}" | Highlights the profile rejection reason and provides a link to open the app and resubmit. |
| Document(s) rejected | "Some of your documents were rejected: {document names}. Please check them in the app for details." | Lists the rejected document names and prompts the user to re-upload them. |

`data` carries `event = PROFILE_REJECTED`, `user_id`, `role` and `rejection_reason`
(the profile reason, or `null` for a document rejection).

Approving the profile sends the usual "Account approved" notification + approved email,
for both `PENDING_APPROVAL → ACTIVE` and `REJECTED → ACTIVE`.

---

## 3. How It Works (direct updates + triggers)

Same pattern as block / unblock: the admin panel **updates the rows directly** (RLS lets
admins update `users` and `user_documents`), and triggers enforce the rules and cascade
the effects. The rules therefore hold for every writer: admin panel, dashboard, service role.
RPCs are kept for operations that are not a plain row write (`delete_user`).

| Admin action | Update |
|---|---|
| Approve a document | `user_documents` → `status = 'APPROVED'` |
| Reject a document | `user_documents` → `status = 'REJECTED', rejection_reason = <reason>` |
| Approve the profile | `users` → `status = 'ACTIVE'` |
| Reject the profile | `users` → `status = 'REJECTED', rejection_reason = <reason>` |

```
UPDATE user_documents SET status = 'REJECTED', rejection_reason = ...
   │
   ├─ trg_user_documents_review_rules   (BEFORE)  reason required, user must be under review
   ├─ trg_user_documents_reject_user    (AFTER)   UPDATE users SET status = 'REJECTED'
   │                                                (only if PENDING_APPROVAL)
   └─ trg_user_documents_pending_user   (AFTER)   REJECTED -> PENDING / APPROVED document:
                                                    UPDATE users SET status = 'PENDING_APPROVAL'
                                                    (only if REJECTED and no document still REJECTED)
                                                         │
UPDATE users SET status = ...                            │
   │◄────────────────────────────────────────────────────┘
   ├─ trg_users_guard_status_and_role   (BEFORE)  users can't change their own status / reason
   ├─ trg_users_review_rules            (BEFORE)  approve: all documents approved, reason cleared
   │                                              reject:  under review, reason (or a rejected document)
   └─ trg_users_lifecycle_events        (AFTER)   notification
```

The document update and the user's move to `REJECTED` happen in the **same transaction**
(the AFTER trigger runs inside the document update), so they always succeed or fail together.
Because the document row is already written when the user's status changes, the
notification can name the rejected document.

Reasons are trimmed. A reason is cleared **only on approval** (document → `APPROVED`,
user → `ACTIVE`); any other status change keeps it.

Errors (SQLSTATE `22023`, shown as is in the admin panel):

| Message | When |
|---|---|
| `Documents can only be reviewed while the application is pending or rejected (current status: …)` | Approving / rejecting a document of a user who is not `PENDING_APPROVAL` / `REJECTED` |
| `Only applications awaiting review can be rejected (current status: …)` | Rejecting an `ACTIVE` / `BLOCKED` / … user |
| `A rejection reason is required` | Empty / blank reason (a document-driven user rejection needs none) |
| `All documents must be approved before the profile can be approved (n not approved)` | Approving a pending / rejected profile with open documents |

Not covered: two admins acting on the same user at the same instant are not serialized.
Each write is still checked against the rules, so the worst case is an error for one of them.

---

## 4. Security Guards

| Guard | What it stops |
|---|---|
| `trg_users_guard_status_and_role` | A user changing their own `status`, `role` **or `rejection_reason`**. |
| `trg_user_documents_guard_review` (BEFORE INSERT on `user_documents`) | A user inserting a document that is already `APPROVED` / `REJECTED`: client inserts are always forced to `PENDING` with no reason. (Updates were already limited to `PENDING` by RLS.) |

---

## 5. Interaction With Deletion

Unchanged from [user_deletion.md](user_deletion.md), plus:

- A `REJECTED` user has never been approved, so deleting them is a **hard delete**
  (row, login and files removed), like `INCOMPLETE` / `PENDING_APPROVAL`.
- Deleting a `REJECTED` user sends the "Account deleted" email and push (not the
  "not approved" one; they were already told).
- An admin deleting a `PENDING_APPROVAL` user still sends the "not approved" email and push,
  as before.

---

## 6. Admin Panel

**User details screen** (`user_details.screen.dart`), while the user is pending or rejected:
- **Top bar** (pending users only): "Reject Profile".
  "Approve Profile" appears beside it **only when every document is approved**.
- **Documents section:** each document has its own approve ✓ / reject ✕ button
  (approve is hidden once approved; reject is hidden once rejected **or approved**). A document shows its
  reason underneath.
- The profile and each document show their rejection reason whenever one is stored, whatever the status (a reason is kept until approval).
- Every reject button opens `AppPopup.showRejectWithReason`, which requires a reason.
- Review buttons are disabled while a review request is running.

**Users list** (`users_management.screen.dart`): the approve / reject buttons are commented
out; reviewing happens on the details screen only.

**Sidebar:** Bodyguards and Companies have a **Rejected** tab
(`/users/bodyguard/rejected`, `/users/company/rejected`). Customers are never reviewed.

Code:

| File | What |
|---|---|
| `features/users/data/repositories/user_review.repository.dart` | Updates `user_documents` / `users` directly (like block / unblock) |
| `features/users/presentation/controllers/user_review.controller.dart` | `userReviewControllerProvider(userId)`; on success refreshes the user's details and every users list |
| `features/users/di/users.providers.dart` | `userReviewRepositoryProvider`, `userReviewControllerProvider` |
| `shared/widgets/feedbacks/widgets/app_popup.dart` | `showRejectWithReason` |

---

## 7. Mobile App (not changed yet)

The mobile app already parses `REJECTED` for users and documents. Still to do there:

- Show `users.rejection_reason` and each document's `rejection_reason` to the user.
- A way to fix a rejected application. Today a user cannot re-upload a `REJECTED`
  document (RLS only allows updating `PENDING` documents). Once a document can go
  `REJECTED → PENDING`, `trg_user_documents_pending_user` already moves the user back
  to `PENDING_APPROVAL` (it bypasses the status guard), so only the RLS policy needs opening.

---

## 8. Files

| File | What |
|---|---|
| `supabase/migrations/20261118000000_add_rejected_user_status.sql` | Adds `REJECTED` back to `user_status` |
| `supabase/migrations/20261118000001_user_rejection_flow.sql` | `users.rejection_reason`, guards, lifecycle trigger update, `delete_user` update, review triggers |
| `supabase/migrations/20261118000002_pending_user_on_document_resubmitted.sql` | Rejected document → `PENDING` moves the user back to `PENDING_APPROVAL` (`trg_user_documents_pending_user`) |
| `supabase/migrations/20261118000003_rejection_reason_cleared_on_approval.sql` | Same trigger also on `REJECTED → APPROVED`; rejection reasons cleared only on approval |
| `supabase/migrations/20261118000014_allow_rejected_user_to_resubmit_profile.sql` | Allows rejected users to update bio/services/documents to resubmit profile |
| `supabase/migrations/20261119000015_send_email_on_profile_rejection.sql` | Sends notification email on application rejection with reason/documents |

Deploy: `supabase db push`. Deploy Edge Function: `supabase functions deploy user-lifecycle-events`.

---

## 9. Testing Checklist

```sql
select id, status, rejection_reason from public.users where id = '<user-id>';
select id, status, rejection_reason from public.user_documents where user_id = '<user-id>';
select type, title, body, data from public.notifications where user_id = '<user-id>' order by created_at desc limit 3;
```

| Scenario | Expected |
|---|---|
| Reject one document of a pending user | Document `REJECTED` + reason; user `REJECTED`, `users.rejection_reason` empty; notification naming the document; rejected email listing document sent. |
| Reject a second document | Document `REJECTED` + reason; no new notification. |
| Set one of two `REJECTED` documents to `PENDING` | Document `PENDING`, reason kept; user stays `REJECTED`. |
| Set the last `REJECTED` document to `PENDING` | User `PENDING_APPROVAL`, both reasons kept; no notification. |
| Approve the last `REJECTED` document | Document `APPROVED`, its reason cleared; user `PENDING_APPROVAL`, profile reason kept. |
| Approve the profile | User `ACTIVE`, `users.rejection_reason` cleared. |
| Approved document | No reject button in the admin panel. |
| Reject the profile of a pending user | User `REJECTED` + reason; notification with the reason; rejected email with reason sent. |
| Approve profile with a pending / rejected document | Fails: `All documents must be approved…`. |
| Approve every document, then the profile | User `ACTIVE`, reason cleared; "Account approved" notification + email. |
| Reject an `ACTIVE` user, or review one of their documents | Fails: `Only applications awaiting review…` / `Documents can only be reviewed…`. |
| Block / unblock an `ACTIVE` user | Works as before. |
| Reject with a blank reason | Fails: `A rejection reason is required` (the popup also blocks it). |
| User updates their own `rejection_reason` | Fails: `You cannot change the rejection reason`. |
| User inserts a document with `status = 'APPROVED'` | Stored as `PENDING`. |
| User updates their own document to `APPROVED` | Fails (RLS). |
| Admin deletes a `REJECTED` user | Row, login and files removed; "Account deleted" email + push. |
