-- ==============================================================================
-- MIGRATION: Row Level Security (RLS) Policies for public.document_types
-- 1. Anyone can view active document types
-- 2. Administrators have FULL access for ALL operations (SELECT, INSERT, UPDATE, DELETE)
-- ==============================================================================

-- 1. Helper function to check if current caller has ADMIN privileges
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT 
    -- 1. Service role (Supabase service key)
    (auth.jwt() ->> 'role' = 'service_role')
    OR
    -- 2. Authenticated user with ADMIN role in public.users
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (role = 'ADMIN' OR role::text = 'ADMIN')
    );
$$;

-- 2. Ensure RLS is enabled on public.document_types
ALTER TABLE public.document_types ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies to ensure idempotent and clean state
DROP POLICY IF EXISTS "Public read active document types" ON public.document_types;
DROP POLICY IF EXISTS "Anyone can view active document types" ON public.document_types;
DROP POLICY IF EXISTS "Anyone can view active document types or admin can view all" ON public.document_types;
DROP POLICY IF EXISTS "Admins have full access to document types" ON public.document_types;
DROP POLICY IF EXISTS "Admins can insert document types" ON public.document_types;
DROP POLICY IF EXISTS "Admins can update document types" ON public.document_types;
DROP POLICY IF EXISTS "Admins can delete document types" ON public.document_types;

-- 4. SELECT / READ: Anyone (anon & authenticated) can view active document types
CREATE POLICY "Anyone can view active document types"
  ON public.document_types
  FOR SELECT
  USING (is_active = true);

-- 5. ALL OPERATIONS: Admins can do all things (SELECT all including inactive, INSERT, UPDATE, DELETE)
CREATE POLICY "Admins have full access to document types"
  ON public.document_types
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());
