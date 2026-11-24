-- ==============================================================================
-- MIGRATION: Split role profiles out of public.users
--
-- Full write-up: documentation/user_profiles.md
--
-- Before: one public.users row held account data AND every role's profile
-- columns (bodyguard rate / bio, company name / type ...). A company could not
-- add bodyguards because a bodyguard had to be a login account.
--
-- After:
--   users       login account only: identity, contact, role, status, review.
--   companies   one row per COMPANY account     (companies.user_id -> users.id)
--   bodyguards  one row per bodyguard:
--                 self-registered  user_id = the GUARD account, company_id NULL
--                 company-managed  user_id NULL, company_id = the company
--
-- Child tables (user_services, user_availabilities, user_documents) now belong
-- to EXACTLY ONE owner (CHECK constraint):
--   user_id       rows of a login account (customer / guard / company), as before
--   bodyguard_id  rows of a company-managed bodyguard (no login)
-- So everything that already works for login accounts is unchanged.
--
-- Account status, approval and rejection stay on users. Company-managed
-- bodyguards have no account status: they are trusted through their company
-- (bodyguards.is_active switches them off). Their documents are stored for the
-- record; an admin may review them at any time (no account to approve).
--
-- Reading a profile in one query: public.user_profiles (view, security
-- invoker) = users + company columns + bodyguard columns, with the same column
-- names the apps used before. The legacy columns are removed from users in the
-- next migration (20261124000020).
--
-- Objects:
--   1. companies, bodyguards (+ updated_at triggers, indexes, realtime)
--   2. Backfill from users
--   3. Child tables: bodyguard_id owner column
--   4. RLS helpers
--   5. RLS policies
--   6. Triggers: bodyguard identity sync, protected columns
--   7. handle_new_user(): creates the role profile row on signup
--   8. handle_user_lifecycle_events(): company name from companies
--   9. enforce_user_document_review(): documents without an account
--  10. set_bodyguard_services() RPC
--  11. user_profiles view
--  12. Re-uploading a rejected document (own documents)
-- ==============================================================================

-- 1. Tables --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  company_name TEXT,
  business_email TEXT,
  company_type TEXT,
  company_phone_code TEXT DEFAULT '+91',
  company_phone_number TEXT,
  experience_years INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.companies IS
  'Company profile of a COMPANY account (one per account). Account data stays in users.';
COMMENT ON COLUMN public.companies.company_type IS
  'BusinessType API value: PROPRIETORSHIP, PARTNERSHIP, PVT_LTD, PUBLIC_LTD, LLP, INDIVIDUAL.';

CREATE TABLE IF NOT EXISTS public.bodyguards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '',
  profile_image_url TEXT,
  gender public.gender_type,
  phone_code TEXT DEFAULT '+91',
  phone_number TEXT,
  hourly_rate NUMERIC(10, 2) DEFAULT 0.00,
  rating NUMERIC(2, 1) DEFAULT 0.0,
  experience_years INTEGER DEFAULT 0,
  bio TEXT,
  languages TEXT,
  certifications TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT bodyguards_owner_check CHECK (user_id IS NOT NULL OR company_id IS NOT NULL)
);

COMMENT ON TABLE public.bodyguards IS
  'Bodyguard profile. user_id set = self-registered GUARD account; user_id NULL = managed by company_id (no login).';
COMMENT ON COLUMN public.bodyguards.name IS
  'For self-registered bodyguards name, profile_image_url and gender are copied from users (source of truth).';
COMMENT ON COLUMN public.bodyguards.phone_number IS
  'Contact phone of a company-managed bodyguard. Not copied for self-registered bodyguards (their phone stays private in users).';

CREATE INDEX IF NOT EXISTS idx_bodyguards_company_id ON public.bodyguards(company_id);
CREATE INDEX IF NOT EXISTS idx_bodyguards_active ON public.bodyguards(is_active);

