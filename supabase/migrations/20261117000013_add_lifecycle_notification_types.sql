-- ==============================================================================
-- MIGRATION: Notification types for user lifecycle events
--
-- Kept in its own migration: a new enum value must be committed before it can
-- be used, and 20261117000014 uses these values.
-- ==============================================================================

ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'NEW_USER_REGISTRATION';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'ACCOUNT_BLOCKED';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'ACCOUNT_UNBLOCKED';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'ACCOUNT_DELETED';
