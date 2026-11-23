-- ==============================================================================
-- MIGRATION: Deep link base URL in public.admin_settings
--
-- `deeplink_base_url` is the deployed web host that is registered for App Links
-- (Android assetlinks.json) and Universal Links (iOS apple-app-site-association).
-- Emails build "Open GuardUp" buttons as `<deeplink_base_url>/download`, which
-- opens the installed app directly instead of the store page.
-- ==============================================================================

ALTER TABLE public.admin_settings
  ADD COLUMN IF NOT EXISTS deeplink_base_url TEXT NULL
  DEFAULT 'https://guardup-991fd.web.app'::text;

COMMENT ON COLUMN public.admin_settings.deeplink_base_url IS
  'Deployed deep link host (no trailing slash). Emails link to <deeplink_base_url>/download to open the app.';

UPDATE public.admin_settings
SET deeplink_base_url = 'https://guardup-991fd.web.app'
WHERE deeplink_base_url IS NULL;
