-- ============================================================
-- Seed default Membership Plans
--
-- The three customer tiers shown in the app:
--   1. Silver Shield    – 10% off bookings (up to ₹500)
--   2. Gold Sentinel    – 20% off bookings (up to ₹1,500), most popular
--   3. Platinum Elite   – 30% off bookings (no cap)
--
-- Yearly price ≈ 10 × monthly (two months free).
-- display_order uses steps of 1000 so admins can reorder / insert before.
--
-- Safe to run multiple times. Existing plans (matched by name, ignoring
-- case and spaces) are left untouched (ON CONFLICT DO NOTHING), so plans
-- an admin has already edited are never overwritten by this seed.
-- ============================================================

INSERT INTO public.membership_plans (
  name,
  description,
  price_per_month,
  price_per_year,
  discount,
  discount_type,
  discount_upto,
  is_popular,
  is_active,
  display_order
)
VALUES
  (
    'Silver Shield',
    ARRAY[
      '10% off every booking, up to ₹500 per booking',
      'Access to all verified bodyguards',
      'Standard customer support'
    ],
    499.00,
    4999.00,
    10,
    'PERCENTAGE'::public.membership_discount_type,
    500.00,
    false,
    true,
    1000
  ),
  (
    'Gold Sentinel',
    ARRAY[
      '20% off every booking, up to ₹1,500 per booking',
      'Access to all verified bodyguards and security companies',
      'Priority customer support',
      'Priority matching for urgent bookings'
    ],
    999.00,
    9999.00,
    20,
    'PERCENTAGE'::public.membership_discount_type,
    1500.00,
    true,
    true,
    2000
  ),
  (
    'Platinum Elite',
    ARRAY[
      '30% off every booking, no upper limit',
      'Access to all verified bodyguards and security companies',
      'Dedicated 24/7 support line',
      'Priority matching for urgent bookings',
      'Free cancellation up to 2 hours before a booking'
    ],
    1999.00,
    19999.00,
    30,
    'PERCENTAGE'::public.membership_discount_type,
    NULL,
    false,
    true,
    3000
  )
ON CONFLICT ((lower(btrim(name)))) DO NOTHING;
