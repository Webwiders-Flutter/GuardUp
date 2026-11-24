-- ==============================================================================
-- MIGRATION: Admin verification of bodyguards (bodyguards.status)
--
-- Full write-up: documentation/user_profiles.md (section "Bodyguard verification")
--
-- Follow-up to 20261124000019_split_user_profiles.sql. Every bodyguard now has
-- a verification status with the same values as users.status:
--
--   self-registered  copied from users.status / users.rejection_reason, so the
--                    bodyguard is approved together with its account
--   company-managed  INCOMPLETE when the company creates it
--                    -> the company submits it        (PENDING_APPROVAL)
--                    -> an admin approves it           (ACTIVE)
--                       or rejects it with a reason    (REJECTED)
--                       and can block / unblock it     (BLOCKED <-> ACTIVE)
--                    Re-submitting after a rejection: INCOMPLETE / REJECTED
--                    -> PENDING_APPROVAL.
--
-- Documents of a company-managed bodyguard follow exactly the account rules:
-- reviewable only while the bodyguard is PENDING_APPROVAL / REJECTED, a
-- rejected document rejects the bodyguard, a re-submitted / approved one sends
-- it back to PENDING_APPROVAL once no document is still rejected, and the
-- bodyguard can only be approved once every document is approved.
--
-- Only ACTIVE bodyguards are listed to customers.
--
-- Notifications (in-app + push, existing types; data.event / data.bodyguard_id
-- identify the bodyguard):
--   submitted                    -> all admins  (NEW_USER_REGISTRATION)
--   approved / rejected /
--   blocked / unblocked          -> the company (ACCOUNT_*)
--
-- user_profiles also returns the whole profile rows as JSON (company,
-- bodyguard) for typed models in the admin panel.
--
-- Objects:
--   1. bodyguards.status, bodyguards.rejection_reason (+ backfill)
--   2. sync_bodyguard_identity() / push_user_identity_to_bodyguard(): status
--   3. guard_profile_ownership(): a company can only submit
--   4. enforce_bodyguard_review_rules()          (BEFORE UPDATE on bodyguards)
--   5. handle_bodyguard_lifecycle_events()       (AFTER UPDATE OF status)
--   6. Document review cascade for company-managed bodyguards
--   7. is_bodyguard_listed(): ACTIVE only
--   8. user_profiles: company / bodyguard JSON columns
-- ==============================================================================

-- 1. Columns -------------------------------------------------------------------
ALTER TABLE public.bodyguards
  ADD COLUMN IF NOT EXISTS status public.user_status NOT NULL DEFAULT 'INCOMPLETE',
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

CREATE INDEX IF NOT EXISTS idx_bodyguards_status ON public.bodyguards(status);

COMMENT ON COLUMN public.bodyguards.status IS
  'Verification status (same values as users.status). Self-registered: copied from users.status. Company-managed: reviewed by an admin (INCOMPLETE -> PENDING_APPROVAL -> ACTIVE / REJECTED).';
COMMENT ON COLUMN public.bodyguards.rejection_reason IS
  'Why the admin rejected a company-managed bodyguard. Self-registered: copied from users.rejection_reason.';

-- 2. Status follows the account for self-registered bodyguards ----------------------
CREATE OR REPLACE FUNCTION public.sync_bodyguard_identity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user record;
BEGIN
  IF NEW.user_id IS NOT NULL THEN
    SELECT name, profile_image_url, gender, status, rejection_reason INTO v_user
    FROM public.users
    WHERE id = NEW.user_id;

    IF FOUND THEN
      NEW.name := COALESCE(v_user.name, '');
      NEW.profile_image_url := v_user.profile_image_url;
      NEW.gender := v_user.gender;
      -- A self-registered bodyguard is approved together with its account.
      NEW.status := v_user.status;
      NEW.rejection_reason := v_user.rejection_reason;
    END IF;
  END IF;

  NEW.name := COALESCE(btrim(NEW.name), '');
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.push_user_identity_to_bodyguard()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.name IS DISTINCT FROM OLD.name
     OR NEW.profile_image_url IS DISTINCT FROM OLD.profile_image_url
     OR NEW.gender IS DISTINCT FROM OLD.gender
     OR NEW.status IS DISTINCT FROM OLD.status
     OR NEW.rejection_reason IS DISTINCT FROM OLD.rejection_reason THEN
    -- trg_bodyguards_sync_identity copies the new values in.
    UPDATE public.bodyguards SET updated_at = NOW() WHERE user_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_push_identity_to_bodyguard ON public.users;
CREATE TRIGGER trg_users_push_identity_to_bodyguard
AFTER UPDATE OF name, profile_image_url, gender, status, rejection_reason ON public.users
FOR EACH ROW EXECUTE FUNCTION public.push_user_identity_to_bodyguard();

