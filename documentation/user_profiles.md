# 🧩 GuardUp – Accounts and Role Profiles (users / companies / bodyguards)

How an account is split into its login data and its role profile, how a company
manages its own bodyguards, and how the apps read and write profiles.

Introduced by migrations `20261124000019_split_user_profiles.sql`,
`20261124000020_drop_legacy_user_profile_columns.sql` and
`20261124000021_bodyguard_verification_status.sql` (bodyguard verification). The per-column reference of
each table is in [user_profile_data.md](user_profile_data.md).

---

## 1. Why

Before, one `public.users` row held the account **and** every role's profile columns
(bodyguard rate / bio, company name / type …). A bodyguard therefore had to be a login
account, so a company could not add bodyguards of its own.

Now:

| Table | One row per | Holds |
|---|---|---|
| `users` | login account (customer, guard, company, admin) | identity, contact, role, status, review (`rejection_reason`), address, settings |
| `companies` | COMPANY account | company name, business email, type, company phone, years in operation |
| `bodyguards` | bodyguard | rate, rating, experience, bio, languages, certifications, `is_active`, verification `status` / `rejection_reason` |

`users.role` still says which profile an account has. The link lives on the profile
table (a real foreign key), so Postgres enforces it and PostgREST can join it.

```
users (role = COMPANY) 1 ──── 1 companies 1 ──── * bodyguards (user_id NULL)   company-managed
users (role = GUARD)   1 ──── 1 bodyguards (user_id set, company_id NULL)     self-registered
users (role = CUSTOMER / ADMIN)   no profile row
```

---

## 2. The Two Kinds of Bodyguard

| | Self-registered | Company-managed |
|---|---|---|
| `bodyguards.user_id` | the GUARD account | `NULL` (no login) |
| `bodyguards.company_id` | `NULL` | the company |
| Created by | `handle_new_user()` on signup | the company (Add Bodyguard) |
| Name, photo | copied from `users` (source of truth) | stored on `bodyguards` |
| Verification (`bodyguards.status`) | copied from `users.status`: approved together with the account | reviewed by an admin on its own (section 2a); `is_active` lets the company switch it off |
| Services / documents / availability rows | keyed by `user_id` | keyed by `bodyguard_id` |
| Deleted with | the account (`delete_user`) | the company deleting it, or the company account |

A company can only manage **its own company-managed** bodyguards. It cannot edit a
self-registered guard, even one that is visible to it.

### 2a. Verification of a company-managed bodyguard

`bodyguards.status` uses the same `user_status` values as accounts.

```
company adds it ──► INCOMPLETE ──(company submits on the Documents step)──► PENDING_APPROVAL
                                                                               │
                         admin approves (all documents APPROVED) ◄─────────────┤
                                     │                                         │
                                  ACTIVE   (never blocked)           admin rejects (reason)
                                                                       or a document is rejected
                                                                               │
                         company edits / re-uploads and resubmits ◄──── REJECTED
```

- The company can only move `INCOMPLETE` / `REJECTED` → `PENDING_APPROVAL`; approving
  and rejecting are admin-only (`guard_profile_ownership()`), and it can never set the
  rejection reason.
- A company-managed bodyguard is **never blocked** (migration `20261124000023`,
  `prevent_company_bodyguard_block()`): an admin approves, rejects or deletes it, and the
  company can switch it off (`is_active`). Blocking stays for login accounts, including
  self-registered guards. A row blocked before that migration keeps `BLOCKED` until it is
  unblocked or deleted; it cannot be blocked again.
- `enforce_bodyguard_review_rules()` applies the account rules: approve only from
  `PENDING_APPROVAL` / `REJECTED` with every document `APPROVED` (clears the reason);
  reject only while under review, with a reason unless a document is rejected.
- Documents follow the account flow: reviewable only while the bodyguard is
  `PENDING_APPROVAL` / `REJECTED`; a rejected document rejects the bodyguard; a
  re-uploaded (or approved) rejected document sends it back to `PENDING_APPROVAL` once
  no document is still rejected.
- Only `ACTIVE` bodyguards are listed to customers (`is_bodyguard_listed`).
- Notifications (in-app + push, no email; existing types, `data.event` and
  `data.bodyguard_id` identify the bodyguard):

  | Change | To | Type | Title |
  |---|---|---|---|
  | → `PENDING_APPROVAL` | all admins | `NEW_USER_REGISTRATION` | New bodyguard to review: {name} |
  | → `ACTIVE` (approved) | the company | `ACCOUNT_APPROVED` | Bodyguard approved |
  | → `REJECTED` | the company | `ACCOUNT_REJECTED` | Bodyguard not approved (reason or rejected documents) |
  | deleted by an admin | the company | `ACCOUNT_DELETED` | Bodyguard removed |

  `data.user_id` is the company account and `data.bodyguard_id` the bodyguard. Opening
  the notification opens the bodyguard (admin: its review panel; company app: its details,
  or the bodyguards list once deleted). See "Opening a notification" in
  [notifications_and_user_lifecycle.md](notifications_and_user_lifecycle.md).

