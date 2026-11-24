-- ==============================================================================
-- MIGRATION: Company-managed bodyguards cannot be blocked
--
-- Full write-up: documentation/user_profiles.md (section "Bodyguard verification")
--
-- Follow-up to 20261124000021_bodyguard_verification_status.sql. An admin
-- only approves, rejects or deletes a company-managed bodyguard; blocking is
-- for login accounts (customers, guards, companies). The company itself can
-- still switch a bodyguard off (bodyguards.is_active).
--
-- A company bodyguard that was blocked before this migration keeps its status
-- (it can be unblocked back to ACTIVE or deleted); it can no longer become
-- BLOCKED again.
--
-- Self-registered bodyguards are unaffected: their status is copied from the
-- GUARD account (users.status), which can still be blocked.
--
-- Objects:
--   1. prevent_company_bodyguard_block()   (BEFORE UPDATE OF status on bodyguards)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.prevent_company_bodyguard_block()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.user_id IS NULL
     AND NEW.status = 'BLOCKED'
     AND OLD.status IS DISTINCT FROM 'BLOCKED' THEN
    RAISE EXCEPTION 'Company bodyguards cannot be blocked. Reject or delete the bodyguard instead.'
      USING ERRCODE = '22023';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_bodyguards_prevent_company_block ON public.bodyguards;
CREATE TRIGGER trg_bodyguards_prevent_company_block
BEFORE UPDATE OF status ON public.bodyguards
FOR EACH ROW EXECUTE FUNCTION public.prevent_company_bodyguard_block();
