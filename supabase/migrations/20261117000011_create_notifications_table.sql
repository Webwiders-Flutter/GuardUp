-- ==============================================================================
-- MIGRATION: Create public.notifications
--
-- In-app notification inbox per user. Every INSERT is pushed to the user's
-- devices by the trigger in 20261117000012_notification_push_trigger.sql.
--
-- 1. users.is_push_notification_enabled preference flag
-- 2. notification_type enum (kept small for now, extend with ADD VALUE)
-- 3. Table + indexes
-- 4. updated_at / read_at triggers
-- 5. RLS: users see and manage their own, admins manage all
-- 6. Realtime publication for live in-app updates
-- ==============================================================================

-- 1. Push preference on users --------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS is_push_notification_enabled boolean NOT NULL DEFAULT true;

-- 2. Enum ----------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE public.notification_type AS ENUM (
    'ACCOUNT_APPROVED',
    'ACCOUNT_REJECTED',
    'SYSTEM'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- 3. Table ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  type public.notification_type NOT NULL DEFAULT 'SYSTEM'::public.notification_type,
  title text NOT NULL,
  body text NOT NULL,
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text NULL,
  is_read boolean NOT NULL DEFAULT false,
  read_at timestamp with time zone NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_notifications_user_created
  ON public.notifications USING btree (user_id, created_at DESC) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications USING btree (user_id) TABLESPACE pg_default
  WHERE is_read = false;

CREATE INDEX IF NOT EXISTS idx_notifications_type
  ON public.notifications USING btree (type) TABLESPACE pg_default;

-- 4. Triggers ------------------------------------------------------------------
DROP TRIGGER IF EXISTS set_notifications_updated_at ON public.notifications;
CREATE TRIGGER set_notifications_updated_at
BEFORE UPDATE ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();

-- Sets read_at when a notification is marked read, clears it when marked unread.
CREATE OR REPLACE FUNCTION public.handle_notification_read_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.is_read AND NOT COALESCE(OLD.is_read, false) AND NEW.read_at IS NULL THEN
    NEW.read_at := NOW();
  ELSIF NOT NEW.is_read THEN
    NEW.read_at := NULL;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_notification_read_at ON public.notifications;
CREATE TRIGGER set_notification_read_at
BEFORE UPDATE ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.handle_notification_read_at();

-- 5. Row Level Security --------------------------------------------------------
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users and admins can view notifications" ON public.notifications;
DROP POLICY IF EXISTS "Admins can insert notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users and admins can update notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users and admins can delete notifications" ON public.notifications;

CREATE POLICY "Users and admins can view notifications"
  ON public.notifications
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR public.is_admin());

-- Only admins (and service_role, which bypasses RLS) create notifications
-- directly; system events go through SECURITY DEFINER functions.
CREATE POLICY "Admins can insert notifications"
  ON public.notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

-- Users mark their own notifications read / unread.
CREATE POLICY "Users and admins can update notifications"
  ON public.notifications
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id OR public.is_admin())
  WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Users and admins can delete notifications"
  ON public.notifications
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id OR public.is_admin());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.notifications TO authenticated;
GRANT ALL ON TABLE public.notifications TO postgres, service_role;

-- 6. Realtime ------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
