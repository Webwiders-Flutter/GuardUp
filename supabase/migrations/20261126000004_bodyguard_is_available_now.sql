-- ==============================================================================
-- MIGRATION: Add is_available_now computed field & fix listing_availabilities
--
-- Full write-up: documentation/user_profiles.md ("Listings and filters")
--
-- Why:
--   1. Bodyguard listings filtered by availability should only return guards who
--      are available RIGHT NOW (their scheduled slot for today covers the current time).
--      Filtering only on day_of_week and is_available=true at the day level returned
--      guards whose working hours (e.g. 09:00 AM - 08:00 PM) had already ended.
--   2. A computed field `is_available_now(public.bodyguards)` allows PostgREST to
--      filter `is_available_now=eq.true` cleanly on the server, guaranteeing that
--      pagination and exact count match the operational availability status.
--   3. Ensure listing_availabilities runs as SECURITY DEFINER so that child availability
--      slots are accessible without RLS drops.
-- ==============================================================================

-- 1. Helper function: check if a time slot covers a time -----------------------
CREATE OR REPLACE FUNCTION public.slot_covers_time(
  p_is_available boolean,
  p_from_time text,
  p_to_time text,
  p_time time
)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_from time;
  v_to time;
BEGIN
  IF NOT COALESCE(p_is_available, false) THEN
    RETURN false;
  END IF;

  BEGIN
    v_from := to_timestamp(trim(p_from_time), 'HH12:MI AM')::time;
    v_to := to_timestamp(trim(p_to_time), 'HH12:MI AM')::time;
  EXCEPTION WHEN OTHERS THEN
    RETURN true;
  END;

  IF v_from <= v_to THEN
    RETURN p_time >= v_from AND p_time <= v_to;
  ELSE
    -- Overnight shift spanning midnight
    RETURN p_time >= v_from OR p_time <= v_to;
  END IF;
END;
$$;

-- 2. Computed field on bodyguards: is_available_now ---------------------------
CREATE OR REPLACE FUNCTION public.is_available_now(public.bodyguards)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_day text;
  v_now_time time;
  v_is_open boolean;
BEGIN
  -- Default to Asia/Kolkata (IST) since GuardUp operatives are configured in IST.
  v_day := lower(trim(to_char(CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata', 'Day')));
  v_now_time := (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::time;

  SELECT public.slot_covers_time(ua.is_available, ua.from_time, ua.to_time, v_now_time)
  INTO v_is_open
  FROM public.user_availabilities ua
  WHERE (ua.bodyguard_id = $1.id OR ($1.user_id IS NOT NULL AND ua.user_id = $1.user_id))
    AND lower(trim(ua.day_of_week)) = v_day
  LIMIT 1;

  RETURN COALESCE(v_is_open, false);
END;
$$;

COMMENT ON FUNCTION public.is_available_now (public.bodyguards) IS 'Computed field: whether the bodyguard is active and within an open availability slot right now.';

-- 3. Ensure listing_availabilities is SECURITY DEFINER -------------------------
CREATE OR REPLACE FUNCTION public.listing_availabilities(public.bodyguards)
RETURNS SETOF public.user_availabilities
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT ua.*
  FROM public.user_availabilities ua
  WHERE ua.bodyguard_id = $1.id
     OR ($1.user_id IS NOT NULL AND ua.user_id = $1.user_id);
$$;

COMMENT ON FUNCTION public.listing_availabilities (public.bodyguards) IS 'Computed relationship: weekly availability of a bodyguard. Runs as SECURITY DEFINER.';

-- 4. Grants -------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.slot_covers_time (boolean, text, text, time)
FROM public, anon;

REVOKE ALL ON FUNCTION public.is_available_now (public.bodyguards)
FROM public, anon;

REVOKE ALL ON FUNCTION public.listing_availabilities (public.bodyguards)
FROM public, anon;

GRANT
EXECUTE ON FUNCTION public.slot_covers_time (boolean, text, text, time) TO authenticated,
service_role;

GRANT
EXECUTE ON FUNCTION public.is_available_now (public.bodyguards) TO authenticated,
service_role;

GRANT
EXECUTE ON FUNCTION public.listing_availabilities (public.bodyguards) TO authenticated,
service_role;

-- 5. Notify PostgREST to reload schema -----------------------------------------
NOTIFY pgrst, 'reload schema';