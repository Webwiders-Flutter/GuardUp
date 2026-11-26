-- ==============================================================================
-- MIGRATION: Default user_availabilities.is_available to false
--
-- Why:
--   Availability should not be marked available by default when no explicit
--   schedule is set by the guard/company.
-- ==============================================================================

ALTER TABLE public.user_availabilities
  ALTER COLUMN is_available SET DEFAULT false;
