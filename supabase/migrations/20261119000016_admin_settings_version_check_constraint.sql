-- ==============================================================================
-- MIGRATION: Enforce semantic versioning format in public.admin_settings
--
-- Ensures latest and minimum version fields strictly follow semver (e.g. 1.0.0, 2.12.3),
-- preventing invalid text, gibberish, or malformed version strings in the database.
-- ==============================================================================

ALTER TABLE public.admin_settings
  DROP CONSTRAINT IF EXISTS admin_settings_versions_semver_check;

ALTER TABLE public.admin_settings
  ADD CONSTRAINT admin_settings_versions_semver_check CHECK (
    latest_ios_version ~ '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$' AND
    minimum_ios_version ~ '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$' AND
    latest_android_version ~ '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$' AND
    minimum_android_version ~ '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$'
  );
