-- ==============================================================================
-- MIGRATION: Send notification email on profile / application rejection
--
-- Previously, when an admin rejected a profile or documents (status -> REJECTED),
-- only an in-app notification & FCM push were sent.
-- This migration updates handle_user_lifecycle_events() to also invoke the
-- user-lifecycle-events Edge Function for PROFILE_REJECTED, sending an email
-- with the specific rejection reason or rejected documents.
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
  v_title text;
  v_body text;
  v_tokens jsonb;
  v_rejected_docs text;
  v_is_self boolean := auth.uid() IS NOT NULL AND auth.uid() = NEW.id;
  -- Set by preserve_deleted_user_on_auth_delete(): the auth user is already
  -- being deleted, so it must not be deleted again from here.
  v_auth_already_deleting boolean :=
    COALESCE(current_setting('guardup.auth_deleting_user_id', true), '') = NEW.id::text;
  -- Never approved -> nothing worth keeping.
  v_hard_delete boolean :=
    NEW.status = 'DELETED' AND OLD.status IN ('INCOMPLETE', 'PENDING_APPROVAL', 'REJECTED');
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  -- ---------------------------------------------------------------------------
  -- A. Notifications & Emails (never block the status change)
  -- ---------------------------------------------------------------------------
  IF NEW.role <> 'ADMIN' THEN
    BEGIN
      v_event := CASE
        WHEN NEW.status = 'PENDING_APPROVAL' AND OLD.status = 'INCOMPLETE' THEN 'SUBMITTED'
        WHEN NEW.status = 'ACTIVE' AND OLD.status IN ('PENDING_APPROVAL', 'REJECTED') THEN 'APPROVED'
        WHEN NEW.status = 'ACTIVE' AND OLD.status = 'BLOCKED' THEN 'UNBLOCKED'
        WHEN NEW.status = 'REJECTED' THEN 'PROFILE_REJECTED'
        WHEN NEW.status = 'BLOCKED' THEN 'BLOCKED'
        -- Admin deletes an application that is still awaiting review.
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

        ELSIF v_event = 'PROFILE_REJECTED' THEN
          -- Status-based rejection: in-app notification & push.
          -- Profile reason wins; otherwise list the rejected documents.
          SELECT string_agg(COALESCE(dt.name, 'Document'), ', ' ORDER BY dt.display_order)
          INTO v_rejected_docs
          FROM public.user_documents d
          LEFT JOIN public.document_types dt ON dt.id = d.document_type_id
          WHERE d.user_id = NEW.id
            AND d.status = 'REJECTED';

          v_body := CASE
            WHEN NULLIF(btrim(NEW.rejection_reason), '') IS NOT NULL THEN
              'Your application was not approved. Reason: ' || btrim(NEW.rejection_reason)
            WHEN v_rejected_docs IS NOT NULL THEN
              'Some of your documents were rejected: ' || v_rejected_docs
                || '. Please check them in the app for details.'
            ELSE
              'Your application was not approved. Please contact support for details.'
          END;

          INSERT INTO public.notifications (user_id, type, title, body, data)
          VALUES (
            NEW.id,
            'ACCOUNT_REJECTED',
            'Application not approved',
            v_body,
            v_data || jsonb_build_object('rejection_reason', NEW.rejection_reason)
          );

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
        -- after a hard delete).
        IF v_event IN ('APPROVED', 'REJECTED', 'DELETED', 'PROFILE_REJECTED')
           AND COALESCE(btrim(NEW.email), '') LIKE '%@%' THEN
          PERFORM public.invoke_edge_function(
            'user-lifecycle-events',
            jsonb_build_object(
              'event', CASE WHEN v_event = 'PROFILE_REJECTED' THEN 'REJECTED' ELSE v_event END,
              'user_id', NEW.id,
              'email', btrim(NEW.email),
              'name', v_name,
              'role', NEW.role::text,
              'rejection_reason', NEW.rejection_reason,
              'rejected_documents', v_rejected_docs
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