Bodyguards a company added before migration `20261124000021` were set to
`PENDING_APPROVAL`, so an admin reviews them once.

**Deleting** (migration `20261124000022`): an admin can delete a company-managed
bodyguard; its services, documents and availability go with it (ON DELETE CASCADE).
`notify_company_on_bodyguard_deleted()` (AFTER DELETE on `bodyguards`) notifies the
company (`ACCOUNT_DELETED`, title "Bodyguard removed", `data.event = BODYGUARD_DELETED`).
It does not notify when the company deletes its own bodyguard, or when the company
account itself is removed.

#### Admin panel

Company-managed bodyguards have their own listing, separate from the Bodyguards
(GUARD accounts) listing: sidebar **Users → Company Bodyguards**, routes
`/users/company-bodyguards/<pending|verified|rejected>`
(`features/company_bodyguards` in `guardup_admin`). Each row shows the bodyguard, its
company (opens the company's details), phone, rate and status. Opening a row shows the
review panel; it is also opened from the company's details (Company Bodyguards
section).

The review flow matches an account's review on the user details screen, without
block / unblock (only approve, reject and delete):

| Status | Profile actions | Documents |
|---|---|---|
| `PENDING_APPROVAL` | Approve (enabled once every document is approved), Reject (reason) | approve / reject each |
| `REJECTED` | none; the company fixes and resubmits (the listing row can Delete) | approve / reject each |
| `ACTIVE` | Delete | read-only |
| `INCOMPLETE` | none (not submitted yet) | read-only |

The database enforces these rules (above), so the panel only mirrors them.

### Identity sync (self-registered)

`users` stays the source of truth for a self-registered bodyguard's `name`,
`profile_image_url`, and verification (`status`, `rejection_reason`):

- `trg_bodyguards_sync_identity` (BEFORE INSERT / UPDATE on `bodyguards`) copies them
  from `users` on every write, so they can never drift.
- `trg_users_push_identity_to_bodyguard` (AFTER UPDATE on `users`) touches the bodyguard
  row when they change, which runs the copy.

Contact and demographic details (`phone_number`, `gender`) stay private on `users` and are not stored on `bodyguards`.

---

## 3. Child Tables: Exactly One Owner

`user_services`, `user_availabilities` and `user_documents` have a `user_id` **and** a
`bodyguard_id` column. A CHECK constraint requires exactly one of them:

| Row belongs to | Column set |
|---|---|
| A login account (customer, guard, company) | `user_id` (unchanged from before) |
| A company-managed bodyguard | `bodyguard_id` |

So everything that already worked for login accounts (the review flow, the RPCs,
both apps) still uses `user_id` unchanged. Unique constraints exist for both owners,
e.g. `UNIQUE (bodyguard_id, day_of_week)`, so upserts work with
`on_conflict=bodyguard_id,day_of_week`.

`user_bank_accounts`, `user_devices`, `notifications` and `contact_us` only ever
belong to a login account (`user_id`).

---

## 4. Who Can Read and Write (RLS)

Helpers (SECURITY DEFINER, so policies never recurse into `users` RLS):

