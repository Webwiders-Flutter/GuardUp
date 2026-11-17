-- ==============================================================================
-- MIGRATION: Update public.services Table
-- 1. Remove 'code' column and its unique constraints / indexes
-- 2. Update existing records so display_order increments in steps of 1000 (1000, 2000, 3000...)
-- 3. Automatically assign next 1000s order for new records
-- ==============================================================================

-- 1. Remove 'code' column and associated constraints / indexes
DO $$
BEGIN
  -- Drop constraint if exists
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_schema = 'public' 
      AND table_name = 'services' 
      AND constraint_name = 'services_code_key'
  ) THEN
    ALTER TABLE public.services DROP CONSTRAINT services_code_key;
  END IF;

  -- Drop index if exists
  IF EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE schemaname = 'public' 
      AND tablename = 'services' 
      AND indexname = 'idx_services_code'
  ) THEN
    DROP INDEX public.idx_services_code;
  END IF;

  -- Drop column if exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'services' 
      AND column_name = 'code'
  ) THEN
    ALTER TABLE public.services DROP COLUMN code;
  END IF;
END $$;

-- 2. Update existing data to have display_order in differences of 1000s
WITH ranked_services AS (
  SELECT id, (ROW_NUMBER() OVER (ORDER BY display_order ASC, created_at ASC) * 1000)::INT AS new_order
  FROM public.services
)
UPDATE public.services s
SET display_order = ranked_services.new_order
FROM ranked_services
WHERE s.id = ranked_services.id;

-- 3. Set default display_order to 0 so trigger assigns next 1000s order
ALTER TABLE public.services ALTER COLUMN display_order SET DEFAULT 0;

-- 4. Trigger to ensure any newly inserted service follows 1000s order
CREATE OR REPLACE FUNCTION public.set_services_display_order()
RETURNS TRIGGER AS $$
DECLARE
  max_order INT;
BEGIN
  -- If display_order is not provided (or 0), assign the next 1000 multiple
  IF NEW.display_order IS NULL OR NEW.display_order <= 0 THEN
    SELECT COALESCE(MAX(display_order), 0) INTO max_order FROM public.services;
    NEW.display_order := (FLOOR(max_order / 1000) + 1) * 1000;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_services_display_order ON public.services;
CREATE TRIGGER trigger_set_services_display_order
  BEFORE INSERT ON public.services
  FOR EACH ROW
  EXECUTE FUNCTION public.set_services_display_order();