DROP TRIGGER IF EXISTS set_companies_updated_at ON public.companies;
CREATE TRIGGER set_companies_updated_at
BEFORE UPDATE ON public.companies
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_bodyguards_updated_at ON public.bodyguards;
CREATE TRIGGER set_bodyguards_updated_at
BEFORE UPDATE ON public.bodyguards
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bodyguards ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.companies, public.bodyguards TO authenticated, service_role;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.companies;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.bodyguards;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- 6a. Bodyguard identity sync (defined before the backfill so it fills names) --
-- users is the source of truth for a self-registered bodyguard's name, photo
-- and gender: copied in on every insert / update of the bodyguard row, and
-- pushed out whenever they change on users (6b).
CREATE OR REPLACE FUNCTION public.sync_bodyguard_identity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user record;
BEGIN
  IF NEW.user_id IS NOT NULL THEN
    SELECT name, profile_image_url, gender INTO v_user
    FROM public.users
    WHERE id = NEW.user_id;

    IF FOUND THEN
      NEW.name := COALESCE(v_user.name, '');
      NEW.profile_image_url := v_user.profile_image_url;
      NEW.gender := v_user.gender;
    END IF;
  END IF;

  NEW.name := COALESCE(btrim(NEW.name), '');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_bodyguards_sync_identity ON public.bodyguards;
CREATE TRIGGER trg_bodyguards_sync_identity
BEFORE INSERT OR UPDATE ON public.bodyguards
FOR EACH ROW EXECUTE FUNCTION public.sync_bodyguard_identity();

-- 2. Backfill ------------------------------------------------------------------
-- Every COMPANY / GUARD row gets its profile row, whatever its status, so
-- history (e.g. DELETED accounts kept for records) stays complete.
INSERT INTO public.companies (
  user_id, company_name, business_email, company_type,
  company_phone_code, company_phone_number, experience_years, created_at, updated_at
)
SELECT
  u.id, u.company_name, u.business_email,
  -- Always the API value: the edit screen used to store the display label.
  CASE lower(btrim(u.company_type))
    WHEN 'proprietorship' THEN 'PROPRIETORSHIP'
    WHEN 'partnership' THEN 'PARTNERSHIP'
    WHEN 'private limited (pvt ltd)' THEN 'PVT_LTD'
    WHEN 'public limited' THEN 'PUBLIC_LTD'
    WHEN 'limited liability partnership (llp)' THEN 'LLP'
    WHEN 'individual' THEN 'INDIVIDUAL'
    ELSE NULLIF(btrim(u.company_type), '')
  END,
  COALESCE(u.company_phone_code, '+91'), u.company_phone_number, u.experience_years,
  u.created_at, u.updated_at
FROM public.users u
WHERE u.role = 'COMPANY'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO public.bodyguards (
  user_id, hourly_rate, rating, experience_years, bio, languages,
  certifications, created_at, updated_at
)
SELECT
  u.id, u.hourly_rate, u.rating, u.experience_years, u.bio, u.languages,
  u.certifications, u.created_at, u.updated_at
FROM public.users u
WHERE u.role = 'GUARD'
ON CONFLICT (user_id) DO NOTHING;

-- 3. Child tables: exactly one owner -------------------------------------------
-- Full UNIQUE constraints (not partial indexes) so PostgREST upserts can use
-- on_conflict=bodyguard_id,<column>. NULLs never collide, so rows owned by
-- user_id are unaffected.
ALTER TABLE public.user_services
  ADD COLUMN IF NOT EXISTS bodyguard_id UUID REFERENCES public.bodyguards(id) ON DELETE CASCADE,
  ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.user_availabilities
  ADD COLUMN IF NOT EXISTS bodyguard_id UUID REFERENCES public.bodyguards(id) ON DELETE CASCADE,
  ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.user_documents
  ADD COLUMN IF NOT EXISTS bodyguard_id UUID REFERENCES public.bodyguards(id) ON DELETE CASCADE,
  ALTER COLUMN user_id DROP NOT NULL;

DO $$ BEGIN
  ALTER TABLE public.user_services
    ADD CONSTRAINT user_services_owner_check CHECK (num_nonnulls(user_id, bodyguard_id) = 1),
    ADD CONSTRAINT unique_bodyguard_service UNIQUE (bodyguard_id, service_id);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE public.user_availabilities
    ADD CONSTRAINT user_availabilities_owner_check CHECK (num_nonnulls(user_id, bodyguard_id) = 1),
    ADD CONSTRAINT unique_bodyguard_day_availability UNIQUE (bodyguard_id, day_of_week);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE public.user_documents
    ADD CONSTRAINT user_documents_owner_check CHECK (num_nonnulls(user_id, bodyguard_id) = 1),
    ADD CONSTRAINT unique_bodyguard_document_type UNIQUE (bodyguard_id, document_type_id);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- 4. RLS helpers ---------------------------------------------------------------
-- SECURITY DEFINER so policies can look at other tables without recursing
-- into their RLS (users is only readable by its owner / admins).