| Function | Returns |
|---|---|
| `my_company_id()` | `companies.id` of the signed-in COMPANY account |
| `is_account_active(user_id)` | the account exists and is `ACTIVE` |
| `can_manage_bodyguard(bodyguard_id)` | the caller is the company of this company-managed bodyguard |
| `is_bodyguard_listed(bodyguard_id)` | `is_active`, `status = ACTIVE`, and its account (own or company's) is `ACTIVE` |

| Table | Read | Write |
|---|---|---|
| `companies` | owner, admins, everyone when the company account is `ACTIVE` | owner updates; insert only by the owner (repairs a missing row) or admins |
| `bodyguards` | owner, its company, admins, everyone when listed | owner (self-registered), its company (company-managed), admins. Only an **`ACTIVE`** company can add bodyguards. Delete: its company or admins |
| `user_services` / `user_availabilities` | public (unchanged) | + the company for its bodyguards' rows |
| `user_documents` | + the company for its bodyguards' rows | + the company for its bodyguards' rows; every company write leaves the document `PENDING` |

Protected columns (`guard_profile_ownership()`, client writes only; admins, triggers
and SECURITY DEFINER functions are not affected):

- `user_id` (both tables) and `company_id` (bodyguards) cannot be changed.
- `bodyguards.rating` comes from reviews: forced to `0` on insert, cannot be changed.

### Documents of a company-managed bodyguard

Reviewed like an account's documents, against `bodyguards.status` instead of
`users.status` (section 2a). The cascade triggers update the bodyguard row.

---

## 5. Reading a Profile: `public.user_profiles`

A read-only view with one row per account, flattening the account and its profile
with the **same column names the apps used before the split** (`company_name`,
`hourly_rate`, …), plus `company_id` and `bodyguard_id`.

- `security_invoker = true`: the caller's RLS applies (own row; everything for admins).
- `hourly_rate`, `rating` and `experience_years` fall back to `0` like the old `users`
  defaults. `experience_years` is the bodyguard's or, for a company, the company's.
- Realtime cannot watch a view. The mobile app listens to `users` plus the role's
  profile table and re-reads the view on every change (`SupabaseUserRepository.watchUserData`).
- `company` / `bodyguard` columns hold the whole profile row as JSON (or `NULL`), for
  typed models (admin panel).
- Write to the base tables, never the view.

---

## 6. Apps

### Mobile app (`guardup`)

| Piece | Role |
|---|---|
| `UserRepository.getUserData` | reads `user_profiles`: same map as before, so `AuthState` getters are unchanged |
| `UserRepository.updateProfileFields` | takes the same flat map as before; `ProfileFields.split` sends each column to `users`, `bodyguards` (GUARD) or `companies` (COMPANY). Role columns that do not belong to the account's role are ignored (logged) |
| `BodyguardRepository` | company-managed bodyguards: list (paginated, search), get, create / update, delete, services (`set_bodyguard_services`) |
| `CompanyBodyguardsCubit` | the company's bodyguard list (All Bodyguards screen, home roster; shimmer skeleton while loading) |
| `BodyguardRepository.submitForReview` | `INCOMPLETE` / `REJECTED` → `PENDING_APPROVAL`, called when the company finishes the Documents step |
| `DocumentSubmissionService` | `getBodyguardDocuments` / `uploadDocuments(bodyguardId:)` for company-managed bodyguards |

Company flow: **All Bodyguards → Add / Edit** (`BodyGuardCompleteProfileScreen` with
the bodyguard as `extra`) **→ Documents** (`BodyGuardUploadDocumentsScreen`) **→ back
to the list**. Files go to `<company user id>/bodyguards/<bodyguard id>/…` in the
`documents` bucket (avatars: `<company user id>/bodyguards/…` in `avatars`), because
the storage policies require the signed-in user as the first folder. The company's own
account, status and logo are never touched by this flow.

The company sees each bodyguard's verification on its card (pending / rejected with
the reason / blocked), and the rejection reason on the edit screen.

Customers still see the sample roster on the All Bodyguards screen until the public
bodyguard listing is built (`is_bodyguard_listed` already defines who is visible).

### Admin panel (`guardup_admin`)

- The users list and search read `user_profiles`, so searching by company name /
  business email keeps working.
- Separate models: `UserModel` (account, every role) with `CompanyModel? company` and
  `BodyguardModel? bodyguard`. A customer has no profile table, so the account is the
  customer. Display helpers (`fullName`, `services` …) are in
  `core/extensions/user.extension.dart`.
- User details read `users` with `company:companies!companies_user_id_fkey(*)` and
  `bodyguard:bodyguards!bodyguards_user_id_fkey(*)`; the list reads the view's JSON
  columns. The FK hints are required: the child tables also link `users` to
  `bodyguards`, so PostgREST would otherwise report several relationships.
- A company's details show **Company Bodyguards** (`BodyguardsRepository`,
  `companyBodyguardsProvider`), awaiting review first. **Review** opens a side panel:
  profile, availability, documents (approve / reject each), then approve / reject the
  bodyguard, or block / unblock an approved one (`BodyguardReviewController`).
- Status changes on accounts (block / unblock / review) write `users` and re-read the view.

---

## 7. RPCs

| RPC | Who | Does |
|---|---|---|
| `set_user_services(p_user_id, p_service_ids)` | the account itself | unchanged |
| `set_bodyguard_services(p_bodyguard_id, p_service_ids)` | the managing company, admins | replaces a company-managed bodyguard's services in one transaction (duplicates ignored) |

---

## 8. Deploying

1. Apply `20261124000019` (creates and backfills the new tables, switches triggers).
   Old app builds still run (the legacy `users` columns still exist), but their profile
   edits land in those legacy columns, which nothing reads any more. Keep this window short.
2. Release the app and admin panel updates.
3. Apply `20261124000020` (drops the legacy `users` columns). From here on an old app
   build that writes e.g. `users.hourly_rate` gets an error.

If no old builds are in use, both migrations can be applied together before the release.

`20261124000021` (bodyguard verification) does not depend on `20261124000020` and can be
applied before or after it, but before releasing apps that read `bodyguards.status`.
