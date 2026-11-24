-- Migration: Add address, latitude, and longitude to public.bodyguards
-- Allows both self-registered and company-managed bodyguards to store their specific service area / deployed location.

ALTER TABLE public.bodyguards
S address TEXT,
ADD COLUMN IF NOT EXISTS latitude NUMERIC(10, 7),
ADD COLUMN IF NOT EXISTS longitude NUMERIC(10, 7);

COMMENT ON COLUMN public.bodyguards.address IS
  'Service area or deployed address of the bodyguard.';
COMMENT ON COLUMN public.bodyguards.latitude IS
  'Latitude coordinate of the service area.';
COMMENT ON COLUMN public.bodyguards.longitude IS
  'Longitude coordinate of the service area.';

-- Sync address and coordinates for self-registered bodyguards (users is source of truth)
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
    SELECT name, profile_image_url, gender, address, latitude, longitude INTO v_user
    FROM public.users
    WHERE id = NEW.user_id;

    IF FOUND THEN
      NEW.name := COALESCE(v_user.name, '');
      NEW.profile_image_url := v_user.profile_image_url;
      IF NEW.address IS NULL THEN
        NEW.address := v_user.address;
        NEW.latitude := v_user.latitude;
        NEW.longitude := v_user.longitude;
      END IF;
    END IF;
  END IF;

  NEW.name := COALESCE(btrim(NEW.name), '');
  RETURN NEW;
END;
$$;

-- Backfill existing self-registered bodyguards from users
UPDATE public.bodyguards b
SET address = u.address,
    latitude = u.latitude,
    longitude = u.longitude
FROM public.users u
WHERE b.user_id = u.id
  AND b.address IS NULL;

-- Backfill existing company-managed bodyguards from the owning company's user address
UPDATE public.bodyguards b
SET address = u.address,
    latitude = u.latitude,
    longitude = u.longitude
FROM public.companies c
JOIN public.users u ON u.id = c.user_id
WHERE b.company_id = c.id
  AND b.user_id IS NULL
  AND b.address IS NULL;
