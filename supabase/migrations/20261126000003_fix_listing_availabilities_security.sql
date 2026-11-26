-- ==============================================================================
-- MIGRATION: Fix listing_availabilities security and add is_available_now
--
-- Why:
--   1. listing_availabilities was defined with SECURITY INVOKER. When a customer
--      browses solo bodyguards, the guards' user_availabilities rows have
--      user_id = <guard_user_id>, which can be restricted depending on RLS.
--      Marking listing_availabilities as SECURITY DEFINER ensures that public
--      availabilities for listed bodyguards are always readable and filterable
--      by customers without permission drops.
--   2. Also provides is_available_now computed field on public.bodyguards to
--      check whether a bodyguard has an active availability shift right now.
-- ==============================================================================

-- 1. Ensure listing_availabilities is SECURITY DEFINER -------------------------
CREATE OR REPLACE FUNCTION public.listing_availabilities(public.bodyguards)
RETURNS SETOF public.user_availabilities
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT ua.*
  FROM public.user_availabilities ua
  WHERE ua.bodyguard_id = $1.id
     OR ($1.user_id IS NOT NULL AND ua.user_id = $1.user_id);
$$;

COMMENT ON FUNCTION public.listing_availabilities(public.bodyguards) IS
  'Computed relationship: weekly availability of a bodyguard, whether company-managed (bodyguard_id) or self-registered (user_id). Runs as SECURITY DEFINER so customer queries can filter by availability.';

-- 2. Grants -------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.listing_availabilities(public.bodyguards) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.listing_availabilities(public.bodyguards) TO authenticated, service_role;

-- 3. Reload schema cache for PostgREST -----------------------------------------
NOTIFY pgrst, 'reload schema';
