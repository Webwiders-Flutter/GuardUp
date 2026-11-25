-- Migration: Add qualifications to public.bodyguards
-- Stores educational, tactical, or security qualifications of the operative.

ALTER TABLE public.bodyguards
ADD COLUMN IF NOT EXISTS qualifications TEXT;

COMMENT ON COLUMN public.bodyguards.qualifications IS
  'Educational, tactical, or security qualifications of the bodyguard operative.';
