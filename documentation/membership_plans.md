# 🎖️ GuardUp – Membership Plans

Customer membership tiers (e.g. *Silver Shield*, *Gold Sentinel*, *Platinum Elite*).
A customer buys a plan monthly (or yearly, if the plan offers it) and gets a
discount on every booking while the plan is active.

This doc covers the plan catalogue that admins manage. Buying a plan, renewals
and applying the discount at checkout are not built yet.

---

## 1. The Table: `public.membership_plans`

Migration: `supabase/migrations/20261118000005_create_membership_plans_table.sql`

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | Primary key. |
| `name` | `text` | Required, not blank. **Unique, ignoring case and surrounding spaces.** |
| `description` | `text[]` | List of benefits, one per line, shown as bullets on the plan card. Defaults to `{}`. |
| `price_per_month` | `numeric(12,2)` | Required, `>= 0`. |
| `price_per_year` | `numeric(12,2)` | Optional. `NULL` means the plan is monthly only. `>= 0`. |
| `discount` | `numeric(12,2)` | Booking discount value. `>= 0`, default `0` (no discount). |
| `discount_type` | `membership_discount_type` | `PERCENTAGE` or `FLAT`. Default `PERCENTAGE`. |
| `discount_upto` | `numeric(12,2)` | Optional cap on the discount amount per booking. `> 0`. **Only allowed for `PERCENTAGE`.** |
| `is_popular` | `boolean` | Highlights the plan as "Most popular" in the app. Default `false`. |
| `is_active` | `boolean` | Whether customers can see / buy the plan. Default `true`. |
| `display_order` | `integer` | Tier order (ascending). Set by the admin panel, can be `0` or negative. New plans go first: first plan's order − `AppConstants.sortOrderGap` (1000). Drag-to-reorder keeps the 1000 gaps. |
| `created_at`, `updated_at` | `timestamptz` | `updated_at` is bumped by a trigger on every update. |

### Default plans (seed)

Migration: `supabase/migrations/20261118000009_seed_membership_plans.sql`

| Plan | Monthly | Yearly | Discount | Popular | Order |
|---|---|---|---|---|---|
| Silver Shield | ₹499 | ₹4,999 | 10%, up to ₹500 | | 1000 |
| Gold Sentinel | ₹999 | ₹9,999 | 20%, up to ₹1,500 | ⭐ | 2000 |
| Platinum Elite | ₹1,999 | ₹19,999 | 30%, no cap | | 3000 |

Safe to re-run: a plan whose name already exists (ignoring case and spaces) is skipped,
so edits made by an admin are never overwritten.

### Discount rules (enforced by check constraints)

| `discount_type` | `discount` means | `discount` range | `discount_upto` |
|---|---|---|---|
| `PERCENTAGE` | % of the booking total | `0`–`100` | Optional max amount off per booking |
| `FLAT` | Fixed amount off the booking total | `>= 0` | Must be `NULL` |

Example: `discount = 20`, `PERCENTAGE`, `discount_upto = 500`.
A ₹1,000 booking gets ₹200 off; a ₹5,000 booking gets ₹500 off (not ₹1,000).

The admin form clears `discount_upto` automatically when the type is `FLAT`
(see `MembershipPlanRequest.toJson`).

### Trigger

| Trigger | When | What |
|---|---|---|
| `set_membership_plans_updated_at` | Before update | Sets `updated_at = now()`. |

---

## 2. Who Can Read / Write (RLS)

| Caller | Read | Create / update / delete |
|---|---|---|
| Anyone (mobile app, logged in or not) | Only plans with `is_active = true` | ❌ |
| Admin (`public.is_admin()`) | All plans, including inactive | ✅ |

---

## 3. Admin Panel

Sidebar: **Platform → Membership Plans** (`/membership-plans`).

Code lives in `guardup_admin/lib/features/membership/`:

| File | Purpose |
|---|---|
| `data/enums/discount_type.enum.dart` | `DiscountType` (`percentage`, `flat`) with labels and icons. |
| `data/models/membership_plan.model.dart` | Freezed `MembershipPlan` + helpers (`discountLabel`, `yearlySavings`, `yearlySavingsPercent`). |
| `data/models/membership_plan_request.model.dart` | Create / update payload. |
| `data/repositories/membership_plan.repository.dart` | Extends `BaseSupabaseRepository`. Searches by `name` only (`description` is an array). |
| `presentation/controllers/membership_plan.controller.dart` | List state: pagination, search, active filter, reorder, toggle active, delete. |
| `presentation/screens/membership_plan_management.screen.dart` | Table: drag to reorder, filter Active / Inactive, bulk delete, row tap opens details. |
| `presentation/screens/membership_plan.form.dart` | Side-panel form for add / edit. |
| `presentation/screens/membership_plan_details.screen.dart` | Details page at `/membership-plans/detail/:id`, with edit / activate / delete. |

**Deleting vs deactivating:** deactivating hides a plan from customers but keeps it.
Once customer subscriptions exist and reference this table, prefer deactivating;
deleting will need a rule for plans that have subscribers.
