-- ==============================================================================
-- MIGRATION: Create public.contact_us table and RLS policies
-- ==============================================================================

-- Create status enum for contact us inquiries
DO $$ BEGIN
  CREATE TYPE public.contact_us_status AS ENUM ('PENDING', 'IN_PROGRESS', 'RESOLVED', 'CLOSED');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.contact_us (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  role public.user_role NULL,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  message TEXT NOT NULL,
  status public.contact_us_status NOT NULL DEFAULT 'PENDING'::public.contact_us_status,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_contact_us_user_id ON public.contact_us(user_id);
CREATE INDEX IF NOT EXISTS idx_contact_us_status ON public.contact_us(status);

-- Enable Row Level Security (RLS)
ALTER TABLE public.contact_us ENABLE ROW LEVEL SECURITY;

-- Allow anyone (authenticated or anon) to submit inquiries
DO $$ BEGIN
  CREATE POLICY "Allow public insert to contact_us"
    ON public.contact_us
    FOR INSERT
    TO public
    WITH CHECK (true);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Allow users to view their own inquiries
DO $$ BEGIN
  CREATE POLICY "Users can view their own contact_us inquiries"
    ON public.contact_us
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Add to Realtime publication
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.contact_us;
EXCEPTION WHEN duplicate_object THEN null;
END $$;
