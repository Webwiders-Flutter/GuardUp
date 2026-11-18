-- ==============================================================================
-- MIGRATION: Bring back 'REJECTED' in public.user_status
--
-- An admin can now reject an application (or one of its documents) with a
-- reason, instead of deleting the applicant. The user keeps their account and
-- gets a notification.
--
-- Kept in its own migration: a new enum value must be committed before it can
-- be used, and 20261118000001 uses it.
--
-- Statuses after this migration:
--   INCOMPLETE, PENDING_APPROVAL, REJECTED, ACTIVE, BLOCKED, DELETED
-- ==============================================================================

ALTER TYPE public.user_status ADD VALUE IF NOT EXISTS 'REJECTED' AFTER 'PENDING_APPROVAL';
