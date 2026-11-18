-- ==============================================================================
-- MIGRATION: Create public.membership_plans
--
-- Customer membership tiers (e.g. Silver Shield, Gold Sentinel, Platinum Elite).
-- A plan is bought monthly (and optionally yearly) and gives the customer a
-- discount on bookings, either a percentage (optionally capped) or a flat amount.
--
-- 1. Enum: membership_discount_type
-- 2. Table + constraints + indexes
-- 3. Trigger: updated_at
-- 4. RLS: anyone can read active plans, admins have full access
-- ==============================================================================

-- 1. Enum ----------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE public.membership_discount_type AS ENUM ('PERCENTAGE', 'FLAT');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- 2. Table ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.membership_plans (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  -- One line per benefit, shown as a bullet list on the plan card.
  description text[] NOT NULL DEFAULT '{}'::text[],
  price_per_month numeric(12, 2) NOT NULL,
  price_per_year numeric(12, 2) NULL,
  discount numeric(12, 2) NOT NULL DEFAULT 0,
  discount_type public.membership_discount_type NOT NULL
    DEFAULT 'PERCENTAGE'::public.membership_discount_type,
  -- Maximum discount amount per booking. Only applies to PERCENTAGE discounts.
  discount_upto numeric(12, 2) NULL,
  -- Highlights the plan as "Most popular" in the app.
  is_popular boolean NOT NULL DEFAULT false,
  is_active boolean NOT NULL DEFAULT true,
  -- Ascending tier order. Set by the client (new plans go first: first - 1000),
  -- so it can be 0 or negative.
  display_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),

  CONSTRAINT membership_plans_pkey PRIMARY KEY (id),
  CONSTRAINT membership_plans_name_not_blank CHECK (length(btrim(name)) > 0),
  CONSTRAINT membership_plans_price_per_month_check CHECK (price_per_month >= 0),
  CONSTRAINT membership_plans_price_per_year_check
    CHECK (price_per_year IS NULL OR price_per_year >= 0),
  CONSTRAINT membership_plans_discount_check CHECK (discount >= 0),
  CONSTRAINT membership_plans_percentage_discount_check
    CHECK (discount_type <> 'PERCENTAGE' OR discount <= 100),
  CONSTRAINT membership_plans_discount_upto_check
    CHECK (discount_upto IS NULL OR discount_upto > 0),
  CONSTRAINT membership_plans_discount_upto_percentage_only
    CHECK (discount_upto IS NULL OR discount_type = 'PERCENTAGE')
) TABLESPACE pg_default;

-- Plan names are unique regardless of case / surrounding spaces.
CREATE UNIQUE INDEX IF NOT EXISTS uq_membership_plans_name
  ON public.membership_plans USING btree (lower(btrim(name))) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_membership_plans_is_active
  ON public.membership_plans USING btree (is_active) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_membership_plans_display_order
  ON public.membership_plans USING btree (display_order) TABLESPACE pg_default;

-- 3. Trigger -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_membership_plans_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_membership_plans_updated_at ON public.membership_plans;
CREATE TRIGGER set_membership_plans_updated_at
BEFORE UPDATE ON public.membership_plans
FOR EACH ROW
EXECUTE FUNCTION public.handle_membership_plans_updated_at();

-- 4. Row Level Security --------------------------------------------------------
ALTER TABLE public.membership_plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view active membership plans" ON public.membership_plans;
DROP POLICY IF EXISTS "Admins have full access to membership plans" ON public.membership_plans;

-- Customers (and the logged-out app) only see plans that are on sale.
CREATE POLICY "Anyone can view active membership plans"
  ON public.membership_plans
  FOR SELECT
  USING (is_active = true);

-- Admins can read inactive plans too, and create / update / delete any plan.
CREATE POLICY "Admins have full access to membership plans"
  ON public.membership_plans
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());
