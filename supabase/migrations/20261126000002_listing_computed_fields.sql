-- ==============================================================================
-- MIGRATION: Computed fields for the customer listings (companies, bodyguards)
--
-- Full write-up: documentation/user_profiles.md (section "Listings and filters")
--
-- Why: public.users is readable only by its owner and admins, so a customer's
-- PostgREST embed `user:users!companies_user_id_fkey!inner(status)` always comes
-- back empty and the `!inner` join removed every company from the list. These
-- functions read the related rows on the server instead. No tables, columns or
-- RLS policies change.
--
-- Objects:
--   1. account_status(companies)          computed field: users.status of the
--                                         company account (SECURITY DEFINER,
--                                         returns only the status)
--   2. listing_services(bodyguards)       computed relationship: user_services
--                                         of a bodyguard, keyed by bodyguard_id
--                                         (company-managed) or user_id
--                                         (self-registered)
--   3. listing_availabilities(bodyguards) computed relationship: the same for
--                                         user_availabilities
--
-- Usage (PostgREST):
--   companies?select=*,account_status&account_status=in.(ACTIVE)
--   bodyguards?select=*,services:listing_services(id,service:services(*))
--   bodyguards?select=*,f:listing_services!inner(service_id)&f.service_id=in.(…)
-- ==============================================================================

-- 1. companies.account_status ----------------------------------------------------
-- SECURITY DEFINER because users is not readable by other accounts. It exposes
-- only the status, and only for company rows the caller can already read
-- (companies RLS: owner, admins, or ACTIVE accounts).
CREATE OR REPLACE FUNCTION public.account_status(public.companies)
RETURNS public.user_status
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT u.status FROM public.users u WHERE u.id = $1.user_id;
$$;

COMMENT ON FUNCTION public.account_status(public.companies) IS
  'Computed field: users.status of the company account. Lets every role filter companies by account status without reading users.';

-- 2. bodyguards -> user_services (both owner keys) -------------------------------
-- SECURITY INVOKER: user_services is publicly readable, RLS still applies.
CREATE OR REPLACE FUNCTION public.listing_services(public.bodyguards)
RETURNS SETOF public.user_services
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT us.*
  FROM public.user_services us
  WHERE us.bodyguard_id = $1.id
     OR ($1.user_id IS NOT NULL AND us.user_id = $1.user_id);
$$;

COMMENT ON FUNCTION public.listing_services(public.bodyguards) IS
  'Computed relationship: services of a bodyguard, whether company-managed (bodyguard_id) or self-registered (user_id).';

-- 3. bodyguards -> user_availabilities (both owner keys) -------------------------
-- SECURITY INVOKER: user_availabilities is publicly readable, RLS still applies.
CREATE OR REPLACE FUNCTION public.listing_availabilities(public.bodyguards)
RETURNS SETOF public.user_availabilities
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT ua.*
  FROM public.user_availabilities ua
  WHERE ua.bodyguard_id = $1.id
     OR ($1.user_id IS NOT NULL AND ua.user_id = $1.user_id);
$$;

COMMENT ON FUNCTION public.listing_availabilities(public.bodyguards) IS
  'Computed relationship: weekly availability of a bodyguard, whether company-managed (bodyguard_id) or self-registered (user_id).';

-- Grants -------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.account_status(public.companies) FROM public, anon;
REVOKE ALL ON FUNCTION public.listing_services(public.bodyguards) FROM public, anon;
REVOKE ALL ON FUNCTION public.listing_availabilities(public.bodyguards) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.account_status(public.companies) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.listing_services(public.bodyguards) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.listing_availabilities(public.bodyguards) TO authenticated, service_role;

-- PostgREST must see the new functions before the app uses them.
NOTIFY pgrst, 'reload schema';
