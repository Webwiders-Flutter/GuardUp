-- Migration: Remove phone_code, phone_number, and gender from public.bodyguards table

-- 1. Drop trigger on public.users that pushed gender to bodyguards
DROP TRIGGER IF EXISTS trg_users_push_identity_to_bodyguard ON public.users;

-- 2. Update push_user_identity_to_bodyguard() to not check gender
CREATE OR REPLACE FUNCTION public.push_user_identity_to_bodyguard()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.name IS DISTINCT FROM OLD.name
     OR NEW.profile_image_url IS DISTINCT FROM OLD.profile_image_url
     OR NEW.status IS DISTINCT FROM OLD.status
     OR NEW.rejection_reason IS DISTINCT FROM OLD.rejection_reason THEN
    -- trg_bodyguards_sync_identity copies the new values in.
    UPDATE public.bodyguards SET updated_at = NOW() WHERE user_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

-- Recreate trigger without gender
CREATE TRIGGER trg_users_push_identity_to_bodyguard
AFTER UPDATE OF name, profile_image_url, status, rejection_reason ON public.users
FOR EACH ROW EXECUTE FUNCTION public.push_user_identity_to_bodyguard();

-- 3. Update sync_bodyguard_identity() to not copy gender
CREATE OR REPLACE FUNCTION public.sync_bodyguard_identity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user record;
BEGIN
  IF NEW.user_id IS NOT NULL THEN
    SELECT name, profile_image_url, status, rejection_reason INTO v_user
    FROM public.users
    WHERE id = NEW.user_id;

    IF FOUND THEN
      NEW.name := COALESCE(v_user.name, '');
      NEW.profile_image_url := v_user.profile_image_url;
      NEW.status := v_user.status;
      NEW.rejection_reason := v_user.rejection_reason;
    END IF;
  END IF;

  NEW.name := COALESCE(btrim(NEW.name), '');
  RETURN NEW;
END;
$$;

-- 4. Drop the columns from public.bodyguards
ALTER TABLE public.bodyguards
  DROP COLUMN IF EXISTS gender,
  DROP COLUMN IF EXISTS phone_code,
  DROP COLUMN IF EXISTS phone_number;
