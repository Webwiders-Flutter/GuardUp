-- ==============================================================================
-- MIGRATION: Remove the role profile columns from public.users
--
-- Follow-up to 20261124000019_split_user_profiles.sql, which copied them to
-- public.companies / public.bodyguards and moved every reader and writer
-- (triggers, view, both apps) to the new tables.
--
-- Kept on users (account data, every role): name, email, phone, role, status,
-- rejection_reason, profile_image_url, gender, address, latitude, longitude,
-- is_push_notification_enabled, metadata.
--
-- After this migration an old app build that writes e.g. users.hourly_rate
-- gets an error, so ship the app update together with this migration.
-- ==============================================================================

DROP INDEX IF EXISTS public.idx_users_company_phone;

ALTER TABLE public.users
  DROP COLUMN IF EXISTS hourly_rate,
  DROP COLUMN IF EXISTS bio,
  DROP COLUMN IF EXISTS rating,
  DROP COLUMN IF EXISTS experience_years,
  DROP COLUMN IF EXISTS languages,
  DROP COLUMN IF EXISTS certifications,
  DROP COLUMN IF EXISTS company_name,
  DROP COLUMN IF EXISTS business_email,
  DROP COLUMN IF EXISTS company_type,
  DROP COLUMN IF EXISTS company_phone_code,
  DROP COLUMN IF EXISTS company_phone_number;

NOTIFY pgrst, 'reload schema';
