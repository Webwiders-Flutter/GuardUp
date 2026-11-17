-- Migration: Create public.admin_settings table for GuardUp platform configuration

-- 1. Ensure handle_updated_at function exists
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Create admin_settings table with GuardUp branding and fees
CREATE TABLE IF NOT EXISTS public.admin_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  latest_ios_version text NOT NULL DEFAULT '1.0.0'::text,
  latest_android_version text NOT NULL DEFAULT '1.0.0'::text,
  minimum_ios_version text NOT NULL DEFAULT '1.0.0'::text,
  minimum_android_version text NOT NULL DEFAULT '1.0.0'::text,
  ios_app_url text NULL DEFAULT 'https://apps.apple.com/app/guardup'::text,
  android_app_url text NULL DEFAULT 'https://play.google.com/store/apps/details?id=com.guardup.app'::text,
  support_email text NOT NULL DEFAULT 'support@guardup.com'::text,
  support_call_phone_number text NOT NULL DEFAULT '+919876543210'::text,
  support_whatsapp_phone_number text NOT NULL DEFAULT '+919876543210'::text,
  support_hours text NULL DEFAULT '10:00 AM - 7:00 PM (Mon-Sat)'::text,
  is_under_maintenance boolean NOT NULL DEFAULT false,
  maintenance_title text NULL DEFAULT 'App Under Maintenance'::text,
  maintenance_message text NULL DEFAULT 'We are currently upgrading our systems. Please check back shortly.'::text,
  bodyguard_fee numeric NOT NULL DEFAULT 0.00,
  company_fee numeric NOT NULL DEFAULT 0.00,
  singleton_guard boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  update_message_ios text NULL DEFAULT 'A new version of the app is available. Please update to continue using GuardUp.'::text,
  update_message_android text NULL DEFAULT 'A new version of the app is available. Please update to continue using GuardUp.'::text,
  CONSTRAINT admin_settings_pkey PRIMARY KEY (id),
  CONSTRAINT admin_settings_singleton_guard_key UNIQUE (singleton_guard),
  CONSTRAINT admin_settings_singleton_guard_check CHECK ((singleton_guard = true))
) TABLESPACE pg_default;

-- 3. Set updated_at trigger
DROP TRIGGER IF EXISTS set_admin_settings_updated_at ON public.admin_settings;
CREATE TRIGGER set_admin_settings_updated_at
BEFORE UPDATE ON public.admin_settings
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;

-- 5. Public read policy (allows clients/apps to check maintenance & version requirements before login)
DROP POLICY IF EXISTS "Anyone can view admin settings" ON public.admin_settings;
CREATE POLICY "Anyone can view admin settings"
ON public.admin_settings
FOR SELECT
TO public
USING (true);

-- 6. Admin update policy (only authenticated users with ADMIN role can update)
DROP POLICY IF EXISTS "Admins can update admin settings" ON public.admin_settings;
CREATE POLICY "Admins can update admin settings"
ON public.admin_settings
FOR UPDATE
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- 7. Admin insert policy
DROP POLICY IF EXISTS "Admins can insert admin settings" ON public.admin_settings;
CREATE POLICY "Admins can insert admin settings"
ON public.admin_settings
FOR INSERT
TO authenticated
WITH CHECK (public.is_admin());

-- 8. Seed default singleton row if table is empty
INSERT INTO public.admin_settings (singleton_guard)
VALUES (true)
ON CONFLICT (singleton_guard) DO NOTHING;
