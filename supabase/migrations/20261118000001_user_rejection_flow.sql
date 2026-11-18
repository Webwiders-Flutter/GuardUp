-- ==============================================================================
-- MIGRATION: Application review flow (approve / reject with a reason)
--
-- Full write-up: documentation/user_review_and_rejection.md
--
-- An admin reviews a PENDING_APPROVAL (or REJECTED) guard / company:
--   * each document is approved or rejected (with a reason) on its own
--   * rejecting ANY document moves the user to REJECTED
--   * the profile itself can be rejected (with a reason) at any time
--   * the profile can be approved only once every document is APPROVED
--
-- Same pattern as block / unblock: the admin panel updates the rows directly
-- (RLS lets admins update users and user_documents) and triggers enforce the
-- rules and cascade the effects, so the rules hold for every writer (admin
-- panel, dashboard, service role).
--
--   Where the reason is stored:
--     document rejected -> public.user_documents.rejection_reason
--     profile rejected  -> public.users.rejection_reason
--
-- Moving to REJECTED only sends an in-app notification (+ push through the
-- notifications INSERT trigger). Nothing is deleted and no email is sent.
--
-- Everything else in handle_user_lifecycle_events is unchanged, except:
--   * REJECTED -> ACTIVE is an approval (same notification + email)
--   * REJECTED users are never-approved users, so deleting one is a hard delete
--     like INCOMPLETE / PENDING_APPROVAL
--
-- Objects:
--   1. users.rejection_reason
--   2. guard_user_status_and_role()       users cannot edit rejection_reason
--   3. guard_user_document_review()       users cannot insert reviewed documents
--   4. handle_user_lifecycle_events()     REJECTED notification
--   5. delete_user()                      hard_deleted includes REJECTED
--   6. enforce_user_document_review()     BEFORE UPDATE on user_documents:
--                                         review rules for a document
--   7. reject_user_on_document_rejected() AFTER UPDATE on user_documents:
--                                         rejected document -> user REJECTED
--   8. enforce_user_review_rules()        BEFORE UPDATE on users:
--                                         review rules for the profile
-- ==============================================================================

-- 1. Column --------------------------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

COMMENT ON COLUMN public.users.rejection_reason IS
  'Why the admin rejected the profile. Cleared automatically when the status leaves REJECTED.';
COMMENT ON COLUMN public.user_documents.rejection_reason IS
  'Why the admin rejected this document. Cleared automatically when the status leaves REJECTED.';

-- 2. Users cannot change their own rejection reason ----------------------------
-- Same rules as 20261117000017, plus rejection_reason.
CREATE OR REPLACE FUNCTION public.guard_user_status_and_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF current_user NOT IN ('authenticated', 'anon') OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.role IS DISTINCT FROM OLD.role THEN
    RAISE EXCEPTION 'You cannot change your role'
      USING ERRCODE = '42501';
  END IF;

  IF NEW.rejection_reason IS DISTINCT FROM OLD.rejection_reason THEN
    RAISE EXCEPTION 'You cannot change the rejection reason'
      USING ERRCODE = '42501';
  END IF;

  IF NEW.status IS DISTINCT FROM OLD.status
     AND NOT (OLD.status = 'INCOMPLETE' AND NEW.status = 'PENDING_APPROVAL') THEN
    RAISE EXCEPTION 'You cannot change your status from % to %', OLD.status, NEW.status
      USING ERRCODE = '42501',
            HINT = 'To delete your account call the delete_user() RPC.';
  END IF;

  RETURN NEW;
END;
$$;

-- 3. Users cannot insert already-reviewed documents ----------------------------
-- The UPDATE policy on user_documents already keeps a user's rows PENDING; the
-- INSERT policy only checks ownership. Approving a profile depends on document
-- status, so a client insert is always forced to PENDING with no reason.
-- Deliberately NOT security definer: current_user must be the caller's role.
CREATE OR REPLACE FUNCTION public.guard_user_document_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF current_user NOT IN ('authenticated', 'anon') OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  NEW.status := 'PENDING';
  NEW.rejection_reason := NULL;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_documents_guard_review ON public.user_documents;
CREATE TRIGGER trg_user_documents_guard_review
BEFORE INSERT ON public.user_documents
FOR EACH ROW
EXECUTE FUNCTION public.guard_user_document_review();

-- 4. Lifecycle + deletion trigger ----------------------------------------------
-- Copy of 20261117000016 with the changes listed in the header.
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
  -- A. Notifications (never block the status change)
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
          -- Status-based rejection: in-app notification only (push is sent by
          -- the notifications INSERT trigger). No email, nothing deleted.
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
        -- after a hard delete). PROFILE_REJECTED sends none.
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

-- Trigger definition is unchanged (trg_users_lifecycle_events, AFTER UPDATE OF
-- status); CREATE OR REPLACE above swaps the function body in place.

