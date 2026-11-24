-- Migration: Remove address, latitude, and longitude from public.users table
-- Address and service area coordinates belong exclusively to public.bodyguards.

-- 1. Update sync_bodyguard_identity so it does not reference dropped user columns
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
    SELECT name, profile_image_url INTO v_user
    FROM public.users
    WHERE id = NEW.user_id;

    IF FOUND THEN
      NEW.name := COALESCE(v_user.name, '');
      NEW.profile_image_url := v_user.profile_image_url;
    END IF;
  END IF;

  NEW.name := COALESCE(btrim(NEW.name), '');
  RETURN NEW;
END;
$$;

-- 2. Drop columns from public.users
ALTER TABLE public.users
  DROP COLUMN IF EXISTS address CASCADE,
  DROP COLUMN IF EXISTS latitude CASCADE,
  DROP COLUMN IF EXISTS longitude CASCADE;

NOTIFY pgrst, 'reload schema';