-- Backfill (before the review / notification triggers exist, so nothing is
-- validated or notified):
--   self-registered  touch the row; trg_bodyguards_sync_identity copies status
--   company-managed  added before verification existed -> awaiting review
UPDATE public.bodyguards SET updated_at = NOW() WHERE user_id IS NOT NULL;
UPDATE public.bodyguards SET status = 'PENDING_APPROVAL' WHERE user_id IS NULL;

-- 3. Clients: a company can only submit its bodyguard for review ------------------
CREATE OR REPLACE FUNCTION public.guard_profile_ownership()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF current_user NOT IN ('authenticated', 'anon') OR COALESCE(public.is_admin(), false) THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.user_id IS DISTINCT FROM OLD.user_id THEN
    RAISE EXCEPTION 'The owner of a profile cannot be changed' USING ERRCODE = '42501';
  END IF;

  IF TG_TABLE_NAME = 'bodyguards' THEN
    IF TG_OP = 'UPDATE' AND NEW.company_id IS DISTINCT FROM OLD.company_id THEN
      RAISE EXCEPTION 'The company of a bodyguard cannot be changed' USING ERRCODE = '42501';
    END IF;

    -- Ratings come from reviews, never from the profile owner.
    IF TG_OP = 'INSERT' THEN
      NEW.rating := 0.0;
    ELSIF NEW.rating IS DISTINCT FROM OLD.rating THEN
      RAISE EXCEPTION 'You cannot change the rating' USING ERRCODE = '42501';
    END IF;

    -- Company-managed verification: the company can only submit (or
    -- resubmit) for review; approving, rejecting and blocking are admin-only.
    -- (Self-registered rows get their status from users in
    -- trg_bodyguards_sync_identity.)
    IF NEW.user_id IS NULL THEN
      IF TG_OP = 'INSERT' THEN
        NEW.status := 'INCOMPLETE';
        NEW.rejection_reason := NULL;
      ELSE
        IF NEW.rejection_reason IS DISTINCT FROM OLD.rejection_reason THEN
          RAISE EXCEPTION 'You cannot change the rejection reason' USING ERRCODE = '42501';
        END IF;
        IF NEW.status IS DISTINCT FROM OLD.status
           AND NOT (OLD.status IN ('INCOMPLETE', 'REJECTED') AND NEW.status = 'PENDING_APPROVAL') THEN
          RAISE EXCEPTION 'You cannot change the bodyguard status from % to %', OLD.status, NEW.status
            USING ERRCODE = '42501';
        END IF;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- 4. Review rules for a company-managed bodyguard --------------------------------
-- Same rules as enforce_user_review_rules() (users), for every writer:
--   approve (-> ACTIVE)   only from PENDING_APPROVAL / REJECTED, every document
--                         APPROVED; clears the reason
--   reject  (-> REJECTED) only from PENDING_APPROVAL / REJECTED; needs a reason
--                         unless a document is rejected
--   other changes keep the last reason
-- Who may do what is enforced by guard_profile_ownership() (clients can only
-- submit); admins use the RLS UPDATE policy.
CREATE OR REPLACE FUNCTION public.enforce_bodyguard_review_rules()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_open_docs int;
BEGIN
  IF NEW.user_id IS NOT NULL OR NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  IF NEW.status = 'ACTIVE' AND OLD.status IN ('PENDING_APPROVAL', 'REJECTED') THEN
    SELECT count(*) INTO v_open_docs
    FROM public.user_documents
    WHERE bodyguard_id = NEW.id
      AND status <> 'APPROVED';

    IF v_open_docs > 0 THEN
      RAISE EXCEPTION 'All documents must be approved before the bodyguard can be approved (% not approved)', v_open_docs
        USING ERRCODE = '22023';
    END IF;

    NEW.rejection_reason := NULL;
    RETURN NEW;
  END IF;

  IF NEW.status = 'REJECTED' THEN
    IF OLD.status NOT IN ('PENDING_APPROVAL', 'REJECTED') THEN
      RAISE EXCEPTION 'Only bodyguards awaiting review can be rejected (current status: %)', OLD.status
        USING ERRCODE = '22023';
    END IF;

    NEW.rejection_reason := NULLIF(btrim(NEW.rejection_reason), '');
    IF NEW.rejection_reason IS NULL
       AND NOT EXISTS (
         SELECT 1 FROM public.user_documents
         WHERE bodyguard_id = NEW.id AND status = 'REJECTED'
       ) THEN
      RAISE EXCEPTION 'A rejection reason is required' USING ERRCODE = '22023';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_bodyguards_review_rules ON public.bodyguards;
CREATE TRIGGER trg_bodyguards_review_rules
BEFORE UPDATE ON public.bodyguards
FOR EACH ROW EXECUTE FUNCTION public.enforce_bodyguard_review_rules();

