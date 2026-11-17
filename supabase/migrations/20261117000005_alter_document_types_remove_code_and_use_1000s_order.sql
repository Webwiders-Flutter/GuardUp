-- ==============================================================================
-- MIGRATION: Update public.document_types Table
-- 1. Remove 'code' column and its unique constraints / indexes
-- 2. Update existing records so display_order increments in steps of 1000 (1000, 2000, 3000...)
-- 3. Trigger to maintain 1000s display_order difference for new records
-- 4. Update services display_order trigger to avoid overriding negative/0 sort orders
-- ==============================================================================

-- 1. Remove 'code' column and associated constraints / indexes from document_types
DO $$
BEGIN
  -- Drop constraint if exists
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_schema = 'public' 
      AND table_name = 'document_types' 
      AND constraint_name = 'document_types_code_key'
  ) THEN
    ALTER TABLE public.document_types DROP CONSTRAINT document_types_code_key;
  END IF;

  -- Drop index if exists
  IF EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE schemaname = 'public' 
      AND tablename = 'document_types' 
      AND indexname IN ('idx_doc_types_code', 'document_types_code_key')
  ) THEN
    DROP INDEX IF EXISTS public.idx_doc_types_code;
    DROP INDEX IF EXISTS public.document_types_code_key;
  END IF;

  -- Drop column if exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'document_types' 
      AND column_name = 'code'
  ) THEN
    ALTER TABLE public.document_types DROP COLUMN code;
  END IF;
END $$;

-- 2. Update existing data in document_types to have display_order in differences of 1000s per target_role
WITH ranked_document_types AS (
  SELECT id, (ROW_NUMBER() OVER (PARTITION BY target_role ORDER BY display_order ASC, created_at ASC) * 1000)::INT AS new_order
  FROM public.document_types
)
UPDATE public.document_types dt
SET display_order = ranked_document_types.new_order
FROM ranked_document_types
WHERE dt.id = ranked_document_types.id;

-- 3. Set default display_order to 0
ALTER TABLE public.document_types ALTER COLUMN display_order SET DEFAULT 0;

-- 4. Trigger to ensure any newly inserted document type maintains 1000s order if display_order is NULL
CREATE OR REPLACE FUNCTION public.set_document_types_display_order()
RETURNS TRIGGER AS $$
DECLARE
  min_order INT;
BEGIN
  IF NEW.display_order IS NULL THEN
    SELECT COALESCE(MIN(display_order), 0) INTO min_order 
    FROM public.document_types 
    WHERE target_role = NEW.target_role;
    NEW.display_order := min_order - 1000;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_document_types_display_order ON public.document_types;
CREATE TRIGGER trigger_set_document_types_display_order
  BEFORE INSERT ON public.document_types
  FOR EACH ROW
  EXECUTE FUNCTION public.set_document_types_display_order();

-- 5. Update set_services_display_order trigger to only set order when NULL (allowing negative/custom sort orders)
CREATE OR REPLACE FUNCTION public.set_services_display_order()
RETURNS TRIGGER AS $$
DECLARE
  min_order INT;
BEGIN
  IF NEW.display_order IS NULL THEN
    SELECT COALESCE(MIN(display_order), 0) INTO min_order FROM public.services;
    NEW.display_order := min_order - 1000;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
