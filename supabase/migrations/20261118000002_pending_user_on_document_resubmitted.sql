-- ==============================================================================
-- MIGRATION: Rejected document back to PENDING -> user back to PENDING_APPROVAL
--
-- Counterpart of reject_user_on_document_rejected() (20261118000001, section 7).
-- When a document moves REJECTED -> PENDING (re-submitted), a REJECTED user is
-- moved back to PENDING_APPROVAL so the application is reviewed again.
--
-- The user is only moved once NO document is still REJECTED; otherwise a
-- single re-upload would hide the other rejected documents from review.
--
-- SECURITY DEFINER: runs as the function owner, so the status guard
-- (trg_users_guard_status_and_role) does not block the change even when the
-- document update came from the user. trg_users_review_rules clears
-- users.rejection_reason (status left REJECTED). No notification is sent
-- (handle_user_lifecycle_events has no event for REJECTED -> PENDING_APPROVAL).
-- Same transaction as the document update: both happen or neither does.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.pending_user_on_document_resubmitted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.status = 'REJECTED' AND NEW.status = 'PENDING' THEN
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

DROP TRIGGER IF EXISTS trg_user_documents_pending_user ON public.user_documents;
CREATE TRIGGER trg_user_documents_pending_user
AFTER UPDATE OF status ON public.user_documents
FOR EACH ROW
EXECUTE FUNCTION public.pending_user_on_document_resubmitted();
