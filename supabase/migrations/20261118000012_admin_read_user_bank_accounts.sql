-- ==============================================================================
-- MIGRATION: Let admins read every user's bank accounts
-- ==============================================================================
-- user_bank_accounts only had an owner policy (auth.uid() = user_id), so the
-- admin panel could not show a guard's / company's payout details. Admins get
-- read-only access; they never create or edit bank accounts.
-- user_availabilities already has a public read policy, so nothing is needed
-- there.

DO $$ BEGIN
  CREATE POLICY "Admins can read all bank accounts"
    ON public.user_bank_accounts
    FOR SELECT
    USING (public.is_admin());
EXCEPTION WHEN duplicate_object THEN null;
END $$;
