# 📨 GuardUp – Contact Us / Help & Support

Support requests sent from the app (`public.contact_us`) and how admins handle them in
the **Help & Support** screen of the admin panel.

---

## 1. Table

| Column | Notes |
|---|---|
| `user_id` | Sender's account; `NULL` for guests. Set to `NULL` if the user is deleted (`ON DELETE SET NULL`). |
| `role` | Sender's role at the time (`user_role`), `NULL` for guests |
| `full_name`, `email`, `message` | Required |
| `status` | `contact_us_status`: `PENDING` (default) → `IN_PROGRESS` → `RESOLVED` / `CLOSED` |
| `created_at`, `updated_at` | `updated_at` is set by the `set_contact_us_updated_at` trigger on every update |

Migrations: `20261118000010_create_contact_us_table.sql`,
`20261118000013_admin_manage_contact_us.sql`.

## 2. Who can do what (RLS)

| Who | Insert | Read | Update | Delete |
|---|---|---|---|---|
| Anyone (anon or signed in) | ✅ | – | – | – |
| Signed-in user | ✅ | own rows only | – | – |
| Admin (`public.is_admin()`) | ✅ | all | all | all |

## 3. Admin panel

- List with search (name, email, message) and filters by status and sender role.
- Change one request's status from its status chip, or several at once with the
  "Mark …" buttons.
- "View User" opens the sender's profile when `user_id` is set.
- Delete one or many requests.

Status changes do not notify the user.
