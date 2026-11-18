-- ==============================================================================
-- MIGRATION: Rejection reasons cleared only on approval; approving a rejected
--            document also moves the user back to PENDING_APPROVAL
--
-- Follow-up to 20261118000002 (already deployed), which only handled
-- REJECTED -> PENDING and cleared the reasons on any status change.
--
-- 1. Rejection reasons (users + user_documents) are cleared ONLY on approval:
--      document -> APPROVED   clears user_documents.rejection_reason
--      user     -> ACTIVE     clears users.rejection_reason (approval)
--    Any other change (e.g. REJECTED -> PENDING) keeps the last reason.
--
-- 2. pending_user_on_document_resubmitted() (from 20261118000002) now also
--    reacts to REJECTED -> APPROVED. When a document moves REJECTED -> PENDING (re-submitted) or
--    REJECTED -> APPROVED, a REJECTED user is moved back to PENDING_APPROVAL
--    so the application is reviewed again. The user is only moved once NO
--    document is still REJECTED.
--
--    SECURITY DEFINER: runs as the function owner, so the status guard
--    (trg_users_guard_status_and_role) does not block the change even when the
--    document update came from the user. No notification is sent
--    (handle_user_lifecycle_events has no event for REJECTED -> PENDING_APPROVAL).
--    Same transaction as the document update: both happen or neither does.
-- ==============================================================================

-- 1a. Column comments ----------------------------------------------------------
COMMENT ON COLUMN public.users.rejection_reason IS
  'Why the admin rejected the profile. Cleared only when the profile is approved (status -> ACTIVE).';
COMMENT ON COLUMN public.user_documents.rejection_reason IS
  'Why the admin rejected this document. Cleared only when the document is approved.';

-- 1b. Document review rules: reason cleared only on APPROVED -------------------
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
  ELSIF NEW.status = 'APPROVED' THEN
    -- Approval is the only thing that clears the reason.
    NEW.rejection_reason := NULL;
  END IF;

  RETURN NEW;
END;
$$;

-- 1c. Profile review rules: reason cleared only on approval --------------------
CREATE OR REPLACE FUNCTION public.enforce_user_review_rules()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_open_docs int;
BEGIN
  -- Approval: PENDING_APPROVAL / REJECTED -> ACTIVE. Clears the reason.
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
  -- unless it comes from a rejected document.
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

  -- Any other change keeps the last rejection reason.
  RETURN NEW;
END;
$$;

-- 2. Document leaves REJECTED -> user back to PENDING_APPROVAL ----------------
CREATE OR REPLACE FUNCTION public.pending_user_on_document_resubmitted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.status = 'REJECTED' AND NEW.status IN ('PENDING', 'APPROVED') THEN
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
  END IF;

  RETURN NEW;
END;
$$;

-- trg_user_documents_pending_user (from 20261118000002) is unchanged.
