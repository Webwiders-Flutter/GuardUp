-- ==============================================================================
-- Migration: Unify user_status enum to remove duplicate 'APPROVED'
-- Standardizes user statuses: INCOMPLETE, PENDING_APPROVAL, ACTIVE, REJECTED, BLOCKED, DELETED
-- Any existing rows with 'APPROVED' are converted to 'ACTIVE'.
-- ==============================================================================

-- 1. Ensure any rows currently using 'APPROVED' are updated to 'ACTIVE'
UPDATE public.users 
SET status = 'ACTIVE' 
WHERE status::text = 'APPROVED';

-- 2. Drop dependent triggers and indexes before altering the column type
DROP TRIGGER IF EXISTS on_user_status_deleted ON public.users;
DROP INDEX IF EXISTS idx_users_status;
DROP INDEX IF EXISTS idx_users_active_email;
DROP INDEX IF EXISTS idx_users_active_phone;

-- 3. Drop default constraint from users table
ALTER TABLE public.users ALTER COLUMN status DROP DEFAULT;

-- 4. Rename old enum
ALTER TYPE public.user_status RENAME TO user_status_old;

-- 5. Create clean new enum without APPROVED
CREATE TYPE public.user_status AS ENUM (
  'INCOMPLETE',
  'PENDING_APPROVAL',
  'ACTIVE',
  'REJECTED',
  'BLOCKED',
  'DELETED'
);

-- 6. Convert public.users.status to the new enum
ALTER TABLE public.users 
  ALTER COLUMN status TYPE public.user_status 
  USING (
    CASE 
      WHEN status::text = 'APPROVED' THEN 'ACTIVE'::public.user_status
      ELSE status::text::public.user_status
    END
  );

-- 7. Restore default value
ALTER TABLE public.users ALTER COLUMN status SET DEFAULT 'INCOMPLETE'::public.user_status;

-- 8. Recreate indexes
CREATE INDEX IF NOT EXISTS idx_users_status ON public.users(status);

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_active_email 
ON public.users (LOWER(email)) 
WHERE status != 'DELETED';

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_active_phone 
ON public.users (phone_code, phone_number) 
WHERE status != 'DELETED' AND phone_number IS NOT NULL AND phone_number != '';

-- 9. Re-compile handle_new_user() with new enum
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  raw_role TEXT;
  assigned_role public.user_role;
  initial_status public.user_status;
BEGIN
  raw_role := UPPER(COALESCE(NEW.raw_user_meta_data->>'role', 'CUSTOMER'));
  
  IF raw_role = 'GUARD' THEN
    assigned_role := 'GUARD';
    initial_status := 'INCOMPLETE';
  ELSIF raw_role = 'COMPANY' THEN
    assigned_role := 'COMPANY';
    initial_status := 'INCOMPLETE';
  ELSE
    assigned_role := 'CUSTOMER';
    initial_status := 'ACTIVE';
  END IF;

  INSERT INTO public.users (
    id,
    email,
    name,
    phone_code,
    phone_number,
    role,
    status
  ) VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'phone_code', '+91'),
    NEW.raw_user_meta_data->>'phone',
    assigned_role,
    initial_status
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Re-compile handle_user_status_deleted() and recreate trigger
CREATE OR REPLACE FUNCTION public.handle_user_status_deleted()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'DELETED' AND (OLD.status IS DISTINCT FROM 'DELETED') THEN
    DELETE FROM auth.users WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_user_status_deleted
  AFTER UPDATE OF status ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_status_deleted();

-- 11. Drop the old enum
DROP TYPE public.user_status_old;