-- 5. Notifications for a company-managed bodyguard --------------------------------
-- Never blocks the status change. No email.
CREATE OR REPLACE FUNCTION public.handle_bodyguard_lifecycle_events()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_company record;
  v_event text;
  v_name text := COALESCE(NULLIF(btrim(NEW.name), ''), 'Bodyguard');
  v_rejected_docs text;
  v_data jsonb;
BEGIN
  IF NEW.user_id IS NOT NULL OR NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  BEGIN
    SELECT c.user_id, COALESCE(NULLIF(btrim(c.company_name), ''), u.name, 'Company') AS name
    INTO v_company
    FROM public.companies c
    JOIN public.users u ON u.id = c.user_id
    WHERE c.id = NEW.company_id;

    IF NOT FOUND THEN
      RETURN NEW;
    END IF;

    v_event := CASE
      WHEN NEW.status = 'PENDING_APPROVAL' AND OLD.status IN ('INCOMPLETE', 'REJECTED') THEN 'BODYGUARD_SUBMITTED'
      WHEN NEW.status = 'ACTIVE' AND OLD.status IN ('PENDING_APPROVAL', 'REJECTED') THEN 'BODYGUARD_APPROVED'
      WHEN NEW.status = 'ACTIVE' AND OLD.status = 'BLOCKED' THEN 'BODYGUARD_UNBLOCKED'
      WHEN NEW.status = 'REJECTED' THEN 'BODYGUARD_REJECTED'
      WHEN NEW.status = 'BLOCKED' THEN 'BODYGUARD_BLOCKED'
    END;

    IF v_event IS NULL THEN
      RETURN NEW;
    END IF;

    v_data := jsonb_build_object(
      'event', v_event,
      'user_id', v_company.user_id,
      'bodyguard_id', NEW.id,
      'role', 'GUARD'
    );

    IF v_event = 'BODYGUARD_SUBMITTED' THEN
      INSERT INTO public.notifications (user_id, type, title, body, data)
      SELECT
        a.id,
        'NEW_USER_REGISTRATION',
        'New bodyguard to review: ' || v_name,
        v_name || ' (bodyguard of ' || v_company.name || ') has been submitted and is awaiting review.',
        v_data || jsonb_build_object('applicant_name', v_name, 'company_name', v_company.name)
      FROM public.users a
      WHERE a.role = 'ADMIN'
        AND a.status <> 'DELETED';
    ELSE
      IF v_event = 'BODYGUARD_REJECTED' THEN
        SELECT string_agg(COALESCE(dt.name, 'Document'), ', ' ORDER BY dt.display_order)
        INTO v_rejected_docs
        FROM public.user_documents d
        LEFT JOIN public.document_types dt ON dt.id = d.document_type_id
        WHERE d.bodyguard_id = NEW.id
          AND d.status = 'REJECTED';
      END IF;

      INSERT INTO public.notifications (user_id, type, title, body, data)
      VALUES (
        v_company.user_id,
        CASE v_event
          WHEN 'BODYGUARD_APPROVED' THEN 'ACCOUNT_APPROVED'
          WHEN 'BODYGUARD_REJECTED' THEN 'ACCOUNT_REJECTED'
          WHEN 'BODYGUARD_BLOCKED' THEN 'ACCOUNT_BLOCKED'
          ELSE 'ACCOUNT_UNBLOCKED'
        END::public.notification_type,
        CASE v_event
          WHEN 'BODYGUARD_APPROVED' THEN 'Bodyguard approved'
          WHEN 'BODYGUARD_REJECTED' THEN 'Bodyguard not approved'
          WHEN 'BODYGUARD_BLOCKED' THEN 'Bodyguard suspended'
          ELSE 'Bodyguard restored'
        END,
        CASE v_event
          WHEN 'BODYGUARD_APPROVED' THEN v_name || ' has been verified and is now visible to customers.'
          WHEN 'BODYGUARD_REJECTED' THEN
            CASE
              WHEN NULLIF(btrim(NEW.rejection_reason), '') IS NOT NULL THEN
                v_name || ' was not approved. Reason: ' || btrim(NEW.rejection_reason)
              WHEN v_rejected_docs IS NOT NULL THEN
                'Some documents of ' || v_name || ' were rejected: ' || v_rejected_docs || '.'
              ELSE v_name || ' was not approved. Please contact support for details.'
            END
          WHEN 'BODYGUARD_BLOCKED' THEN v_name || ' has been suspended. Please contact support.'
          ELSE v_name || ' is active again.'
        END,
        v_data || jsonb_build_object('rejection_reason', NEW.rejection_reason)
      );
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Bodyguard lifecycle notification failed for bodyguard % (% -> %): %',
      NEW.id, OLD.status, NEW.status, SQLERRM;
  END;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_bodyguards_lifecycle_events ON public.bodyguards;
