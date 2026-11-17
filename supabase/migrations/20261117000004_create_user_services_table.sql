-- ==============================================================================
-- MIGRATION: Create public.user_services Table & Drop services column from users
-- Normalizes the many-to-many relationship between users and services by id (UUID).
-- ==============================================================================

-- 1. Create junction table: user_services
CREATE TABLE IF NOT EXISTS public.user_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_service UNIQUE (user_id, service_id)
);

-- 2. Indexes for fast joins & lookups
CREATE INDEX IF NOT EXISTS idx_user_services_user_id ON public.user_services(user_id);
CREATE INDEX IF NOT EXISTS idx_user_services_service_id ON public.user_services(service_id);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.user_services ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
-- Anyone (customers, guards, public) can view services offered by users
DO $$ BEGIN
  CREATE POLICY "Allow public read user services"
    ON public.user_services
    FOR SELECT
    USING (true);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Bodyguards/Companies can insert their own services
DO $$ BEGIN
  CREATE POLICY "Users can insert their own services"
    ON public.user_services
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Bodyguards/Companies can delete their own services (e.g., when updating profile)
DO $$ BEGIN
  CREATE POLICY "Users can delete their own services"
    ON public.user_services
    FOR DELETE
    USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- 5. Realtime publication
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.user_services;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- 6. Clean up obsolete services text[] column from public.users
DO $$ BEGIN
  -- Drop GIN index if exists
  IF EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE schemaname = 'public' 
      AND tablename = 'users' 
      AND indexname = 'idx_users_services'
  ) THEN
    DROP INDEX public.idx_users_services;
  END IF;

  -- Drop services column if exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'users' 
      AND column_name = 'services'
  ) THEN
    ALTER TABLE public.users DROP COLUMN services;
  END IF;
END $$;

-- 7. Atomic RPC function to sync user services inside a single transaction
CREATE OR REPLACE FUNCTION public.set_user_services(
  p_user_id UUID,
  p_service_ids UUID[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Security check: Caller must be the user themselves or service_role
  IF auth.uid() IS NOT NULL AND auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Not authorized to modify services for this user';
  END IF;

  -- 1. Remove existing services
  DELETE FROM public.user_services WHERE user_id = p_user_id;

  -- 2. Insert new services atomically
  IF p_service_ids IS NOT NULL AND array_length(p_service_ids, 1) > 0 THEN
    INSERT INTO public.user_services (user_id, service_id)
    SELECT p_user_id, UNNEST(p_service_ids);
  END IF;
END;
$$;
