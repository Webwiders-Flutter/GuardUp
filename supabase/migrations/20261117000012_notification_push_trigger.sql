-- ==============================================================================
-- MIGRATION: Auto push on public.notifications INSERT + batch RPC helper
--
-- 1. invoke_edge_function(name, payload): shared Vault + pg_net helper.
-- 2. AFTER INSERT trigger on public.notifications calls the send-notification
--    Edge Function through pg_net (async, never blocks or fails the insert).
--    Rows whose data contains "_push_handled": "true" are skipped, because the
--    Edge Function already pushed them itself (save_to_db = true path).
-- 3. RPC create_and_send_notification(user_ids[], ...) inserts one row per
--    user; the trigger then delivers the pushes.
--
-- Required Vault secrets (set once per project, see supabase/.env.example):
--   internal_function_secret -> shared secret sent as the x-internal-secret
--                               header; must equal the INTERNAL_FUNCTION_SECRET
--                               Edge Function secret
--   supabase_url             -> optional, defaults to the GuardUp project URL below
--
-- The service_role key is intentionally NOT used here: the trigger only needs
-- permission to call our functions, not full database access.
-- ==============================================================================

-- 1. Extensions ----------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- 2. Helper: invoke_edge_function ----------------------------------------------
-- Fire-and-forget POST to an Edge Function, authenticated with the
-- internal_function_secret from Vault (x-internal-secret header).
-- Never raises: failures are logged as warnings so the calling transaction
-- (e.g. a user status update) is never rolled back by a network problem.
-- Internal only: EXECUTE is revoked from every client role below.
CREATE OR REPLACE FUNCTION public.invoke_edge_function(
  p_function_name text,
  p_payload jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_supabase_url text;
  v_internal_secret text;
BEGIN
  BEGIN
    SELECT decrypted_secret INTO v_supabase_url
    FROM vault.decrypted_secrets
    WHERE name = 'supabase_url'
    LIMIT 1;

    SELECT decrypted_secret INTO v_internal_secret
    FROM vault.decrypted_secrets
    WHERE name = 'internal_function_secret'
    LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  v_supabase_url := COALESCE(
    NULLIF(v_supabase_url, ''),
    'https://xbdxsfnicuelqnsdwire.supabase.co'
  );

  IF COALESCE(v_internal_secret, '') = '' THEN
    RAISE WARNING 'Edge function "%" skipped: Vault secret "internal_function_secret" is not set', p_function_name;
    RETURN;
  END IF;

  BEGIN
    PERFORM net.http_post(
      url := v_supabase_url || '/functions/v1/' || p_function_name,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-internal-secret', v_internal_secret
      ),
      body := p_payload,
      timeout_milliseconds := 5000
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Edge function "%" dispatch failed: %', p_function_name, SQLERRM;
  END;
END;
$$;

REVOKE ALL ON FUNCTION public.invoke_edge_function(text, jsonb) FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.invoke_edge_function(text, jsonb) TO service_role;

-- 3. Trigger function ----------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_notification_inserted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
  -- Already pushed by the Edge Function that created this row.
  IF NEW.data->>'_push_handled' = 'true' THEN
    RETURN NEW;
  END IF;

  PERFORM public.invoke_edge_function(
    'send-notification',
    jsonb_build_object(
      'action', 'send_to_user_ids',
      'user_ids', jsonb_build_array(NEW.user_id),
      'title', NEW.title,
      'body', NEW.body,
      'type', NEW.type::text,
      'image_url', NEW.image_url,
      'data', NEW.data || jsonb_build_object('notification_id', NEW.id),
      'save_to_db', false -- row already exists
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_on_notification_inserted ON public.notifications;
CREATE TRIGGER trigger_on_notification_inserted
AFTER INSERT ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.handle_notification_inserted();

-- 4. RPC: create_and_send_notification -----------------------------------------
-- Inserts one notification per user id; the trigger above pushes each one.
-- Restricted to admins and service_role so regular users cannot message others.
CREATE OR REPLACE FUNCTION public.create_and_send_notification(
  p_user_ids uuid[],
  p_title text,
  p_body text,
  p_type public.notification_type DEFAULT 'SYSTEM',
  p_data jsonb DEFAULT '{}'::jsonb,
  p_image_url text DEFAULT NULL
)
RETURNS SETOF public.notifications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can send notifications' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  INSERT INTO public.notifications (user_id, type, title, body, data, image_url)
  SELECT DISTINCT
    u,
    p_type,
    p_title,
    p_body,
    COALESCE(p_data, '{}'::jsonb),
    p_image_url
  FROM unnest(p_user_ids) AS u
  RETURNING *;
END;
$$;

REVOKE ALL ON FUNCTION public.create_and_send_notification(uuid[], text, text, public.notification_type, jsonb, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.create_and_send_notification(uuid[], text, text, public.notification_type, jsonb, text) TO authenticated, service_role;
