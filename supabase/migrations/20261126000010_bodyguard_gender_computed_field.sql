-- ==============================================================================
-- MIGRATION: Add gender(public.bodyguards) computed field for filtering
--
-- Why:
--   `bodyguards.gender` was dropped in 20261124000024 and `users.gender` is
--   protected by `users` RLS (customers cannot read other users' rows).
--   Exposing `gender(public.bodyguards)` as a SECURITY DEFINER computed field
--   allows PostgREST to filter `gender=eq.MALE` / `FEMALE` / `OTHER` cleanly
--   on the server while preserving `users` RLS.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.gender(public.bodyguards)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT u.gender::text
  FROM public.users u
  WHERE $1.user_id IS NOT NULL
    AND u.id = $1.user_id;
$$;

COMMENT ON FUNCTION public.gender(public.bodyguards) IS
  'Computed field: gender of a self-registered bodyguard from public.users. Lets customers filter guards by gender without reading users.';

REVOKE ALL ON FUNCTION public.gender(public.bodyguards) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.gender(public.bodyguards) TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';
