-- ==============================================================================
-- MIGRATION: Add experience_years to public.users
-- ==============================================================================

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS experience_years INTEGER DEFAULT 0;

COMMENT ON COLUMN public.users.experience_years IS
  'Years of professional or operational experience';
