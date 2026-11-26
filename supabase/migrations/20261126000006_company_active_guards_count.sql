-- ==============================================================================
-- MIGRATION: Add active_guards computed field on public.companies
--
-- Why:
--   Company cards and company details display the count of active guards
--   belonging to the company. A computed field `active_guards(public.companies)`
--   lets PostgREST return the exact count in the listing & detail queries
--   without extra round-trips.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.active_guards(public.companies)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT count(*)::integer
  FROM public.bodyguards b
  WHERE b.company_id = $1.id
    AND b.user_id IS NULL
    AND b.status = 'ACTIVE';
$$;

COMMENT ON FUNCTION public.active_guards(public.companies) IS
  'Computed field: count of ACTIVE company-managed bodyguards belonging to this company.';

REVOKE ALL ON FUNCTION public.active_guards(public.companies) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.active_guards(public.companies) TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';
