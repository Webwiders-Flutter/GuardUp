# 🛡️ GuardUp – Protection Services

The master catalogue of protection services (e.g. *VIP Close Protection*,
*Event Security*). Admins manage it from the admin panel's **Services** screen.
Guards pick the services they offer from this list.

---

## 1. The Table: `public.services`

Migrations:
- `supabase/migrations/20261116000000_auth_users_documents_services.sql` (create)
- `supabase/migrations/20261117000002_alter_services_remove_code_and_use_1000s_order.sql` (drop `code`, 1000-step ordering)
- `supabase/migrations/20261123000017_add_icon_url_to_services_and_admin_bucket.sql` (add `icon_url`)

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key. |
| `name` | `text` | Required. |
| `description` | `text` | Optional. |
| `icon_name` | `text` | Legacy name of a built-in icon. Still read by the mobile app. The admin panel keeps it as is. |
| `icon_url` | `text` | Public URL of the uploaded icon image. `NULL` means no icon (services created before this column existed). |
| `is_active` | `boolean` | Whether the service shows up in the app. Default `true`. |
| `display_order` | `integer` | Order in the list (ascending). New services go first: first service's order − `AppConstants.sortOrderGap` (1000). Drag-to-reorder keeps the 1000 gaps. |
| `created_at`, `updated_at` | `timestamptz` | |

### Access (RLS)

Migration: `supabase/migrations/20261117000003_services_admin_rls_policies.sql`

| Who | Can do |
|---|---|
| Anyone (anon / signed in) | Read **active** services. |
| Admin (`public.is_admin()`) | Read, create, update and delete all services. |

---

## 2. Service Icons

Admins upload an image as the service's icon. The file goes to Supabase Storage
and its public URL is saved in `services.icon_url`.

### Storage

| | |
|---|---|
| Bucket | `admin` (public) |
| Folder | `services/` — files are named `<timestamp>_<original name>` |
| Max size | 5 MB |
| Allowed types | PNG, JPEG, SVG, GIF, WebP, AVIF (the admin form offers PNG, JPG, WebP, SVG) |

The `admin` bucket is for any admin-managed asset, one folder per feature.

| Who | Can do in the `admin` bucket |
|---|---|
| Anyone | Read / download files |
| Admin (`public.is_admin()`) | Upload, replace and delete files |

### What the admin panel does

| Action | Result |
|---|---|
| Create a service | An icon is **required**. It is uploaded first, then the row is saved with its URL. |
| Edit and pick a new icon | The new file is uploaded, the old file is deleted, and `icon_url` is updated. |
| Edit and remove the icon | `icon_url` is set to `NULL` and the old file is deleted. |
| Edit without touching the icon | `icon_url` stays the same. Services without an icon can still be edited. |
| Delete one or more services | The rows are deleted, then their icon files. A failure to delete a file is ignored, so the delete still succeeds. |

The services table in the admin panel shows the icon in an **Icon** column
(click to preview). Services without an icon show a placeholder shield.

### Mobile app

The mobile app does not read `icon_url` yet. It still uses `icon_name`.
