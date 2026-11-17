-- Migration: Make documents bucket public and allow read access for document previews

-- 1. Set documents bucket to public so getPublicUrl works
UPDATE storage.buckets
SET public = true
WHERE id = 'documents';

-- 2. Drop existing restrictive read policy on documents
DROP POLICY IF EXISTS "Users can read own documents" ON storage.objects;
DROP POLICY IF EXISTS "Documents are readable" ON storage.objects;

-- 3. Create permissive read policy for documents and avatars
CREATE POLICY "Documents and avatars are readable"
ON storage.objects
FOR SELECT
USING (
  bucket_id IN ('documents', 'avatars')
);

