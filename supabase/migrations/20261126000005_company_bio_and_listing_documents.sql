-- ==============================================================================
-- MIGRATION: Add bio to companies & computed relationship listing_documents
--
-- Why:
--   1. Companies need a biography/overview column (bio) that can be edited in
--      their profile and displayed in the company details About tab.
--   2. In company details, verified documents need to be embedded, but documents
--      must NOT be joined in the company listing queries (to keep listings lean).
--   3. public.user_documents RLS restricts SELECT to owner or admin. A computed
--      relationship `listing_documents(public.companies)` running as SECURITY DEFINER
--      allows PostgREST to embed verified documents on company detail queries.
-- ==============================================================================

-- 1. Add bio column to public.companies -----------------------------------------
ALTER TABLE public.companies
  ADD COLUMN IF NOT EXISTS bio text;

COMMENT ON COLUMN public.companies.bio IS
  'Company biography / overview written by the company.';

-- 2. Computed relationship: listing_documents(public.companies) ----------------
CREATE OR REPLACE FUNCTION public.listing_documents(public.companies)
RETURNS SETOF public.user_documents
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT ud.*
  FROM public.user_documents ud
  WHERE ud.user_id = $1.user_id;
$$;

COMMENT ON FUNCTION public.listing_documents(public.companies) IS
  'Computed relationship: user_documents belonging to this company account. Runs as SECURITY DEFINER so company details can embed verified documents.';

-- Grants -------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.listing_documents(public.companies) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.listing_documents(public.companies) TO authenticated, service_role;

-- Reload schema in PostgREST ---------------------------------------------------
NOTIFY pgrst, 'reload schema';
