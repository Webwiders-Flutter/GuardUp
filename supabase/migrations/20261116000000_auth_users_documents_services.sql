-- ==============================================================================
-- GUARDUP PRODUCTION MIGRATION
-- Authentication, Unified Users, Dynamic Services, Document Management
-- ==============================================================================

-- 1. ENUMS
DO $$ BEGIN
  CREATE TYPE public.user_role AS ENUM ('CUSTOMER', 'GUARD', 'COMPANY');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE public.user_status AS ENUM (
    'INCOMPLETE',        -- Just signed up, onboarding pending
    'PENDING_APPROVAL',  -- Uploaded documents, waiting for admin approval
    'ACTIVE',            -- Active customer or approved bodyguard/company
    'REJECTED',          -- Verification rejected
    'BLOCKED',           -- Suspended by administrator
    'DELETED'            -- Soft deleted
  );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE public.document_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- ==============================================================================
-- 2. UNIFIED USERS TABLE (Single Table Architecture)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY,
  
  -- Common Fields
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  phone_code TEXT DEFAULT '+91',
  phone_number TEXT,
  role public.user_role NOT NULL DEFAULT 'CUSTOMER',
  status public.user_status NOT NULL DEFAULT 'INCOMPLETE',
  profile_image_url TEXT,

  -- Bodyguard Specific Fields (NULL for customer & company)
  hourly_rate NUMERIC(10, 2) DEFAULT 0.00,
  bio TEXT,
  services TEXT[] DEFAULT ARRAY[]::TEXT[],
  rating NUMERIC(2, 1) DEFAULT 0.0,

  -- Company Specific Fields (NULL for customer & guard)
  company_name TEXT,
  business_email TEXT,
  company_type TEXT,

  -- Flexible JSONB for custom configurations
  metadata JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_status ON public.users(status);
CREATE INDEX IF NOT EXISTS idx_users_services ON public.users USING GIN(services);

-- Unique index on email only for non-deleted (active) users
-- If an account is deleted, the email is immediately freed for new registrations
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_active_email ON public.users(LOWER(email)) WHERE status != 'DELETED';

-- Unique index on phone only for non-deleted (active) users
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_active_phone ON public.users(phone_code, phone_number) WHERE status != 'DELETED' AND phone_number IS NOT NULL AND phone_number != '';

-- ==============================================================================
-- 3. MASTER SERVICES TABLE (Managed from Admin Website)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  icon_name TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 4. MASTER DOCUMENT TYPES TABLE (Managed from Admin Website)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.document_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  target_role public.user_role NOT NULL,
  is_required BOOLEAN NOT NULL DEFAULT true,
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 5. USER SUBMITTED DOCUMENTS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.user_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  document_type_id TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_name TEXT,
  status public.document_status NOT NULL DEFAULT 'PENDING',
  rejection_reason TEXT,
  valid_till DATE,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_document_type UNIQUE (user_id, document_type_id)
);

CREATE INDEX IF NOT EXISTS idx_services_active ON public.services(is_active, display_order);
CREATE INDEX IF NOT EXISTS idx_doc_types_role ON public.document_types(target_role, is_active, display_order);
CREATE INDEX IF NOT EXISTS idx_user_documents_user ON public.user_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_user_documents_status ON public.user_documents(status);

-- ==============================================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES & REALTIME
-- ==============================================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_documents ENABLE ROW LEVEL SECURITY;

-- Enable Realtime Replication for users table
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Public read active services" ON public.services FOR SELECT USING (is_active = true);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Public read active document types" ON public.document_types FOR SELECT USING (is_active = true);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can view their own profile" ON public.users FOR SELECT USING (auth.uid() = id);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can update their own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can view own documents" ON public.user_documents FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can upload own documents" ON public.user_documents FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can update own pending documents" ON public.user_documents FOR UPDATE USING (auth.uid() = user_id AND status = 'PENDING');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- ==============================================================================
-- 7. STORAGE BUCKETS
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public) VALUES ('documents', 'documents', false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT (id) DO NOTHING;

-- Storage RLS
DO $$ BEGIN
  CREATE POLICY "Users can upload own documents" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'documents' AND (storage.foldername(name))[1] = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can read own documents" ON storage.objects FOR SELECT
  USING (bucket_id = 'documents' AND (storage.foldername(name))[1] = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Avatars are public" ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can upload own avatar" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- ==============================================================================
-- 8. TRIGGER: AUTO-CREATE USERS ON AUTH SIGNUP
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
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

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger: When a user status is updated to DELETED in public.users,
-- delete the user from auth.users to immediately free up email and phone for reuse.
CREATE OR REPLACE FUNCTION public.handle_user_status_deleted()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'DELETED' AND (OLD.status IS DISTINCT FROM 'DELETED') THEN
    DELETE FROM auth.users WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_user_status_deleted ON public.users;
CREATE TRIGGER on_user_status_deleted
  AFTER UPDATE OF status ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_status_deleted();

-- Trigger: When a user is deleted from auth.users, preserve their public.users record
-- with status = 'DELETED' so their history and documents are retained.
CREATE OR REPLACE FUNCTION public.preserve_deleted_user_on_auth_delete()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.users
  SET status = 'DELETED',
      updated_at = NOW()
  WHERE id = OLD.id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_deleted ON auth.users;
CREATE TRIGGER on_auth_user_deleted
  BEFORE DELETE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.preserve_deleted_user_on_auth_delete();

-- ==============================================================================
-- 9. INITIAL SEED DATA
-- ==============================================================================
INSERT INTO public.services (code, name, description, display_order) VALUES
  ('VIP_CLOSE_PROTECTION', 'VIP Close Protection', 'Dedicated personal bodyguards for high-profile clients', 1),
  ('ARMED_ESCORT', 'Armed Escort', 'High-threat transit and armed convoy security', 2),
  ('TACTICAL_DRIVER', 'Tactical Driver', 'Evasive security driving and executive transport', 3),
  ('EVENT_SECURITY', 'Event Security', 'Crowd control, perimeter security, and venue access', 4),
  ('RESIDENTIAL_PROTECTION', 'Residential Protection', 'Estate and private property static guarding', 5),
  ('ASSET_PROTECTION', 'Asset Protection', 'Valuables and high-value cargo transport protection', 6),
  ('SURVEILLANCE_RECON', 'Surveillance Recon', 'Counter-surveillance and route threat assessment', 7),
  ('CRISIS_MANAGEMENT', 'Crisis Management', 'Emergency extraction and crisis response', 8)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.document_types (code, name, description, target_role, is_required, display_order) VALUES
  ('ID_PROOF', 'ID Proof', 'Aadhaar / Passport / SSN', 'GUARD', true, 1),
  ('POLICE_VERIFICATION', 'Police Verification', 'Clearance Certificate', 'GUARD', true, 2),
  ('SECURITY_LICENSE', 'Security License', 'Armed / Unarmed Guard ID', 'GUARD', true, 3),
  ('CERTIFICATIONS', 'Certifications', 'First Aid / Tactical Defense', 'GUARD', false, 4),
  ('BUSINESS_REGISTRATION', 'Business Registration', 'Official corporate incorporation certificate', 'COMPANY', true, 1),
  ('GOVERNMENT_ID', 'Government ID (Admin)', 'Director or legal representative identification', 'COMPANY', true, 2),
  ('COMPANY_LOGO', 'Company Logo', 'High-resolution emblem or branding', 'COMPANY', true, 3),
  ('ADDITIONAL_DOCUMENTS', 'Additional Documents', 'Insurance policy or operating permits', 'COMPANY', false, 4)
ON CONFLICT (code) DO NOTHING;

