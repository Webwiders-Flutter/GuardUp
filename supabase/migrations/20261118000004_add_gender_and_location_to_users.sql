-- ==============================================================================
-- MIGRATION: Add gender enum (gender_type), address, latitude, and longitude to public.users
-- ==============================================================================

-- 1. Create gender_type enum safely
DO $$ BEGIN
  CREATE TYPE public.gender_type AS ENUM ('MALE', 'FEMALE', 'OTHER');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- 2. Add or convert gender column to public.gender_type
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'gender'
  ) THEN
    ALTER TABLE public.users
      ADD COLUMN gender public.gender_type DEFAULT 'MALE';
  ELSE
    ALTER TABLE public.users
      ALTER COLUMN gender TYPE public.gender_type USING gender::public.gender_type,
      ALTER COLUMN gender SET DEFAULT 'MALE';
  END IF;
END $$;

-- 3. Add address, latitude, longitude columns
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS address TEXT,
  ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

COMMENT ON TYPE public.gender_type IS
  'User gender options: MALE, FEMALE, OTHER';
COMMENT ON COLUMN public.users.gender IS
  'User gender enum: MALE, FEMALE, OTHER';
COMMENT ON COLUMN public.users.address IS
  'Physical or registered office address';
COMMENT ON COLUMN public.users.latitude IS
  'Latitude coordinate of the address';
COMMENT ON COLUMN public.users.longitude IS
  'Longitude coordinate of the address';

