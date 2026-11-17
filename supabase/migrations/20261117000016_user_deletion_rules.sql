-- ==============================================================================
-- MIGRATION: User deletion rules + delete_user RPC
--
-- Full write-up: documentation/user_deletion.md
--
-- Setting public.users.status = 'DELETED' is the ONLY way to delete a user.
-- Everything else follows from the status the user had before:
--
--   Previous status              public.users row         auth.users   Storage files
--   INCOMPLETE / PENDING_APPROVAL Hard deleted (+cascade)  Deleted      Deleted
--   ACTIVE / BLOCKED              Kept, status = DELETED   Deleted      Kept
--
-- Rejecting an applicant = deleting them while PENDING_APPROVAL.
--
-- Who did it decides the message (auth.uid() = the user -> self-delete):
--   PENDING_APPROVAL, deleted by admin / system  -> REJECTED  email + push
--   anything else                                -> DELETED   email (+ in-app
--                                                   notification when the row is kept)
--
-- Objects:
--   1. purge_user_storage(user_id)          internal: async storage cleanup
--   2. handle_user_lifecycle_events()       ONE trigger for notifications AND
--                                           deletion, so ordering is guaranteed
--                                           (replaces handle_user_status_deleted)
--   3. preserve_deleted_user_on_auth_delete deleting an auth user from the
--                                           dashboard follows the same rules
--   4. delete_user(p_user_id)               RPC used by both apps
-- ==============================================================================

