-- ==============================================================================
-- MIGRATION: Create public.user_devices
--
-- Stores FCM push tokens per user device. Used by the send-notification
-- Edge Function to deliver push notifications.
--
-- 1. Table + indexes
-- 2. updated_at trigger
-- 3. RLS: users manage their own devices, admins manage all
-- 4. RPC register_user_device: safe upsert that re-assigns a token to the
--    current user (a token can move between accounts on the same phone)
-- ==============================================================================

-- 1. Table ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_devices (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  token text NOT NULL,
  platform text NULL,
  is_active boolean NOT NULL DEFAULT true,
  last_active_at timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_devices_pkey PRIMARY KEY (id),
  CONSTRAINT user_devices_token_key UNIQUE (token),
  CONSTRAINT user_devices_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.users (id) ON DELETE CASCADE,
  CONSTRAINT user_devices_platform_check
    CHECK (platform IS NULL OR platform IN ('android', 'ios', 'web'))
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_user_devices_user_id
  ON public.user_devices USING btree (user_id) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_user_devices_user_active
  ON public.user_devices USING btree (user_id) TABLESPACE pg_default
  WHERE is_active = true;

-- 2. updated_at trigger --------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_user_devices_updated_at ON public.user_devices;
CREATE TRIGGER set_user_devices_updated_at
BEFORE UPDATE ON public.user_devices
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();

-- 3. Row Level Security --------------------------------------------------------
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users and admins can view devices" ON public.user_devices;
DROP POLICY IF EXISTS "Users and admins can insert devices" ON public.user_devices;
DROP POLICY IF EXISTS "Users and admins can update devices" ON public.user_devices;
DROP POLICY IF EXISTS "Users and admins can delete devices" ON public.user_devices;

CREATE POLICY "Users and admins can view devices"
  ON public.user_devices
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Users and admins can insert devices"
  ON public.user_devices
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Users and admins can update devices"
  ON public.user_devices
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id OR public.is_admin())
  WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Users and admins can delete devices"
  ON public.user_devices
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id OR public.is_admin());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.user_devices TO authenticated;
GRANT ALL ON TABLE public.user_devices TO postgres, service_role;

-- 4. RPC: register_user_device -------------------------------------------------
-- A plain client upsert fails when the token row still belongs to another
-- account (RLS blocks the UPDATE). This SECURITY DEFINER helper always
-- assigns the token to the calling user and re-activates it.
CREATE OR REPLACE FUNCTION public.register_user_device(
  p_token text,
  p_platform text DEFAULT NULL
)
RETURNS public.user_devices
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_device public.user_devices;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF p_token IS NULL OR btrim(p_token) = '' THEN
    RAISE EXCEPTION 'Device token is required' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.user_devices (user_id, token, platform, is_active, last_active_at)
  VALUES (v_user_id, p_token, lower(p_platform), true, NOW())
  ON CONFLICT (token) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    platform = COALESCE(EXCLUDED.platform, public.user_devices.platform),
    is_active = true,
    last_active_at = NOW()
  RETURNING * INTO v_device;

  RETURN v_device;
END;
$$;

REVOKE ALL ON FUNCTION public.register_user_device(text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.register_user_device(text, text) TO authenticated, service_role;
