-- ==============================================================================
-- MIGRATION: Service icons
-- 1. Add `icon_url` to public.services (public URL of the uploaded icon image)
-- 2. Create the public 'admin' storage bucket for admin-managed assets
--    (organised in folders, e.g. 'services/<timestamp>_<file>')
-- 3. Storage RLS: anyone can read, only admins can upload / replace / delete
-- ==============================================================================

-- 1. Icon URL column (nullable: existing services have no icon yet)
ALTER TABLE public.services
  ADD COLUMN IF NOT EXISTS icon_url TEXT;

COMMENT ON COLUMN public.services.icon_url IS
  'Public URL of the service icon image, stored in the admin bucket under services/.';

-- 2. 'admin' storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'admin',
  'admin',
  true,
  5242880, -- 5 MB
  ARRAY[
    'image/png',
    'image/jpeg',
    'image/jpg',
    'image/svg+xml',
    'image/gif',
    'image/webp',
    'image/avif'
  ]::text[]
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 3. Storage RLS policies for the 'admin' bucket
DROP POLICY IF EXISTS "Anyone can view admin bucket files" ON storage.objects;
CREATE POLICY "Anyone can view admin bucket files" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'admin');

DROP POLICY IF EXISTS "Admins can insert admin bucket files" ON storage.objects;
CREATE POLICY "Admins can insert admin bucket files" ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'admin' AND public.is_admin());

DROP POLICY IF EXISTS "Admins can update admin bucket files" ON storage.objects;
CREATE POLICY "Admins can update admin bucket files" ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'admin' AND public.is_admin())
  WITH CHECK (bucket_id = 'admin' AND public.is_admin());

DROP POLICY IF EXISTS "Admins can delete admin bucket files" ON storage.objects;
CREATE POLICY "Admins can delete admin bucket files" ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'admin' AND public.is_admin());
