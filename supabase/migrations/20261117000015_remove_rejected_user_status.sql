-- ==============================================================================
-- MIGRATION: Remove 'REJECTED' from public.user_status
--
-- Rejection is no longer a status. Rejecting an applicant now means deleting
-- them while they are PENDING_APPROVAL, which removes the public.users row and
-- the auth user completely (see 20261117000016_user_deletion_rules.sql and
-- documentation/user_deletion.md).
--
-- Statuses after this migration:
--   INCOMPLETE, PENDING_APPROVAL, ACTIVE, BLOCKED, DELETED
--
-- Existing REJECTED rows are moved back to PENDING_APPROVAL so an admin can
-- review them again (approve, or delete = reject).
--
-- Postgres cannot drop a value from an enum, so the type is recreated.
-- The status triggers are dropped here because a column used in an
-- "UPDATE OF status" trigger cannot change type; they are recreated by
-- 20261117000016_user_deletion_rules.sql, which must run right after this one.
-- ==============================================================================

-- 1. Drop triggers that depend on users.status (recreated in ..._000016)
DROP TRIGGER IF EXISTS trg_users_lifecycle_events ON public.users;
DROP TRIGGER IF EXISTS on_user_status_deleted ON public.users;

-- 2. Move existing REJECTED users back into the review queue.
--    Runs with the status triggers dropped, so no notifications are sent.
UPDATE public.users
SET status = 'PENDING_APPROVAL',
    updated_at = NOW()
WHERE status::text = 'REJECTED';

-- 3. Drop indexes and default that reference the column
DROP INDEX IF EXISTS public.idx_users_status;
DROP INDEX IF EXISTS public.idx_users_active_email;
DROP INDEX IF EXISTS public.idx_users_active_phone;

ALTER TABLE public.users ALTER COLUMN status DROP DEFAULT;

-- 4. Recreate the enum without REJECTED
ALTER TYPE public.user_status RENAME TO user_status_old;

CREATE TYPE public.user_status AS ENUM (
  'INCOMPLETE',
  'PENDING_APPROVAL',
  'ACTIVE',
  'BLOCKED',
  'DELETED'
);

ALTER TABLE public.users
  ALTER COLUMN status TYPE public.user_status
  USING status::text::public.user_status;

ALTER TABLE public.users
  ALTER COLUMN status SET DEFAULT 'INCOMPLETE'::public.user_status;

DROP TYPE public.user_status_old;

-- 5. Recreate indexes
CREATE INDEX IF NOT EXISTS idx_users_status ON public.users (status);

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_active_email
  ON public.users (LOWER(email))
  WHERE status <> 'DELETED';

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_active_phone
  ON public.users (phone_code, phone_number)
  WHERE status <> 'DELETED' AND phone_number IS NOT NULL AND phone_number <> '';