CREATE TRIGGER trg_bodyguards_lifecycle_events
AFTER UPDATE OF status ON public.bodyguards
FOR EACH ROW EXECUTE FUNCTION public.handle_bodyguard_lifecycle_events();

-- 6. Document review cascade ------------------------------------------------------
-- Copies of the account versions (20261118000001 / 20261118000003 /
-- 20261124000019) with a bodyguards.status branch for documents owned by a
-- company-managed bodyguard (user_id NULL, bodyguard_id set).
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
    IF NEW.user_id IS NOT NULL THEN
      SELECT status INTO v_user_status FROM public.users WHERE id = NEW.user_id;
    ELSE
      SELECT status INTO v_user_status FROM public.bodyguards WHERE id = NEW.bodyguard_id;
    END IF;

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
  ELSIF NEW.status = 'APPROVED' THEN
    -- Approval is the only thing that clears the reason.
    NEW.rejection_reason := NULL;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.reject_user_on_document_rejected()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'REJECTED' AND OLD.status IS DISTINCT FROM 'REJECTED' THEN
    IF NEW.user_id IS NOT NULL THEN
      UPDATE public.users
      SET status = 'REJECTED',
          updated_at = NOW()
      WHERE id = NEW.user_id
        AND status = 'PENDING_APPROVAL';
    ELSE
      UPDATE public.bodyguards
      SET status = 'REJECTED'
      WHERE id = NEW.bodyguard_id
        AND user_id IS NULL
        AND status = 'PENDING_APPROVAL';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.pending_user_on_document_resubmitted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.status = 'REJECTED' AND NEW.status IN ('PENDING', 'APPROVED') THEN
    IF NEW.user_id IS NOT NULL THEN
      UPDATE public.users u
      SET status = 'PENDING_APPROVAL',
          updated_at = NOW()
      WHERE u.id = NEW.user_id
        AND u.status = 'REJECTED'
        AND NOT EXISTS (
          SELECT 1 FROM public.user_documents d
          WHERE d.user_id = NEW.user_id
            AND d.status = 'REJECTED'
        );
    ELSE
      UPDATE public.bodyguards b
      SET status = 'PENDING_APPROVAL'
      WHERE b.id = NEW.bodyguard_id
        AND b.user_id IS NULL
        AND b.status = 'REJECTED'
        AND NOT EXISTS (
          SELECT 1 FROM public.user_documents d
          WHERE d.bodyguard_id = NEW.bodyguard_id
            AND d.status = 'REJECTED'
        );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- 7. Only approved bodyguards are listed ------------------------------------------
-- Whether a bodyguard is visible to everyone: switched on, approved, and the
-- account behind it (their own, or their company's) is ACTIVE.
CREATE OR REPLACE FUNCTION public.is_bodyguard_listed(p_bodyguard_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.bodyguards b
    LEFT JOIN public.companies c ON c.id = b.company_id
    WHERE b.id = p_bodyguard_id
      AND b.is_active
      AND b.status = 'ACTIVE'
      AND public.is_account_active(COALESCE(b.user_id, c.user_id))
  );
$$;

-- 8. user_profiles: whole profile rows as JSON ------------------------------------
-- Same columns as before plus company / bodyguard (appended, so CREATE OR
-- REPLACE keeps existing readers working).
CREATE OR REPLACE VIEW public.user_profiles
WITH (security_invoker = true)
AS
SELECT
  u.id,
  u.email,
  u.name,
  u.phone_code,
  u.phone_number,
  u.role,
  u.status,
  u.rejection_reason,
  u.profile_image_url,
  u.gender,
  u.address,
  u.latitude,
  u.longitude,
  u.is_push_notification_enabled,
  u.metadata,
  u.created_at,
  u.updated_at,
  c.id AS company_id,
  c.company_name,
  c.business_email,
  c.company_type,
  c.company_phone_code,
  c.company_phone_number,
  b.id AS bodyguard_id,
  -- Same defaults users had for every role before the split, so readers
  -- that treat NULL differently (e.g. a fallback rating) behave as before.
  COALESCE(b.hourly_rate, 0.00) AS hourly_rate,
  COALESCE(b.rating, 0.0) AS rating,
  -- Both roles have years of experience (bodyguard / company in operation).
  COALESCE(b.experience_years, c.experience_years, 0) AS experience_years,
  b.bio,
  b.languages,
  b.certifications,
  -- Whole profile rows for typed models (admin panel); NULL when absent.
  CASE WHEN c.id IS NULL THEN NULL ELSE to_jsonb(c) END AS company,
  CASE WHEN b.id IS NULL THEN NULL ELSE to_jsonb(b) END AS bodyguard
FROM public.users u
LEFT JOIN public.companies c ON c.user_id = u.id
LEFT JOIN public.bodyguards b ON b.user_id = u.id;

NOTIFY pgrst, 'reload schema';
