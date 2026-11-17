-- ==============================================================================
-- Migration: Handle unconfirmed signups in check_registration_conflict
-- If an existing account with this email/phone was never verified (email_confirmed_at IS NULL),
-- clean up the unconfirmed record so the user can re-register or complete signup without conflict.
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
  -- 1. Check if a user with this email exists
  SELECT u.id, u.email, u.phone_number, u.phone_code, u.status, a.email_confirmed_at 
  INTO v_matched
  FROM public.users u
  LEFT JOIN auth.users a ON a.id = u.id
  WHERE LOWER(u.email) = v_clean_email
    AND u.status != 'DELETED'
  LIMIT 1;

  IF v_matched.id IS NOT NULL THEN
    -- If the account was never verified (email unconfirmed), clean up incomplete record
    -- so the user can register freshly
    IF v_matched.email_confirmed_at IS NULL THEN
      DELETE FROM auth.users WHERE id = v_matched.id;
      DELETE FROM public.users WHERE id = v_matched.id;
    ELSE
      RETURN jsonb_build_object(
        'has_conflict', true,
        'conflict_type', 'EMAIL',
        'message', 'This email is already in use by an active account. Please sign in or use a different email.'
      );
    END IF;
  END IF;

  -- 2. Check if an active (non-deleted) user has this phone number
  IF v_clean_phone IS NOT NULL AND v_clean_phone != '' THEN
    SELECT u.id, u.email, u.phone_number, u.phone_code, u.status, a.email_confirmed_at 
    INTO v_matched
    FROM public.users u
    LEFT JOIN auth.users a ON a.id = u.id
    WHERE u.phone_number = v_clean_phone
      AND (u.phone_code = v_clean_code OR v_clean_code IS NULL OR v_clean_code = '')
      AND u.status != 'DELETED'
    LIMIT 1;

    IF v_matched.id IS NOT NULL THEN
      IF v_matched.email_confirmed_at IS NULL THEN
        DELETE FROM auth.users WHERE id = v_matched.id;
        DELETE FROM public.users WHERE id = v_matched.id;
      ELSE
        RETURN jsonb_build_object(
          'has_conflict', true,
          'conflict_type', 'PHONE',
          'message', 'This phone number is already registered with an active account.'
        );
      END IF;
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'has_conflict', false,
    'message', null
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_registration_conflict(TEXT, TEXT, TEXT) TO anon, authenticated, service_role;

