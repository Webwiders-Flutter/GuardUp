-- ==============================================================================
-- MIGRATION: Restore status & rejection_reason sync in sync_bodyguard_identity()
--
-- Why:
--   Migration 20261124000025_add_address_and_coordinates_to_bodyguards.sql
--   overwrote sync_bodyguard_identity() and inadvertently dropped
--   `NEW.status := v_user.status` and `NEW.rejection_reason := v_user.rejection_reason`
--   (while also referencing `users.address`, which was dropped in 20261124000026).
--   As a result, approved solo guards had `users.status = 'ACTIVE'` while
--   `bodyguards.status` remained `'INCOMPLETE'`.
-- ==============================================================================

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
    SELECT
      name,
      profile_image_url,
      status,
      rejection_reason
    INTO v_user
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

-- Backfill status and rejection_reason for existing self-registered bodyguards
UPDATE public.bodyguards b
SET status = u.status,
    rejection_reason = u.rejection_reason
FROM public.users u
WHERE b.user_id = u.id
  AND (
    b.status IS DISTINCT FROM u.status
    OR b.rejection_reason IS DISTINCT FROM u.rejection_reason
  );
