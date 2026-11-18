-- ==============================================================================
-- MIGRATION: Add languages & certifications to public.users and create public.user_availabilities
-- ==============================================================================

-- 1. Add languages and certifications to public.users
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS languages TEXT,
  ADD COLUMN IF NOT EXISTS certifications TEXT;

COMMENT ON COLUMN public.users.languages IS
  'Spoken/communicative languages (e.g. English, French, Spanish)';
COMMENT ON COLUMN public.users.certifications IS
  'Professional security licenses and certifications (e.g. CPR, First Aid)';

-- 2. Create public.user_availabilities table
CREATE TABLE IF NOT EXISTS public.user_availabilities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  day_of_week TEXT NOT NULL,
  is_available BOOLEAN NOT NULL DEFAULT true,
  from_time TEXT NOT NULL DEFAULT '09:00 AM',
  to_time TEXT NOT NULL DEFAULT '05:00 PM',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_day_availability UNIQUE (user_id, day_of_week)
);

-- 3. Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_user_availabilities_user_id
  ON public.user_availabilities(user_id);

CREATE INDEX IF NOT EXISTS idx_user_availabilities_lookup
  ON public.user_availabilities(user_id, day_of_week, is_available);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.user_availabilities ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
DO $$ BEGIN
  CREATE POLICY "Allow public read user availabilities"
    ON public.user_availabilities
    FOR SELECT
    USING (true);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can manage their own availability"
    ON public.user_availabilities
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- 6. Add to Realtime publication
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.user_availabilities;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

