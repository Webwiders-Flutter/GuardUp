-- ==============================================================================
-- MIGRATION: Ensure public.set_user_services RPC exists and is exposed to PostgREST
--
-- Why:
--   PostgREST returned PGRST202 ("Could not find the function
--   public.set_user_services(p_service_ids, p_user_id) in the schema cache").
--   Recreating the function with explicit grants and `NOTIFY pgrst, 'reload schema'`
--   ensures it exists in `public` and is visible to authenticated callers.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.set_user_services(
  p_user_id UUID,
  p_service_ids UUID[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL
     AND auth.uid() != p_user_id
     AND NOT COALESCE(public.is_admin(), false) THEN
    RAISE EXCEPTION 'Not authorized to modify services for this user'
      USING ERRCODE = '42501';
  END IF;

  DELETE FROM public.user_services WHERE user_id = p_user_id;

  IF p_service_ids IS NOT NULL AND array_length(p_service_ids, 1) > 0 THEN
    INSERT INTO public.user_services (user_id, service_id)
    SELECT DISTINCT p_user_id, s
    FROM UNNEST(p_service_ids) AS s;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.set_user_services(UUID, UUID[]) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.set_user_services(UUID, UUID[]) TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';