-- 5. delete_user: REJECTED users are hard deleted ------------------------------
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
    'hard_deleted', v_user.status IN ('INCOMPLETE', 'PENDING_APPROVAL', 'REJECTED')
  );
END;
$$;

REVOKE ALL ON FUNCTION public.delete_user(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.delete_user(uuid) TO authenticated, service_role;

-- Review rules (shared by sections 6-8) ---------------------------------------
-- A document or profile can be reviewed only while the user is
-- PENDING_APPROVAL or REJECTED. Rejecting needs a reason; approving clears it.
-- Errors use SQLSTATE 22023 so the admin panel shows the message as is.

-- 6. Document review rules -----------------------------------------------------
CREATE OR REPLACE FUNCTION public.enforce_user_document_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_status public.user_status;
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status
     AND NEW.rejection_reason IS NOT DISTINCT FROM OLD.rejection_reason THEN
    RETURN NEW;
  END IF;

  IF NEW.status IN ('APPROVED', 'REJECTED') THEN
    SELECT status INTO v_user_status FROM public.users WHERE id = NEW.user_id;

    IF v_user_status NOT IN ('PENDING_APPROVAL', 'REJECTED') THEN
      RAISE EXCEPTION 'Documents can only be reviewed while the application is pending or rejected (current status: %)', v_user_status
        USING ERRCODE = '22023';
    END IF;
  END IF;

  IF NEW.status = 'REJECTED' THEN
    NEW.rejection_reason := NULLIF(btrim(NEW.rejection_reason), '');
    IF NEW.rejection_reason IS NULL THEN
      RAISE EXCEPTION 'A rejection reason is required' USING ERRCODE = '22023';
    END IF;
  ELSE
    -- Only a rejected document carries a reason.
    NEW.rejection_reason := NULL;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_documents_review_rules ON public.user_documents;
CREATE TRIGGER trg_user_documents_review_rules
BEFORE UPDATE ON public.user_documents
FOR EACH ROW
EXECUTE FUNCTION public.enforce_user_document_review();

-- 7. Rejected document -> user REJECTED ----------------------------------------
-- AFTER the document row is written, so the lifecycle notification (fired by
-- the users update below) can already name the rejected document. Runs in the
-- same transaction as the document update: both happen or neither does.
CREATE OR REPLACE FUNCTION public.reject_user_on_document_rejected()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'REJECTED' AND OLD.status IS DISTINCT FROM 'REJECTED' THEN
    UPDATE public.users
    SET status = 'REJECTED',
        updated_at = NOW()
    WHERE id = NEW.user_id
      AND status = 'PENDING_APPROVAL';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_documents_reject_user ON public.user_documents;
CREATE TRIGGER trg_user_documents_reject_user
AFTER UPDATE OF status ON public.user_documents
FOR EACH ROW
EXECUTE FUNCTION public.reject_user_on_document_rejected();

-- 8. Profile review rules ------------------------------------------------------
-- Runs after trg_users_guard_status_and_role (BEFORE triggers fire in name
-- order), so users editing themselves are already stopped there.
CREATE OR REPLACE FUNCTION public.enforce_user_review_rules()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_open_docs int;
BEGIN
  -- Approval: PENDING_APPROVAL / REJECTED -> ACTIVE
  IF NEW.status = 'ACTIVE' AND OLD.status IN ('PENDING_APPROVAL', 'REJECTED') THEN
    SELECT count(*) INTO v_open_docs
    FROM public.user_documents
    WHERE user_id = NEW.id
      AND status <> 'APPROVED';

    IF v_open_docs > 0 THEN
      RAISE EXCEPTION 'All documents must be approved before the profile can be approved (% not approved)', v_open_docs
        USING ERRCODE = '22023';
    END IF;

    NEW.rejection_reason := NULL;
    RETURN NEW;
  END IF;

  -- Rejection: only an application under review. Needs a profile reason,
  -- unless it comes from a rejected document (section 7).
  IF NEW.status = 'REJECTED' THEN
    IF OLD.status NOT IN ('PENDING_APPROVAL', 'REJECTED') THEN
      RAISE EXCEPTION 'Only applications awaiting review can be rejected (current status: %)', OLD.status
        USING ERRCODE = '22023';
    END IF;

    NEW.rejection_reason := NULLIF(btrim(NEW.rejection_reason), '');
    IF NEW.rejection_reason IS NULL
       AND NOT EXISTS (
         SELECT 1 FROM public.user_documents
         WHERE user_id = NEW.id AND status = 'REJECTED'
       ) THEN
      RAISE EXCEPTION 'A rejection reason is required' USING ERRCODE = '22023';
    END IF;
    RETURN NEW;
  END IF;

  -- The reason belongs to a rejected profile only.
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    NEW.rejection_reason := NULL;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_review_rules ON public.users;
CREATE TRIGGER trg_users_review_rules
BEFORE UPDATE ON public.users
FOR EACH ROW
EXECUTE FUNCTION public.enforce_user_review_rules();
