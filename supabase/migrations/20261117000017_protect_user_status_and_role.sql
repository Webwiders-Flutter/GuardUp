-- ==============================================================================
-- MIGRATION: Stop users from changing their own status or role
--
-- The "Users can update own profile or admin can update any" RLS policy allows
-- a user to update ANY column of their own row. Without this guard a user
-- could approve themselves (status = 'ACTIVE') or make themselves an admin
-- (role = 'ADMIN') straight from the client.
--
-- Rules for direct client updates (role "authenticated" / "anon"):
--   * Admins: no restriction.
--   * role:   cannot be changed.
--   * status: the only allowed change is INCOMPLETE -> PENDING_APPROVAL
--             (the app submits the application after the registration fee).
--             Deleting goes through the delete_user() RPC.
--
-- SECURITY DEFINER functions (delete_user, triggers) run as the function owner,
-- not as "authenticated", so they are not affected. Neither are the service
-- role, the dashboard or migrations.
-- ==============================================================================

-- Deliberately NOT security definer: current_user must be the caller's role.
CREATE OR REPLACE FUNCTION public.guard_user_status_and_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF current_user NOT IN ('authenticated', 'anon') OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.role IS DISTINCT FROM OLD.role THEN
    RAISE EXCEPTION 'You cannot change your role'
      USING ERRCODE = '42501';
  END IF;

  IF NEW.status IS DISTINCT FROM OLD.status
     AND NOT (OLD.status = 'INCOMPLETE' AND NEW.status = 'PENDING_APPROVAL') THEN
    RAISE EXCEPTION 'You cannot change your status from % to %', OLD.status, NEW.status
      USING ERRCODE = '42501',
            HINT = 'To delete your account call the delete_user() RPC.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_guard_status_and_role ON public.users;
CREATE TRIGGER trg_users_guard_status_and_role
BEFORE UPDATE ON public.users
FOR EACH ROW
EXECUTE FUNCTION public.guard_user_status_and_role();