-- The company of the signed-in COMPANY account, or NULL.
CREATE OR REPLACE FUNCTION public.my_company_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT c.id FROM public.companies c WHERE c.user_id = auth.uid();
$$;

-- Whether an account exists and is ACTIVE (approved, not blocked / deleted).
CREATE OR REPLACE FUNCTION public.is_account_active(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users u WHERE u.id = p_user_id AND u.status = 'ACTIVE'
  );
$$;

-- Whether the signed-in user is the company that manages this bodyguard.
-- Only company-managed bodyguards (no login) can be managed by a company.
CREATE OR REPLACE FUNCTION public.can_manage_bodyguard(p_bodyguard_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p_bodyguard_id IS NOT NULL AND EXISTS (
    SELECT 1
    FROM public.bodyguards b
    JOIN public.companies c ON c.id = b.company_id
    WHERE b.id = p_bodyguard_id
      AND b.user_id IS NULL
      AND c.user_id = auth.uid()
  );
$$;

-- Whether a bodyguard is visible to everyone: switched on, and the account
-- behind it (their own, or their company's) is ACTIVE.
CREATE OR REPLACE FUNCTION public.is_bodyguard_listed(p_bodyguard_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.bodyguards b
    LEFT JOIN public.companies c ON c.id = b.company_id
    WHERE b.id = p_bodyguard_id
      AND b.is_active
      AND public.is_account_active(COALESCE(b.user_id, c.user_id))
  );
$$;

REVOKE ALL ON FUNCTION public.my_company_id() FROM public, anon;
REVOKE ALL ON FUNCTION public.is_account_active(uuid) FROM public, anon;
REVOKE ALL ON FUNCTION public.can_manage_bodyguard(uuid) FROM public, anon;
REVOKE ALL ON FUNCTION public.is_bodyguard_listed(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.my_company_id() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_account_active(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.can_manage_bodyguard(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_bodyguard_listed(uuid) TO authenticated, service_role;

-- 5. RLS policies --------------------------------------------------------------
-- companies
DROP POLICY IF EXISTS "Companies are readable by owner, admins, or when active" ON public.companies;
CREATE POLICY "Companies are readable by owner, admins, or when active"
ON public.companies FOR SELECT TO authenticated
USING (user_id = auth.uid() OR public.is_admin() OR public.is_account_active(user_id));

-- Normally created by handle_new_user(); this lets the app repair a missing row.
DROP POLICY IF EXISTS "Company accounts can create their company" ON public.companies;
CREATE POLICY "Company accounts can create their company"
ON public.companies FOR INSERT TO authenticated
WITH CHECK (
  (user_id = auth.uid()
   AND EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.role = 'COMPANY'))
  OR public.is_admin()
);

DROP POLICY IF EXISTS "Owner or admin can update company" ON public.companies;
CREATE POLICY "Owner or admin can update company"
ON public.companies FOR UPDATE TO authenticated
USING (user_id = auth.uid() OR public.is_admin())
WITH CHECK (user_id = auth.uid() OR public.is_admin());

-- bodyguards
DROP POLICY IF EXISTS "Bodyguards are readable by owner, company, admins, or when listed" ON public.bodyguards;
CREATE POLICY "Bodyguards are readable by owner, company, admins, or when listed"
ON public.bodyguards FOR SELECT TO authenticated
USING (
  user_id = auth.uid()
  OR (company_id IS NOT NULL AND company_id = public.my_company_id())
  OR public.is_admin()
  OR public.is_bodyguard_listed(id)
);

-- Self-registered: normally created by handle_new_user(); this lets the app
-- repair a missing row. Company-managed: an ACTIVE company adds its bodyguards.
DROP POLICY IF EXISTS "Guards and active companies can create bodyguards" ON public.bodyguards;
CREATE POLICY "Guards and active companies can create bodyguards"
ON public.bodyguards FOR INSERT TO authenticated
WITH CHECK (
  (user_id = auth.uid()
   AND company_id IS NULL
   AND EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.role = 'GUARD'))
  OR (user_id IS NULL
      AND company_id IS NOT NULL
      AND company_id = public.my_company_id()
      AND public.is_account_active(auth.uid()))
  OR public.is_admin()
);

DROP POLICY IF EXISTS "Owner, managing company or admin can update bodyguard" ON public.bodyguards;
CREATE POLICY "Owner, managing company or admin can update bodyguard"
ON public.bodyguards FOR UPDATE TO authenticated
USING (user_id = auth.uid() OR public.can_manage_bodyguard(id) OR public.is_admin())
WITH CHECK (
  user_id = auth.uid()
  OR (user_id IS NULL AND company_id IS NOT NULL AND company_id = public.my_company_id())
  OR public.is_admin()
);

-- Self-registered bodyguards are removed with their account (delete_user).
DROP POLICY IF EXISTS "Managing company or admin can delete bodyguard" ON public.bodyguards;
CREATE POLICY "Managing company or admin can delete bodyguard"
ON public.bodyguards FOR DELETE TO authenticated
USING (public.can_manage_bodyguard(id) OR public.is_admin());

-- user_services (SELECT is already public)
DROP POLICY IF EXISTS "Companies can insert their bodyguards' services" ON public.user_services;
CREATE POLICY "Companies can insert their bodyguards' services"
ON public.user_services FOR INSERT TO authenticated
WITH CHECK (public.can_manage_bodyguard(bodyguard_id));

DROP POLICY IF EXISTS "Companies can delete their bodyguards' services" ON public.user_services;
CREATE POLICY "Companies can delete their bodyguards' services"
ON public.user_services FOR DELETE TO authenticated
USING (public.can_manage_bodyguard(bodyguard_id));

-- user_availabilities (SELECT is already public)
DROP POLICY IF EXISTS "Companies can manage their bodyguards' availability" ON public.user_availabilities;
CREATE POLICY "Companies can manage their bodyguards' availability"
ON public.user_availabilities FOR ALL TO authenticated
USING (public.can_manage_bodyguard(bodyguard_id))
WITH CHECK (public.can_manage_bodyguard(bodyguard_id));

-- user_documents: a company can re-upload any of its bodyguards' documents,
-- but every write by the company leaves the document PENDING.
DROP POLICY IF EXISTS "Companies can view their bodyguards' documents" ON public.user_documents;
CREATE POLICY "Companies can view their bodyguards' documents"
ON public.user_documents FOR SELECT TO authenticated
USING (public.can_manage_bodyguard(bodyguard_id));

DROP POLICY IF EXISTS "Companies can upload their bodyguards' documents" ON public.user_documents;
CREATE POLICY "Companies can upload their bodyguards' documents"
ON public.user_documents FOR INSERT TO authenticated
WITH CHECK (public.can_manage_bodyguard(bodyguard_id));

DROP POLICY IF EXISTS "Companies can update their bodyguards' documents" ON public.user_documents;
CREATE POLICY "Companies can update their bodyguards' documents"
ON public.user_documents FOR UPDATE TO authenticated
USING (public.can_manage_bodyguard(bodyguard_id))
WITH CHECK (public.can_manage_bodyguard(bodyguard_id) AND status = 'PENDING');

DROP POLICY IF EXISTS "Companies can delete their bodyguards' documents" ON public.user_documents;
CREATE POLICY "Companies can delete their bodyguards' documents"
ON public.user_documents FOR DELETE TO authenticated
USING (public.can_manage_bodyguard(bodyguard_id));

-- 6b. Push identity changes from users to the bodyguard row --------------------
CREATE OR REPLACE FUNCTION public.push_user_identity_to_bodyguard()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.name IS DISTINCT FROM OLD.name
     OR NEW.profile_image_url IS DISTINCT FROM OLD.profile_image_url
     OR NEW.gender IS DISTINCT FROM OLD.gender THEN
    -- trg_bodyguards_sync_identity copies the new values in.
    UPDATE public.bodyguards SET updated_at = NOW() WHERE user_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_push_identity_to_bodyguard ON public.users;
CREATE TRIGGER trg_users_push_identity_to_bodyguard
AFTER UPDATE OF name, profile_image_url, gender ON public.users
FOR EACH ROW EXECUTE FUNCTION public.push_user_identity_to_bodyguard();

-- 6c. Protected columns ----------------------------------------------------------
-- Same pattern as guard_user_status_and_role(): direct client writes cannot
-- move a profile to another owner or set their own rating. Admins, triggers
-- and SECURITY DEFINER functions are not affected.
-- Deliberately NOT security definer: current_user must be the caller's role.
CREATE OR REPLACE FUNCTION public.guard_profile_ownership()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF current_user NOT IN ('authenticated', 'anon') OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.user_id IS DISTINCT FROM OLD.user_id THEN
    RAISE EXCEPTION 'The owner of a profile cannot be changed' USING ERRCODE = '42501';
  END IF;

  IF TG_TABLE_NAME = 'bodyguards' THEN
    IF TG_OP = 'UPDATE' AND NEW.company_id IS DISTINCT FROM OLD.company_id THEN
      RAISE EXCEPTION 'The company of a bodyguard cannot be changed' USING ERRCODE = '42501';
    END IF;

    -- Ratings come from reviews, never from the profile owner.
    IF TG_OP = 'INSERT' THEN
      NEW.rating := 0.0;
    ELSIF NEW.rating IS DISTINCT FROM OLD.rating THEN
      RAISE EXCEPTION 'You cannot change the rating' USING ERRCODE = '42501';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_companies_guard_ownership ON public.companies;
CREATE TRIGGER trg_companies_guard_ownership
BEFORE UPDATE ON public.companies
FOR EACH ROW EXECUTE FUNCTION public.guard_profile_ownership();

DROP TRIGGER IF EXISTS trg_bodyguards_guard_ownership ON public.bodyguards;
CREATE TRIGGER trg_bodyguards_guard_ownership
BEFORE INSERT OR UPDATE ON public.bodyguards
FOR EACH ROW EXECUTE FUNCTION public.guard_profile_ownership();

-- 7. Signup creates the role profile ---------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  raw_role TEXT;
  assigned_role public.user_role;
  initial_status public.user_status;
BEGIN
  raw_role := UPPER(COALESCE(NEW.raw_user_meta_data->>'role', 'CUSTOMER'));

  IF raw_role = 'GUARD' THEN
    assigned_role := 'GUARD';
    initial_status := 'INCOMPLETE';
  ELSIF raw_role = 'COMPANY' THEN
    assigned_role := 'COMPANY';
    initial_status := 'INCOMPLETE';
  ELSE
    assigned_role := 'CUSTOMER';
    initial_status := 'ACTIVE';
  END IF;

  INSERT INTO public.users (
    id,
    email,
    name,
    phone_code,
    phone_number,
    role,
    status
  ) VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'phone_code', '+91'),
    NEW.raw_user_meta_data->>'phone',
    assigned_role,
    initial_status
  );

  IF assigned_role = 'GUARD' THEN
    INSERT INTO public.bodyguards (user_id) VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
  ELSIF assigned_role = 'COMPANY' THEN
    INSERT INTO public.companies (user_id) VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

-- 8. Lifecycle notifications: company name from companies ------------------------
-- Copy of 20261119000015; the only change is where the display name of a
-- company comes from (users.company_name moved to companies.company_name).
CREATE OR REPLACE FUNCTION public.handle_user_lifecycle_events()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_event text;
  v_name text;
  v_role_label text;
  v_data jsonb;
  v_title text;
  v_body text;
  v_tokens jsonb;
  v_rejected_docs text;
  v_is_self boolean := auth.uid() IS NOT NULL AND auth.uid() = NEW.id;
  -- Set by preserve_deleted_user_on_auth_delete(): the auth user is already
  -- being deleted, so it must not be deleted again from here.
  v_auth_already_deleting boolean :=
    COALESCE(current_setting('guardup.auth_deleting_user_id', true), '') = NEW.id::text;
  -- Never approved -> nothing worth keeping.
  v_hard_delete boolean :=
    NEW.status = 'DELETED' AND OLD.status IN ('INCOMPLETE', 'PENDING_APPROVAL', 'REJECTED');
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  -- ---------------------------------------------------------------------------
  -- A. Notifications & Emails (never block the status change)
  -- ---------------------------------------------------------------------------
  IF NEW.role <> 'ADMIN' THEN
    BEGIN
      v_event := CASE
        WHEN NEW.status = 'PENDING_APPROVAL' AND OLD.status = 'INCOMPLETE' THEN 'SUBMITTED'
        WHEN NEW.status = 'ACTIVE' AND OLD.status IN ('PENDING_APPROVAL', 'REJECTED') THEN 'APPROVED'
        WHEN NEW.status = 'ACTIVE' AND OLD.status = 'BLOCKED' THEN 'UNBLOCKED'
        WHEN NEW.status = 'REJECTED' THEN 'PROFILE_REJECTED'
        WHEN NEW.status = 'BLOCKED' THEN 'BLOCKED'
        -- Admin deletes an application that is still awaiting review.
        WHEN NEW.status = 'DELETED' AND OLD.status = 'PENDING_APPROVAL' AND NOT v_is_self THEN 'REJECTED'
        WHEN NEW.status = 'DELETED' THEN 'DELETED'
      END;

      IF v_event IS NOT NULL THEN
        SELECT NULLIF(btrim(c.company_name), '') INTO v_name
        FROM public.companies c
        WHERE c.user_id = NEW.id;
        v_name := COALESCE(v_name, NULLIF(btrim(NEW.name), ''), 'User');
        v_role_label := CASE NEW.role
          WHEN 'GUARD' THEN 'Bodyguard'
          WHEN 'COMPANY' THEN 'Company'
          ELSE 'Customer'
        END;
        v_data := jsonb_build_object('event', v_event, 'user_id', NEW.id, 'role', NEW.role::text);

        IF v_event = 'SUBMITTED' THEN
          -- Tell every admin there is a new application to review
          INSERT INTO public.notifications (user_id, type, title, body, data)
          SELECT
            a.id,
            'NEW_USER_REGISTRATION',
            'New registration: ' || v_name,
            v_name || ' (' || v_role_label || ') has submitted their profile and is awaiting review.',
            v_data || jsonb_build_object('applicant_name', v_name, 'email', NEW.email)
          FROM public.users a
          WHERE a.role = 'ADMIN'
            AND a.status <> 'DELETED';

        ELSIF v_event = 'PROFILE_REJECTED' THEN
          -- Status-based rejection: in-app notification & push.
          -- Profile reason wins; otherwise list the rejected documents.
          SELECT string_agg(COALESCE(dt.name, 'Document'), ', ' ORDER BY dt.display_order)
          INTO v_rejected_docs
          FROM public.user_documents d
          LEFT JOIN public.document_types dt ON dt.id = d.document_type_id
          WHERE d.user_id = NEW.id
            AND d.status = 'REJECTED';

          v_body := CASE
            WHEN NULLIF(btrim(NEW.rejection_reason), '') IS NOT NULL THEN
              'Your application was not approved. Reason: ' || btrim(NEW.rejection_reason)
            WHEN v_rejected_docs IS NOT NULL THEN
              'Some of your documents were rejected: ' || v_rejected_docs
                || '. Please check them in the app for details.'
            ELSE
              'Your application was not approved. Please contact support for details.'
          END;

          INSERT INTO public.notifications (user_id, type, title, body, data)
          VALUES (
            NEW.id,
            'ACCOUNT_REJECTED',
            'Application not approved',
            v_body,
            v_data || jsonb_build_object('rejection_reason', NEW.rejection_reason)
          );

        ELSE
          v_title := CASE v_event
            WHEN 'APPROVED' THEN 'Account approved'
            WHEN 'REJECTED' THEN 'Application not approved'
            WHEN 'BLOCKED' THEN 'Account suspended'
            WHEN 'UNBLOCKED' THEN 'Account restored'
            WHEN 'DELETED' THEN 'Account deleted'
          END;
          v_body := CASE v_event
            WHEN 'APPROVED' THEN 'Your profile has been verified. Welcome to GuardUp!'
            WHEN 'REJECTED' THEN 'Your application could not be approved. You are welcome to register again.'
            WHEN 'BLOCKED' THEN 'Your GuardUp account has been suspended. Please contact support.'
            WHEN 'UNBLOCKED' THEN 'Your GuardUp account is active again.'
            WHEN 'DELETED' THEN 'Your GuardUp account has been deleted.'
          END;

          IF v_hard_delete THEN
            -- The row (and its notifications / devices) is about to be removed,
            -- so an in-app row is pointless. Push straight to the device tokens,
            -- collected now, before the cascade deletes them. Self-deletes get
            -- no push: the user is in the app and just confirmed it.
            IF NOT v_is_self THEN
              SELECT jsonb_agg(d.token) INTO v_tokens
              FROM public.user_devices d
              WHERE d.user_id = NEW.id
                AND d.is_active;

              IF v_tokens IS NOT NULL AND jsonb_array_length(v_tokens) > 0 THEN
                PERFORM public.invoke_edge_function(
                  'send-notification',
                  jsonb_build_object(
                    'action', 'send_to_tokens',
                    'tokens', v_tokens,
                    'title', v_title,
                    'body', v_body,
                    'type', CASE v_event WHEN 'REJECTED' THEN 'ACCOUNT_REJECTED' ELSE 'ACCOUNT_DELETED' END,
                    'data', v_data,
                    'save_to_db', false
                  )
                );
              END IF;
            END IF;
          ELSE
            -- Row is kept: in-app notification; the notifications INSERT
            -- trigger sends the push.
            INSERT INTO public.notifications (user_id, type, title, body, data)
            VALUES (
              NEW.id,
              CASE v_event
                WHEN 'APPROVED' THEN 'ACCOUNT_APPROVED'
                WHEN 'REJECTED' THEN 'ACCOUNT_REJECTED'
                WHEN 'BLOCKED' THEN 'ACCOUNT_BLOCKED'
                WHEN 'UNBLOCKED' THEN 'ACCOUNT_UNBLOCKED'
                WHEN 'DELETED' THEN 'ACCOUNT_DELETED'
              END::public.notification_type,
              v_title,
              v_body,
              v_data
            );
          END IF;
        END IF;

        -- Emails (the address travels in the payload, so this also works
        -- after a hard delete).
        IF v_event IN ('APPROVED', 'REJECTED', 'DELETED', 'PROFILE_REJECTED')
           AND COALESCE(btrim(NEW.email), '') LIKE '%@%' THEN
          PERFORM public.invoke_edge_function(
            'user-lifecycle-events',
            jsonb_build_object(
              'event', CASE WHEN v_event = 'PROFILE_REJECTED' THEN 'REJECTED' ELSE v_event END,
              'user_id', NEW.id,
              'email', btrim(NEW.email),
              'name', v_name,
              'role', NEW.role::text,
              'rejection_reason', NEW.rejection_reason,
              'rejected_documents', v_rejected_docs
            )
          );
        END IF;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'User lifecycle notification failed for user % (% -> %): %',
        NEW.id, OLD.status, NEW.status, SQLERRM;
    END;
  END IF;

  -- ---------------------------------------------------------------------------
  -- B. Deletion (errors here DO abort the status change, so a user is never
  --    left half-deleted)
  -- ---------------------------------------------------------------------------
  IF NEW.status = 'DELETED' THEN
    -- Remove the login. Frees the email / phone in Supabase Auth.
    IF NOT v_auth_already_deleting THEN
      DELETE FROM auth.users WHERE id = NEW.id;
    END IF;

    -- Never approved: remove the row too. user_documents, user_services,
    -- user_devices and notifications go with it (ON DELETE CASCADE).
    IF v_hard_delete THEN
      PERFORM public.purge_user_storage(NEW.id);
      DELETE FROM public.users WHERE id = NEW.id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- 9. Document review for documents without an account ---------------------------
-- Copy of 20261118000003 except: documents of a company-managed bodyguard
-- (user_id NULL) have no application status to check, so they can be reviewed
-- at any time. The cascade triggers (reject_user_on_document_rejected,
-- pending_user_on_document_resubmitted) only touch users WHERE id = user_id,
-- so they already do nothing for these rows.
CREATE OR REPLACE FUNCTION public.enforce_user_document_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_status public.user_status;
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status
     AND NEW.rejection_reason IS NOT DISTINCT FROM OLD.rejection_reason THEN
    RETURN NEW;
  END IF;

  IF NEW.status IN ('APPROVED', 'REJECTED') AND NEW.user_id IS NOT NULL THEN
    SELECT status INTO v_user_status FROM public.users WHERE id = NEW.user_id;

    IF v_user_status NOT IN ('PENDING_APPROVAL', 'REJECTED') THEN
      RAISE EXCEPTION 'Documents can only be reviewed while the application is pending or rejected (current status: %)', v_user_status
        USING ERRCODE = '22023';
    END IF;
  END IF;

  IF NEW.status = 'REJECTED' THEN
    NEW.rejection_reason := NULLIF(btrim(NEW.rejection_reason), '');
    IF NEW.rejection_reason IS NULL THEN
      RAISE EXCEPTION 'A rejection reason is required' USING ERRCODE = '22023';
    END IF;
  ELSIF NEW.status = 'APPROVED' THEN
    -- Approval is the only thing that clears the reason.
    NEW.rejection_reason := NULL;
  END IF;

  RETURN NEW;
END;
$$;

-- 10. RPC: set_bodyguard_services ------------------------------------------------
-- Replaces the services of a company-managed bodyguard in one transaction.
-- Counterpart of set_user_services() (login accounts).
CREATE OR REPLACE FUNCTION public.set_bodyguard_services(
  p_bodyguard_id UUID,
  p_service_ids UUID[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- COALESCE: is_admin() can return NULL when the JWT has no role claim.
  IF auth.uid() IS NOT NULL
     AND NOT COALESCE(public.can_manage_bodyguard(p_bodyguard_id), false)
     AND NOT COALESCE(public.is_admin(), false) THEN
    RAISE EXCEPTION 'Not authorized to modify services for this bodyguard'
      USING ERRCODE = '42501';
  END IF;

  DELETE FROM public.user_services WHERE bodyguard_id = p_bodyguard_id;

  IF p_service_ids IS NOT NULL AND array_length(p_service_ids, 1) > 0 THEN
    INSERT INTO public.user_services (bodyguard_id, service_id)
    SELECT DISTINCT p_bodyguard_id, s
    FROM UNNEST(p_service_ids) AS s;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.set_bodyguard_services(UUID, UUID[]) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.set_bodyguard_services(UUID, UUID[]) TO authenticated, service_role;

-- 11. View: user_profiles --------------------------------------------------------
-- One row per account with its role profile flattened in, using the column
-- names the apps used before the split. security_invoker: the caller's RLS on
-- users / companies / bodyguards applies (own row, or everything for admins).
-- Read-only: writes go to users / companies / bodyguards.
CREATE OR REPLACE VIEW public.user_profiles
WITH (security_invoker = true)
AS
SELECT
  u.id,
  u.email,
  u.name,
  u.phone_code,
  u.phone_number,
  u.role,
  u.status,
  u.rejection_reason,
  u.profile_image_url,
  u.gender,
  u.address,
  u.latitude,
  u.longitude,
  u.is_push_notification_enabled,
  u.metadata,
  u.created_at,
  u.updated_at,
  c.id AS company_id,
  c.company_name,
  c.business_email,
  c.company_type,
  c.company_phone_code,
  c.company_phone_number,
  b.id AS bodyguard_id,
  -- Same defaults users had for every role before the split, so readers
  -- that treat NULL differently (e.g. a fallback rating) behave as before.
  COALESCE(b.hourly_rate, 0.00) AS hourly_rate,
  COALESCE(b.rating, 0.0) AS rating,
  -- Both roles have years of experience (bodyguard / company in operation).
  COALESCE(b.experience_years, c.experience_years, 0) AS experience_years,
  b.bio,
  b.languages,
  b.certifications
FROM public.users u
LEFT JOIN public.companies c ON c.user_id = u.id
LEFT JOIN public.bodyguards b ON b.user_id = u.id;

COMMENT ON VIEW public.user_profiles IS
  'Read-only: users + companies + bodyguards (self-registered) flattened per account. Write to the base tables.';

REVOKE ALL ON public.user_profiles FROM public, anon;
GRANT SELECT ON public.user_profiles TO authenticated, service_role;

-- 12. Re-uploading a rejected document ------------------------------------------
-- The old UPDATE policy only matched the owner's PENDING documents, so the app
-- re-uploading a REJECTED document updated 0 rows (silently) and
-- pending_user_on_document_resubmitted() never ran. Now the owner may update a
-- PENDING or REJECTED document; the row must end PENDING.
DROP POLICY IF EXISTS "Users can update own pending or admin can update all" ON public.user_documents;
DROP POLICY IF EXISTS "Users can update own pending or rejected, admin can update all" ON public.user_documents;
CREATE POLICY "Users can update own pending or rejected, admin can update all"
ON public.user_documents FOR UPDATE TO authenticated
USING (
  (auth.uid() = user_id AND status IN ('PENDING', 'REJECTED'))
  OR public.is_admin()
)
WITH CHECK (
  (auth.uid() = user_id AND status = 'PENDING')
  OR public.is_admin()
);

-- Client writes (owner or company) can never review a document: an insert is
-- always PENDING with no reason (unchanged), an update always ends PENDING and
-- keeps the admin's last rejection reason (cleared only on approval).
-- Deliberately NOT security definer: current_user must be the caller's role.
CREATE OR REPLACE FUNCTION public.guard_user_document_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF current_user NOT IN ('authenticated', 'anon') OR COALESCE(public.is_admin(), false) THEN
    RETURN NEW;
  END IF;

  NEW.status := 'PENDING';
  IF TG_OP = 'INSERT' THEN
    NEW.rejection_reason := NULL;
  ELSE
    NEW.rejection_reason := OLD.rejection_reason;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_documents_guard_review ON public.user_documents;
CREATE TRIGGER trg_user_documents_guard_review
BEFORE INSERT OR UPDATE ON public.user_documents
FOR EACH ROW
EXECUTE FUNCTION public.guard_user_document_review();

NOTIFY pgrst, 'reload schema';
