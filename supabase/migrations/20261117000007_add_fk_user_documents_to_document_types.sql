-- Migration: Add foreign key constraint from public.user_documents(document_type_id) to public.document_types(id)
--
-- Historically user_documents.document_type_id stored the document type CODE
-- (e.g. 'ID_PROOF'). The code column was dropped from document_types in
-- 20261117000005, so legacy codes are mapped to document_types.id by matching
-- the seeded name + target_role before the column is converted to UUID.

DO $$
DECLARE
  unresolved TEXT;
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'user_documents'
      AND column_name = 'document_type_id'
      AND data_type = 'text'
  ) THEN
    -- 1. Map legacy codes to document type ids (seeded name + role).
    WITH legacy(code, name, target_role) AS (
      VALUES
        ('ID_PROOF',              'ID Proof',              'GUARD'),
        ('POLICE_VERIFICATION',   'Police Verification',   'GUARD'),
        ('SECURITY_LICENSE',      'Security License',      'GUARD'),
        ('CERTIFICATIONS',        'Certifications',        'GUARD'),
        ('BUSINESS_REGISTRATION', 'Business Registration', 'COMPANY'),
        ('GOVERNMENT_ID',         'Government ID (Admin)', 'COMPANY'),
        ('COMPANY_LOGO',          'Company Logo',          'COMPANY'),
        ('ADDITIONAL_DOCUMENTS',  'Additional Documents',  'COMPANY')
    ),
    resolved AS (
      SELECT DISTINCT ON (l.code) l.code, dt.id
      FROM legacy l
      JOIN public.document_types dt
        ON lower(trim(dt.name)) = lower(l.name)
       AND dt.target_role::text = l.target_role
      ORDER BY l.code, dt.created_at
    )
    UPDATE public.user_documents ud
    SET document_type_id = r.id::text
    FROM resolved r
    WHERE ud.document_type_id = r.code;

    -- 2. Abort with a clear message if anything is still not a valid type id.
    SELECT string_agg(DISTINCT ud.document_type_id, ', ')
      INTO unresolved
    FROM public.user_documents ud
    WHERE ud.document_type_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
       OR NOT EXISTS (
         SELECT 1 FROM public.document_types dt
         WHERE dt.id::text = lower(ud.document_type_id)
       );

    IF unresolved IS NOT NULL THEN
      RAISE EXCEPTION
        'user_documents.document_type_id has values that do not match any document_types.id: %. Fix or remove these rows, then rerun.',
        unresolved;
    END IF;

    -- 3. Convert column to UUID.
    ALTER TABLE public.user_documents
      ALTER COLUMN document_type_id TYPE uuid USING document_type_id::uuid;
  END IF;

  -- 4. Add foreign key constraint if not present.
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'user_documents_document_type_id_fkey'
  ) THEN
    ALTER TABLE public.user_documents
      ADD CONSTRAINT user_documents_document_type_id_fkey
      FOREIGN KEY (document_type_id) REFERENCES public.document_types(id)
      ON DELETE CASCADE;
  END IF;
END $$;

-- 5. Index for efficient join lookups.
CREATE INDEX IF NOT EXISTS idx_user_documents_document_type_id
  ON public.user_documents(document_type_id);

-- 6. Make PostgREST pick up the new relationship.
NOTIFY pgrst, 'reload schema';
