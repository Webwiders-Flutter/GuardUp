-- ==============================================================================
-- Migration: Add company phone fields to public.users
-- Allows security companies to store their dedicated business phone number
-- without overwriting the account owner's personal authentication phone number.
-- ==============================================================================

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS company_phone_code TEXT DEFAULT '+91',
  ADD COLUMN IF NOT EXISTS company_phone_number TEXT;

-- Create index for lookup of company phone
CREATE INDEX IF NOT EXISTS idx_users_company_phone 
ON public.users (company_phone_code, company_phone_number) 
WHERE role = 'COMPANY' AND company_phone_number IS NOT NULL AND company_phone_number != '';

