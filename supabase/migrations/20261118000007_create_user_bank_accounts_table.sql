-- ==============================================================================
-- MIGRATION: Create public.user_bank_accounts table and RLS policies
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.user_bank_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  account_number TEXT NOT NULL,
  account_holder TEXT NOT NULL,
  bank_name TEXT NOT NULL,
  branch TEXT NOT NULL,
  ifsc_code TEXT NOT NULL,
  branch_address TEXT,
  is_primary BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast user account lookups
CREATE INDEX IF NOT EXISTS idx_user_bank_accounts_user_id
  ON public.user_bank_accounts(user_id);

-- Enable Row Level Security (RLS)
ALTER TABLE public.user_bank_accounts ENABLE ROW LEVEL SECURITY;

-- RLS Policies: users can manage their own bank accounts
DO $$ BEGIN
  CREATE POLICY "Users can manage their own bank accounts"
    ON public.user_bank_accounts
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Add to Realtime publication
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.user_bank_accounts;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

