-- ==============================================================================
-- MIGRATION: Language per device in public.user_devices
--
-- Each FCM token (one row = one device) now carries the language that device
-- wants its push notifications in. Same model as Supplr.
--
-- Rules (all keyed on the token):
--   - Token not in the table yet      -> new row (user, platform, language).
--   - Token already in the table      -> row is re-assigned to the caller,
--                                        re-activated and its language updated.
--   - App language changed            -> only that token's language changes.
--   - Two devices, different languages -> two rows, each with its own language.
--   - FCM issues a new token          -> registered as a new row; the old token
--                                        is pruned after its first failed push.
--
-- 1. Column + check
-- 2. register_user_device(p_token, p_platform, p_language_code)
-- 3. update_user_device_language(p_token, p_language_code)
-- ==============================================================================

-- 1. Column --------------------------------------------------------------------
ALTER TABLE public.user_devices
  ADD COLUMN IF NOT EXISTS language_code text NOT NULL DEFAULT 'en';

ALTER TABLE public.user_devices
  DROP CONSTRAINT IF EXISTS user_devices_language_code_check;

-- ISO 639 language code as given by Flutter's Locale.languageCode (en, hi, ...).
ALTER TABLE public.user_devices
  ADD CONSTRAINT user_devices_language_code_check
  CHECK (language_code ~ '^[a-z]{2,3}$');

COMMENT ON COLUMN public.user_devices.language_code IS
  'Language this device receives push notifications in (ISO 639, lower-case). Default en.';

-- Shared normaliser: trims + lower-cases, keeps only the base language
-- ("en-US" / "en_US" -> "en"). NULL / blank stays NULL.
CREATE OR REPLACE FUNCTION public.normalize_language_code(p_language_code text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT NULLIF(split_part(replace(lower(btrim(p_language_code)), '_', '-'), '-', 1), '');
$$;

-- 2. RPC: register_user_device -------------------------------------------------
-- Replaces the 2-argument version. p_language_code is optional: when omitted,
-- a new row gets 'en' and an existing row keeps its current language.
DROP FUNCTION IF EXISTS public.register_user_device(text, text);

CREATE OR REPLACE FUNCTION public.register_user_device(
  p_token text,
  p_platform text DEFAULT NULL,
  p_language_code text DEFAULT NULL
)
RETURNS public.user_devices
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_language text := public.normalize_language_code(p_language_code);
  v_device public.user_devices;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF p_token IS NULL OR btrim(p_token) = '' THEN
    RAISE EXCEPTION 'Device token is required' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.user_devices
    (user_id, token, platform, language_code, is_active, last_active_at)
  VALUES
    (v_user_id, p_token, lower(p_platform), COALESCE(v_language, 'en'), true, NOW())
  ON CONFLICT (token) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    platform = COALESCE(lower(p_platform), public.user_devices.platform),
    language_code = COALESCE(v_language, public.user_devices.language_code),
    is_active = true,
    last_active_at = NOW()
  RETURNING * INTO v_device;

  RETURN v_device;
END;
$$;

REVOKE ALL ON FUNCTION public.register_user_device(text, text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.register_user_device(text, text, text) TO authenticated, service_role;

-- 3. RPC: update_user_device_language ------------------------------------------
-- Changes the language of one device (the caller's token). Other devices of
-- the same user keep their own language.
CREATE OR REPLACE FUNCTION public.update_user_device_language(
  p_token text,
  p_language_code text
)
RETURNS public.user_devices
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_language text := public.normalize_language_code(p_language_code);
  v_device public.user_devices;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF p_token IS NULL OR btrim(p_token) = '' THEN
    RAISE EXCEPTION 'Device token is required' USING ERRCODE = '22023';
  END IF;

  IF v_language IS NULL THEN
    RAISE EXCEPTION 'Language code is required' USING ERRCODE = '22023';
  END IF;

  UPDATE public.user_devices
  SET language_code = v_language,
      last_active_at = NOW()
  WHERE token = p_token
    AND user_id = v_user_id
  RETURNING * INTO v_device;

  -- NULL when the token is not registered for this user yet; the app then
  -- registers it with register_user_device (which also sets the language).
  RETURN v_device;
END;
$$;

REVOKE ALL ON FUNCTION public.update_user_device_language(text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.update_user_device_language(text, text) TO authenticated, service_role;
