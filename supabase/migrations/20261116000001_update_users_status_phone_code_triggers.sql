-- ==============================================================================
-- GUARDUP MIGRATION: Update Users Schema, Phone Code, Realtime & Deletion Triggers
-- ==============================================================================

-- 1. Default column values for rating and hourly rate
ALTER TABLE public.users ALTER COLUMN hourly_rate SET DEFAULT 0.00;
ALTER TABLE public.users ALTER COLUMN rating SET DEFAULT 0.0;
UPDATE public.users SET hourly_rate = 0.00 WHERE hourly_rate = 60.00 OR hourly_rate IS NULL;
UPDATE public.users SET rating = 0.0 WHERE rating = 5.0 OR rating IS NULL;

-- 2. Add phone_code column to public.users
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone_code TEXT DEFAULT '+91';
UPDATE public.users SET phone_code = '+91' WHERE phone_code IS NULL;

-- 3. Drop foreign key cascade constraint
-- Prevents public.users rows from being deleted when auth.users row is deleted
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_id_fkey;

-- 4. Drop hard unique constraint on email & set partial unique indexes
-- If an account is DELETED, its email and phone number are freed for reuse
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_email_key;

DROP INDEX IF EXISTS public.idx_users_active_email;
DROP INDEX IF EXISTS public.idx_users_active_phone;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_active_email 
ON public.users (LOWER(email)) 
WHERE status != 'DELETED';

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_active_phone 
ON public.users (phone_code, phone_number) 
WHERE status != 'DELETED' AND phone_number IS NOT NULL AND phone_number != '';

-- 5. Update handle_new_user() trigger function to persist phone_code
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

-- 6. Trigger: When status = 'DELETED' in public.users, delete from auth.users
CREATE OR REPLACE FUNCTION public.handle_user_status_deleted()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'DELETED' AND (OLD.status IS DISTINCT FROM 'DELETED') THEN
    DELETE FROM auth.users WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_user_status_deleted ON public.users;
CREATE TRIGGER on_user_status_deleted
  AFTER UPDATE OF status ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_status_deleted();

-- 7. Trigger: When user is deleted from auth.users, keep public.users row with status = 'DELETED'
CREATE OR REPLACE FUNCTION public.preserve_deleted_user_on_auth_delete()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.users
  SET status = 'DELETED',
      updated_at = NOW()
  WHERE id = OLD.id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_deleted ON auth.users;
CREATE TRIGGER on_auth_user_deleted
  BEFORE DELETE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.preserve_deleted_user_on_auth_delete();

-- 8. Enable Realtime Replication for users table
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

