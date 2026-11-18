# 👤 GuardUp – User Profile Data

The tables that hold a user's profile, who writes them, and what the admin panel
shows on the **User Details** screen.

Reviewing applications is covered in
[user_review_and_rejection.md](user_review_and_rejection.md); deleting users is in
[user_deletion.md](user_deletion.md).

---

## 1. Tables

| Table | One row per | Written by | Admin access |
|---|---|---|---|
| `users` | user | user (mobile app), status / rejection by admin | read + review |
| `user_services` | user × service | user | read |
| `user_documents` | user × document type | user (upload), admin (review) | read + review |
| `user_availabilities` | user × day of week | bodyguard | read (public read policy) |
| `user_bank_accounts` | payout account | bodyguard / company | **read only** (`Admins can read all bank accounts`) |

All child tables use `ON DELETE CASCADE` on `user_id`, so deleting a user's row removes
them too.

### `users` columns by role

| Group | Columns | Shown for |
|---|---|---|
| Account | `name`, `email`, `phone_code` + `phone_number`, `role`, `status`, `rejection_reason`, `profile_image_url` | everyone |
| Personal | `gender` (`MALE` / `FEMALE` / `OTHER`), `address`, `latitude`, `longitude`, `is_push_notification_enabled` | everyone |
| Bodyguard | `hourly_rate`, `rating`, `experience_years`, `bio`, `languages`, `certifications` | `GUARD` |
| Company | `company_name`, `business_email`, `company_type`, `company_phone_code` + `company_phone_number` | `COMPANY` |

- `languages` and `certifications` are free text. The admin panel splits them on
  commas / new lines and shows each item as a chip.
- `phone_code` and `company_phone_code` default to `+91`.
- For a company, `phone_number` is the **contact person's** phone and
  `company_phone_number` is the company's own line.

### `user_availabilities`

One row per day (`UNIQUE (user_id, day_of_week)`), upserted by the mobile app.

- `day_of_week` is stored in **lowercase** (`monday` … `sunday`), matching the
  admin `WeekDay` enum values. Any other value is ignored.
- `from_time` / `to_time` are display strings such as `09:00 AM`.
- A day with no row is shown as **Not set**; `is_available = false` is shown as **Off**.

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
(`user_services`, `documents:user_documents`, `bank_accounts:user_bank_accounts`,
`availabilities:user_availabilities`). A user with none of these gets empty lists.

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
