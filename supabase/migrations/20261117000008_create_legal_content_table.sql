-- ==============================================================================
-- MIGRATION: Create public.legal_content
--
-- Stores admin-managed legal / informational HTML pages, scoped per
-- (role, content_type, language).
--
-- 1. Enums: language_code, legal_content_type
-- 2. Table + unique scope constraint + indexes
-- 3. updated_at trigger
-- 4. RLS: anyone can read, admins can insert / update / delete
-- ==============================================================================

-- 1. Enums ---------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE public.language_code AS ENUM ('en');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.legal_content_type AS ENUM (
    'TERMS',
    'ABOUT_US',
    'PRIVACY_POLICY',
    'DELETE_ACCOUNT',
    'SUPPORT'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- 2. Table ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.legal_content (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  role public.user_role NOT NULL,
  language public.language_code NOT NULL DEFAULT 'en'::public.language_code,
  content_type public.legal_content_type NOT NULL,
  content_html text NOT NULL DEFAULT ''::text,
  last_published_at timestamp with time zone NULL DEFAULT now(),
  created_at timestamp with time zone NULL DEFAULT now(),
  updated_at timestamp with time zone NULL DEFAULT now(),
  CONSTRAINT legal_content_pkey PRIMARY KEY (id),
  CONSTRAINT unique_legal_content_scope UNIQUE (role, content_type, language)
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_legal_content_role
  ON public.legal_content USING btree (role) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_legal_content_content_type
  ON public.legal_content USING btree (content_type) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_legal_content_published_at
  ON public.legal_content USING btree (last_published_at) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_legal_content_language
  ON public.legal_content USING btree (language) TABLESPACE pg_default;

-- 3. updated_at trigger --------------------------------------------------------
-- Bumps updated_at on every write, and last_published_at whenever the HTML changes.
CREATE OR REPLACE FUNCTION public.handle_legal_content_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  IF NEW.content_html IS DISTINCT FROM OLD.content_html THEN
    NEW.last_published_at = NOW();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_legal_content_updated_at ON public.legal_content;
CREATE TRIGGER set_legal_content_updated_at
BEFORE UPDATE ON public.legal_content
FOR EACH ROW
EXECUTE FUNCTION public.handle_legal_content_updated_at();

-- 4. Row Level Security --------------------------------------------------------
ALTER TABLE public.legal_content ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view legal content" ON public.legal_content;
DROP POLICY IF EXISTS "Admins can insert legal content" ON public.legal_content;
DROP POLICY IF EXISTS "Admins can update legal content" ON public.legal_content;
DROP POLICY IF EXISTS "Admins can delete legal content" ON public.legal_content;
DROP POLICY IF EXISTS "Admins have full access to legal content" ON public.legal_content;

-- Anyone (anon + authenticated) can read: legal pages are shown before login
-- in the mobile app and on the public web pages of the admin panel.
CREATE POLICY "Anyone can view legal content"
  ON public.legal_content
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Admins can insert legal content"
  ON public.legal_content
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY "Admins can update legal content"
  ON public.legal_content
  FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "Admins can delete legal content"
  ON public.legal_content
  FOR DELETE
  TO authenticated
  USING (public.is_admin());
