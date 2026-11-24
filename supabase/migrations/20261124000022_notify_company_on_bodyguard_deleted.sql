-- ==============================================================================
-- MIGRATION: Notify the company when an admin deletes its bodyguard
--
-- Full write-up: documentation/user_profiles.md (section "Bodyguard verification")
--
-- Follow-up to 20261124000021_bodyguard_verification_status.sql. Admins can
-- now delete a company-managed bodyguard from the admin panel (Company
-- Bodyguards listing), like they delete accounts. Deleting removes the row
-- and, through ON DELETE CASCADE, its services, documents and availability.
--
-- The company is notified (in-app + push, no email) with the existing
-- ACCOUNT_DELETED type; data.event = 'BODYGUARD_DELETED' and
-- data.bodyguard_id identify the bodyguard, data.user_id is the company
-- account (same shape as the other bodyguard events).
--
-- Not notified:
--   - the company deleting its own bodyguard (it did it itself)
--   - bodyguards removed because the company account itself is removed
--     (the company row / account is gone, nothing to notify)
--
-- Never blocks the delete.
--
-- Objects:
--   1. notify_company_on_bodyguard_deleted()   (AFTER DELETE on bodyguards)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.notify_company_on_bodyguard_deleted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_company_user_id uuid;
  v_name text := COALESCE(NULLIF(btrim(OLD.name), ''), 'Bodyguard');
BEGIN
  IF OLD.user_id IS NOT NULL OR NOT COALESCE(public.is_admin(), false) THEN
    RETURN OLD;
  END IF;

  BEGIN
    SELECT c.user_id INTO v_company_user_id
    FROM public.companies c
    JOIN public.users u ON u.id = c.user_id
    WHERE c.id = OLD.company_id
      AND u.status <> 'DELETED';

    IF v_company_user_id IS NULL THEN
      RETURN OLD;
    END IF;

    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
      v_company_user_id,
      'ACCOUNT_DELETED',
      'Bodyguard removed',
      v_name || ' has been removed by GuardUp. Please contact support for details.',
      jsonb_build_object(
        'event', 'BODYGUARD_DELETED',
        'user_id', v_company_user_id,
        'bodyguard_id', OLD.id,
        'role', 'GUARD'
      )
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Bodyguard deletion notification failed for bodyguard %: %',
      OLD.id, SQLERRM;
  END;

  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_bodyguards_notify_deleted ON public.bodyguards;
CREATE TRIGGER trg_bodyguards_notify_deleted
AFTER DELETE ON public.bodyguards
FOR EACH ROW EXECUTE FUNCTION public.notify_company_on_bodyguard_deleted();
