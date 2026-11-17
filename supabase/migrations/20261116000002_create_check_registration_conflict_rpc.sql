-- ==============================================================================
-- RPC: Check Registration Conflict (Email & Phone Uniqueness)
-- Security Definable to allow anonymous sign-up flow to verify uniqueness
-- without leaking other users' private profiles through table RLS.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.check_registration_conflict(
  p_email TEXT,
  p_phone_number TEXT DEFAULT NULL,
  p_phone_code TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_clean_email TEXT := LOWER(TRIM(p_email));
  v_clean_phone TEXT := TRIM(p_phone_number);
  v_clean_code TEXT := COALESCE(TRIM(p_phone_code), '+91');
  v_matched RECORD;
BEGIN
  -- 1. Check if an active (non-deleted) user has this email
  SELECT id, email, phone_number, phone_code, status 
  INTO v_matched
  FROM public.users
  WHERE LOWER(email) = v_clean_email
    AND status != 'DELETED'
  LIMIT 1;

  IF v_matched.id IS NOT NULL THEN
    RETURN jsonb_build_object(
      'has_conflict', true,
      'conflict_type', 'EMAIL',
      'message', 'This email is already in use by an active account. Please sign in or use a different email.'
    );
  END IF;

  -- 2. Check if an active (non-deleted) user has this phone number
  IF v_clean_phone IS NOT NULL AND v_clean_phone != '' THEN
    SELECT id, email, phone_number, phone_code, status 
    INTO v_matched
    FROM public.users
    WHERE phone_number = v_clean_phone
      AND (phone_code = v_clean_code OR v_clean_code IS NULL OR v_clean_code = '')
      AND status != 'DELETED'
    LIMIT 1;

    IF v_matched.id IS NOT NULL THEN
      RETURN jsonb_build_object(
        'has_conflict', true,
        'conflict_type', 'PHONE',
        'message', 'This phone number is already registered with an active account.'
      );
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'has_conflict', false,
    'message', null
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_registration_conflict(TEXT, TEXT, TEXT) TO anon, authenticated, service_role;

