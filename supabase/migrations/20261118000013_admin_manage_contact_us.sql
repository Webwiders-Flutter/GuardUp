-- ==============================================================================
-- MIGRATION: Let admins fully manage contact_us + keep updated_at current
-- ==============================================================================
-- contact_us only had "public insert" and "owner read" policies, so the admin
-- panel's Help & Support screen could not list, change the status of, or
-- delete requests. Admins get full access (SELECT / INSERT / UPDATE / DELETE).

DO $$ BEGIN
  CREATE POLICY "Admins can manage all contact_us inquiries"
    ON public.contact_us
    FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Status changes from the admin panel should bump updated_at
-- (reuses the shared trigger function from the admin_settings migration).
DROP TRIGGER IF EXISTS set_contact_us_updated_at ON public.contact_us;
CREATE TRIGGER set_contact_us_updated_at
BEFORE UPDATE ON public.contact_us
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();
