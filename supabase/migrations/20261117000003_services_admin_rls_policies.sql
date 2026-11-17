-- ==============================================================================
-- MIGRATION: Row Level Security (RLS) Policies for public.services
-- 1. Anyone can view active services
-- 2. Administrators have full access (View All, Add/Insert, Edit/Update, Delete)
-- ==============================================================================

-- 1. Ensure is_admin() helper function is available
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

-- 2. Ensure RLS is enabled on public.services
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies to ensure idempotent and clean state
DROP POLICY IF EXISTS "Public read active services" ON public.services;
DROP POLICY IF EXISTS "Anyone can view active services or admin can view all" ON public.services;
DROP POLICY IF EXISTS "Admins have full access to services" ON public.services;
DROP POLICY IF EXISTS "Admins can insert services" ON public.services;
DROP POLICY IF EXISTS "Admins can update services" ON public.services;
DROP POLICY IF EXISTS "Admins can delete services" ON public.services;

-- 4. SELECT / VIEW: Anyone can view active services; Admins can view ALL services (including inactive)
CREATE POLICY "Anyone can view active services or admin can view all"
  ON public.services
  FOR SELECT
  USING (is_active = true OR public.is_admin());

-- 5. INSERT / ADD: Admins can insert new services
CREATE POLICY "Admins can insert services"
  ON public.services
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

-- 6. UPDATE / EDIT: Admins can update any service
CREATE POLICY "Admins can update services"
  ON public.services
  FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- 7. DELETE: Admins can delete any service
CREATE POLICY "Admins can delete services"
  ON public.services
  FOR DELETE
  TO authenticated
  USING (public.is_admin());
