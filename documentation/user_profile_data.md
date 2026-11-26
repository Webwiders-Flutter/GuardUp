# 👤 GuardUp – User Profile Data

The tables that hold a user's profile, who writes them, and what the admin panel
shows on the **User Details** screen.

Reviewing applications is covered in
[user_review_and_rejection.md](user_review_and_rejection.md); deleting users is in
[user_deletion.md](user_deletion.md).

---

## 1. Tables

Account data lives in `users`; role profiles live in `companies` and `bodyguards`.
How the split works (company-managed bodyguards, RLS, the `user_profiles` view) is in
[user_profiles.md](user_profiles.md).

| Table | One row per | Written by | Admin access |
|---|---|---|---|
| `users` | login account | user (mobile app), status / rejection by admin | read + review |
| `companies` | COMPANY account | company | read |
| `bodyguards` | bodyguard (self-registered or company-managed) | guard / their company | read |
| `user_services` | owner × service | guard / company | read |
| `user_documents` | owner × document type | owner (upload), admin (review) | read + review |
| `user_availabilities` | owner × day of week | bodyguard / their company | read (public read policy) |
| `user_bank_accounts` | payout account | bodyguard / company | **read only** (`Admins can read all bank accounts`) |

"Owner" is `user_id` for a login account or `bodyguard_id` for a company-managed
bodyguard (exactly one is set). All child tables cascade on delete from their owner.

### Columns by table

| Table | Columns | Shown for |
|---|---|---|
| `users` (account) | `name`, `email`, `phone_code` + `phone_number`, `role`, `status`, `rejection_reason`, `profile_image_url` | everyone |
| `users` (personal) | `gender` (`MALE` / `FEMALE` / `OTHER`), `address`, `latitude`, `longitude`, `is_push_notification_enabled` | everyone |
| `bodyguards` | `hourly_rate`, `rating`, `experience_years`, `bio`, `languages`, `certifications`, `is_active` | `GUARD` |
| `companies` | `company_name`, `business_email`, `company_type`, `company_phone_code` + `company_phone_number`, `experience_years` | `COMPANY` |

The `user_profiles` view returns all of these flattened per account under the same
names, which is what both apps read.

- `companies.company_type` always stores the `BusinessType` API value (`PVT_LTD`, …);
  screens show its label (`businessTypeLabel` extension in the app). Rows the old edit
  screen saved as labels are converted by migration `20261124000019`.
- `languages` and `certifications` are free text. The admin panel splits them on
  commas / new lines and shows each item as a chip.
- `phone_code` and `company_phone_code` default to `+91`.
- For a company, `phone_number` is the **contact person's** phone and
  `company_phone_number` is the company's own line.

### `user_availabilities`

One row per day (`UNIQUE (user_id, day_of_week)` for accounts, `UNIQUE (bodyguard_id, day_of_week)` for company-managed bodyguards), upserted by the mobile app.

- `day_of_week` is stored in **lowercase** (`monday` … `sunday`), matching the
  admin `WeekDay` enum values. Any other value is ignored.
- `from_time` / `to_time` are display strings such as `09:00 AM`.
- A day with no row is shown as **Not set**; `is_available = false` is shown as **Off**.
- Legacy accounts that originally stored schedules in `users.metadata['availability']`
  are backfilled into `public.user_availabilities` by migration
  `20261126000001_backfill_user_availabilities_from_metadata.sql` (inserting all
  7 lowercase weekday rows per qualifying user with `ON CONFLICT (user_id, day_of_week) DO NOTHING`).
  The legacy `metadata['availability']` key is left intact in place, and the mobile
  app no longer reads or double-writes it.

### `user_bank_accounts`

`account_holder`, `bank_name`, `branch`, `ifsc_code`, `account_number`,
`branch_address` (optional), `is_primary`.

Originally only the owner could read their rows. Migration
`20261118000012_admin_read_user_bank_accounts.sql` adds a `SELECT` policy for
`public.is_admin()`. Admins cannot insert, update or delete bank accounts.

### `user_documents`

Besides status and rejection reason, each document has `uploaded_at` and an optional
`valid_till`. The admin panel shows both and flags a document as **Expired** when
`valid_till` is before today. Expiry is informational only; it does not change the
document's status.

---

## 2. Admin panel: User Details screen

`UsersRepository.getDetails` loads the user with every relation in one query
(`company:companies`, `bodyguard:bodyguards`, `user_services`, `documents:user_documents`,
`bank_accounts:user_bank_accounts`, `availabilities:user_availabilities`) and copies the
company / bodyguard columns onto the user. The users list reads the `user_profiles` view. A user with none of these gets empty lists.

Sections, in order:

1. Profile header (name, role, status, contact, review / block / delete actions)
2. Quick stats
3. Personal Information (gender, address with a Google Maps link, push notifications)
4. Bodyguard details (rate, rating, experience, bio, services, languages,
   certifications) **or** Company details (name, type, contact person, company phone,
   business email, services)
5. Weekly Availability, Monday → Sunday (bodyguards, or anyone with rows)
6. Bank Accounts (bodyguards & companies): primary first, account number masked with a
   show / copy action, IFSC copyable
7. Verification Documents with review actions, upload date and expiry