-- 1. purge_user_storage ---------------------------------------------------------
-- Storage objects cannot be removed with plain SQL, so the purge-user-storage
-- Edge Function deletes everything under "<user_id>/" in the user buckets.
-- Fire-and-forget through pg_net: never blocks or fails the deletion.
CREATE OR REPLACE FUNCTION public.purge_user_storage(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
  IF p_user_id IS NULL THEN
    RETURN;
  END IF;

  PERFORM public.invoke_edge_function(
    'purge-user-storage',
    jsonb_build_object('user_id', p_user_id)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.purge_user_storage(uuid) FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.purge_user_storage(uuid) TO service_role;

-- 2. Lifecycle + deletion trigger ----------------------------------------------
DROP TRIGGER IF EXISTS on_user_status_deleted ON public.users;
DROP FUNCTION IF EXISTS public.handle_user_status_deleted();

CREATE OR REPLACE FUNCTION public.handle_user_lifecycle_events()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_event text;
  v_name text;
  v_role_label text;
  v_data jsonb;
  v_title text;
  v_body text;
  v_tokens jsonb;
  v_is_self boolean := auth.uid() IS NOT NULL AND auth.uid() = NEW.id;
  -- Set by preserve_deleted_user_on_auth_delete(): the auth user is already
  -- being deleted, so it must not be deleted again from here.
  v_auth_already_deleting boolean :=
    COALESCE(current_setting('guardup.auth_deleting_user_id', true), '') = NEW.id::text;
  v_hard_delete boolean :=
    NEW.status = 'DELETED' AND OLD.status IN ('INCOMPLETE', 'PENDING_APPROVAL');
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  -- ---------------------------------------------------------------------------
  -- A. Notifications (never block the status change)
  -- ---------------------------------------------------------------------------
  IF NEW.role <> 'ADMIN' THEN
    BEGIN
      v_event := CASE
        WHEN NEW.status = 'PENDING_APPROVAL' AND OLD.status = 'INCOMPLETE' THEN 'SUBMITTED'
        WHEN NEW.status = 'ACTIVE' AND OLD.status = 'PENDING_APPROVAL' THEN 'APPROVED'
        WHEN NEW.status = 'ACTIVE' AND OLD.status = 'BLOCKED' THEN 'UNBLOCKED'
        WHEN NEW.status = 'BLOCKED' THEN 'BLOCKED'
        WHEN NEW.status = 'DELETED' AND OLD.status = 'PENDING_APPROVAL' AND NOT v_is_self THEN 'REJECTED'
        WHEN NEW.status = 'DELETED' THEN 'DELETED'
      END;

      IF v_event IS NOT NULL THEN
        v_name := COALESCE(NULLIF(btrim(NEW.company_name), ''), NULLIF(btrim(NEW.name), ''), 'User');
        v_role_label := CASE NEW.role
          WHEN 'GUARD' THEN 'Bodyguard'
          WHEN 'COMPANY' THEN 'Company'
          ELSE 'Customer'
        END;
        v_data := jsonb_build_object('event', v_event, 'user_id', NEW.id, 'role', NEW.role::text);

        IF v_event = 'SUBMITTED' THEN
          -- Tell every admin there is a new application to review
          INSERT INTO public.notifications (user_id, type, title, body, data)
          SELECT
            a.id,
            'NEW_USER_REGISTRATION',
            'New registration: ' || v_name,
            v_name || ' (' || v_role_label || ') has submitted their profile and is awaiting review.',
            v_data || jsonb_build_object('applicant_name', v_name, 'email', NEW.email)
          FROM public.users a
          WHERE a.role = 'ADMIN'
            AND a.status <> 'DELETED';
        ELSE
          v_title := CASE v_event
            WHEN 'APPROVED' THEN 'Account approved'
            WHEN 'REJECTED' THEN 'Application not approved'
            WHEN 'BLOCKED' THEN 'Account suspended'
            WHEN 'UNBLOCKED' THEN 'Account restored'
            WHEN 'DELETED' THEN 'Account deleted'
          END;
          v_body := CASE v_event
            WHEN 'APPROVED' THEN 'Your profile has been verified. Welcome to GuardUp!'
            WHEN 'REJECTED' THEN 'Your application could not be approved. You are welcome to register again.'
            WHEN 'BLOCKED' THEN 'Your GuardUp account has been suspended. Please contact support.'
            WHEN 'UNBLOCKED' THEN 'Your GuardUp account is active again.'
            WHEN 'DELETED' THEN 'Your GuardUp account has been deleted.'
          END;

          IF v_hard_delete THEN
            -- The row (and its notifications / devices) is about to be removed,
            -- so an in-app row is pointless. Push straight to the device tokens,
            -- collected now, before the cascade deletes them. Self-deletes get
            -- no push: the user is in the app and just confirmed it.
            IF NOT v_is_self THEN
              SELECT jsonb_agg(d.token) INTO v_tokens
              FROM public.user_devices d
              WHERE d.user_id = NEW.id
                AND d.is_active;

              IF v_tokens IS NOT NULL AND jsonb_array_length(v_tokens) > 0 THEN
                PERFORM public.invoke_edge_function(
                  'send-notification',
                  jsonb_build_object(
                    'action', 'send_to_tokens',
                    'tokens', v_tokens,
                    'title', v_title,
                    'body', v_body,
                    'type', CASE v_event WHEN 'REJECTED' THEN 'ACCOUNT_REJECTED' ELSE 'ACCOUNT_DELETED' END,
                    'data', v_data,
                    'save_to_db', false
                  )
                );
              END IF;
            END IF;
          ELSE
            -- Row is kept: in-app notification; the notifications INSERT
            -- trigger sends the push.
            INSERT INTO public.notifications (user_id, type, title, body, data)
            VALUES (
              NEW.id,
              CASE v_event
                WHEN 'APPROVED' THEN 'ACCOUNT_APPROVED'
                WHEN 'REJECTED' THEN 'ACCOUNT_REJECTED'
                WHEN 'BLOCKED' THEN 'ACCOUNT_BLOCKED'
                WHEN 'UNBLOCKED' THEN 'ACCOUNT_UNBLOCKED'
                WHEN 'DELETED' THEN 'ACCOUNT_DELETED'
              END::public.notification_type,
              v_title,
              v_body,
              v_data
            );
          END IF;
        END IF;

        -- Emails (the address travels in the payload, so this also works
        -- after a hard delete)
        IF v_event IN ('APPROVED', 'REJECTED', 'DELETED')
           AND COALESCE(btrim(NEW.email), '') LIKE '%@%' THEN
          PERFORM public.invoke_edge_function(
            'user-lifecycle-events',
            jsonb_build_object(
              'event', v_event,
              'user_id', NEW.id,
              'email', btrim(NEW.email),
              'name', v_name,
              'role', NEW.role::text
            )
          );
        END IF;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'User lifecycle notification failed for user % (% -> %): %',
        NEW.id, OLD.status, NEW.status, SQLERRM;
    END;
  END IF;

  -- ---------------------------------------------------------------------------
  -- B. Deletion (errors here DO abort the status change, so a user is never
  --    left half-deleted)
  -- ---------------------------------------------------------------------------
  IF NEW.status = 'DELETED' THEN
    -- Remove the login. Frees the email / phone in Supabase Auth.
    IF NOT v_auth_already_deleting THEN
      DELETE FROM auth.users WHERE id = NEW.id;
    END IF;

    -- Never approved: remove the row too. user_documents, user_services,
    -- user_devices and notifications go with it (ON DELETE CASCADE).
    IF v_hard_delete THEN
      PERFORM public.purge_user_storage(NEW.id);
      DELETE FROM public.users WHERE id = NEW.id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_lifecycle_events ON public.users;
CREATE TRIGGER trg_users_lifecycle_events
AFTER UPDATE OF status ON public.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_user_lifecycle_events();

-- 3. Auth user deleted directly (dashboard / admin API) ---------------------------
-- Marks the profile DELETED, which runs the same rules as above. The flag stops
-- the lifecycle trigger from deleting this auth row a second time (that would
-- fail with "tuple to be deleted was already modified").
CREATE OR REPLACE FUNCTION public.preserve_deleted_user_on_auth_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM set_config('guardup.auth_deleting_user_id', OLD.id::text, true);

  UPDATE public.users
  SET status = 'DELETED',
      updated_at = NOW()
  WHERE id = OLD.id
    AND status <> 'DELETED';

  PERFORM set_config('guardup.auth_deleting_user_id', '', true);
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_deleted ON auth.users;
CREATE TRIGGER on_auth_user_deleted
  BEFORE DELETE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.preserve_deleted_user_on_auth_delete();

-- 4. RPC: delete_user -----------------------------------------------------------
-- p_user_id omitted -> the caller deletes their own account.
-- p_user_id given   -> admins only (this is also how an admin rejects).
-- Admin accounts cannot be deleted through this RPC.
--
-- Returns: { user_id, previous_status, hard_deleted }
CREATE OR REPLACE FUNCTION public.delete_user(p_user_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller uuid := auth.uid();
  v_target uuid;
  v_user record;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  v_target := COALESCE(p_user_id, v_caller);

  IF v_target <> v_caller AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can delete other users' USING ERRCODE = '42501';
  END IF;

  SELECT id, role, status INTO v_user
  FROM public.users
  WHERE id = v_target
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_user.role = 'ADMIN' THEN
    RAISE EXCEPTION 'Admin accounts cannot be deleted' USING ERRCODE = '42501';
  END IF;

  IF v_user.status = 'DELETED' THEN
    -- Already deleted: just make sure the login is gone too.
    DELETE FROM auth.users WHERE id = v_target;
    RETURN jsonb_build_object(
      'user_id', v_target,
      'previous_status', 'DELETED',
      'hard_deleted', false
    );
  END IF;

  -- The lifecycle trigger does the rest.
  UPDATE public.users
  SET status = 'DELETED',
      updated_at = NOW()
  WHERE id = v_target;

  RETURN jsonb_build_object(
    'user_id', v_target,
    'previous_status', v_user.status::text,
    'hard_deleted', v_user.status IN ('INCOMPLETE', 'PENDING_APPROVAL')
  );
END;
$$;

REVOKE ALL ON FUNCTION public.delete_user(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.delete_user(uuid) TO authenticated, service_role;
