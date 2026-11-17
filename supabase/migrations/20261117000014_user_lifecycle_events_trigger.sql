-- ==============================================================================
-- MIGRATION: User lifecycle events (status transitions on public.users)
--
-- On every status change of a CUSTOMER / GUARD / COMPANY user:
--   1. Inserts in-app notification row(s) into public.notifications.
--      The notifications INSERT trigger then pushes them to devices.
--   2. For APPROVED / REJECTED / DELETED, calls the user-lifecycle-events
--      Edge Function (async, pg_net) to send the email.
--
--   Transition                                   Notified    Email
--   INCOMPLETE | REJECTED  -> PENDING_APPROVAL    all admins  -
--   PENDING_APPROVAL | REJECTED -> ACTIVE         user        approved
--   any -> REJECTED                               user        rejected
--   any -> BLOCKED                                user        -
--   BLOCKED -> ACTIVE                             user        -
--   any -> DELETED                                user        deleted
--
-- Runs alongside on_user_status_deleted (which removes the auth user on
-- DELETED); the public.users row stays, so the notification FK is valid.
-- ==============================================================================

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
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status OR NEW.role = 'ADMIN' THEN
    RETURN NEW;
  END IF;

  v_event := CASE
    WHEN NEW.status = 'PENDING_APPROVAL' AND OLD.status IN ('INCOMPLETE', 'REJECTED') THEN 'SUBMITTED'
    WHEN NEW.status = 'ACTIVE' AND OLD.status IN ('PENDING_APPROVAL', 'REJECTED') THEN 'APPROVED'
    WHEN NEW.status = 'ACTIVE' AND OLD.status = 'BLOCKED' THEN 'UNBLOCKED'
    WHEN NEW.status = 'REJECTED' THEN 'REJECTED'
    WHEN NEW.status = 'BLOCKED' THEN 'BLOCKED'
    WHEN NEW.status = 'DELETED' THEN 'DELETED'
  END;

  IF v_event IS NULL THEN
    RETURN NEW;
  END IF;

  v_name := COALESCE(NULLIF(btrim(NEW.company_name), ''), NULLIF(btrim(NEW.name), ''), 'User');
  v_role_label := CASE NEW.role
    WHEN 'GUARD' THEN 'Bodyguard'
    WHEN 'COMPANY' THEN 'Company'
    ELSE 'Customer'
  END;
  v_data := jsonb_build_object('event', v_event, 'user_id', NEW.id, 'role', NEW.role::text);

  -- 1. In-app notifications (push is sent by the notifications INSERT trigger)
  IF v_event = 'SUBMITTED' THEN
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
      CASE v_event
        WHEN 'APPROVED' THEN 'Account approved'
        WHEN 'REJECTED' THEN 'Application not approved'
        WHEN 'BLOCKED' THEN 'Account suspended'
        WHEN 'UNBLOCKED' THEN 'Account restored'
        WHEN 'DELETED' THEN 'Account deleted'
      END,
      CASE v_event
        WHEN 'APPROVED' THEN 'Your profile has been verified. Welcome to GuardUp!'
        WHEN 'REJECTED' THEN 'Your application could not be approved. Please contact support for details.'
        WHEN 'BLOCKED' THEN 'Your GuardUp account has been suspended. Please contact support.'
        WHEN 'UNBLOCKED' THEN 'Your GuardUp account is active again.'
        WHEN 'DELETED' THEN 'Your GuardUp account has been deleted.'
      END,
      v_data
    );
  END IF;

  -- 2. Emails
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

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Never block a status change because of a notification problem.
  RAISE WARNING 'User lifecycle event failed for user % (% -> %): %',
    NEW.id, OLD.status, NEW.status, SQLERRM;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_lifecycle_events ON public.users;
CREATE TRIGGER trg_users_lifecycle_events
AFTER UPDATE OF status ON public.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_user_lifecycle_events();
