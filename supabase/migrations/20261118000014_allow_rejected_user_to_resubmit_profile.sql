-- ==============================================================================
-- MIGRATION: Allow rejected users to resubmit their profile for review
--
-- When a user's application or profile is rejected by an administrator, the user
-- must be allowed to update their profile details (bio, name, address, services, etc.)
-- or resubmit existing valid documents to transition from REJECTED -> PENDING_APPROVAL.
--
-- Updates guard_user_status_and_role() to permit:
-- OLD.status IN ('INCOMPLETE', 'REJECTED') AND NEW.status = 'PENDING_APPROVAL'
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.guard_user_status_and_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF current_user NOT IN ('authenticated', 'anon') OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.role IS DISTINCT FROM OLD.role THEN
    RAISE EXCEPTION 'You cannot change your role'
      USING ERRCODE = '42501';
  END IF;

  IF NEW.rejection_reason IS DISTINCT FROM OLD.rejection_reason THEN
    RAISE EXCEPTION 'You cannot change the rejection reason'
      USING ERRCODE = '42501';
  END IF;

  IF NEW.status IS DISTINCT FROM OLD.status
     AND NOT (OLD.status IN ('INCOMPLETE', 'REJECTED') AND NEW.status = 'PENDING_APPROVAL') THEN
    RAISE EXCEPTION 'You cannot change your status from % to %', OLD.status, NEW.status
      USING ERRCODE = '42501',
            HINT = 'To delete your account call the delete_user() RPC.';
  END IF;

  RETURN NEW;
END;
$$;

