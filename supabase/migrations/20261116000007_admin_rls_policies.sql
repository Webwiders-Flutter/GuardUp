-- Migration: Add Admin RLS policies to public.users and public.user_documents

-- 1. Helper function to check if current authenticated user has ADMIN role
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'ADMIN'
  );
$$;

-- 2. Drop existing restrictive policies on public.users
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view their own profile or admin can view all" ON public.users;
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;

-- Allow users to view their own profile, or admins to view all users
CREATE POLICY "Users can view their own profile or admin can view all"
ON public.users
FOR SELECT
TO authenticated
USING (
  auth.uid() = id OR public.is_admin()
);

-- 3. Update policy on public.users
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile or admin can update any" ON public.users;
DROP POLICY IF EXISTS "Admins can update all users" ON public.users;

-- Allow users to update their own profile, or admins to update any user
CREATE POLICY "Users can update own profile or admin can update any"
ON public.users
FOR UPDATE
TO authenticated
USING (
  auth.uid() = id OR public.is_admin()
)
WITH CHECK (
  auth.uid() = id OR public.is_admin()
);

-- 4. Select policy on public.user_documents
DROP POLICY IF EXISTS "Users can view own documents" ON public.user_documents;
DROP POLICY IF EXISTS "Users can view own documents or admin can view all" ON public.user_documents;
DROP POLICY IF EXISTS "Admins can view all user documents" ON public.user_documents;

CREATE POLICY "Users can view own documents or admin can view all"
ON public.user_documents
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id OR public.is_admin()
);

-- 5. Update policy on public.user_documents
DROP POLICY IF EXISTS "Users can update own pending documents" ON public.user_documents;
DROP POLICY IF EXISTS "Users can update own pending or admin can update all" ON public.user_documents;
DROP POLICY IF EXISTS "Admins can update all user documents" ON public.user_documents;

CREATE POLICY "Users can update own pending or admin can update all"
ON public.user_documents
FOR UPDATE
TO authenticated
USING (
  (auth.uid() = user_id AND status = 'PENDING') OR public.is_admin()
)
WITH CHECK (
  (auth.uid() = user_id AND status = 'PENDING') OR public.is_admin()
);

