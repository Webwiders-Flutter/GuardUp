-- ==============================================================================
-- MIGRATION: Backfill public.user_availabilities from legacy users.metadata
-- ==============================================================================
-- Legacy mobile builds stored weekly availability inside users.metadata['availability']
-- keyed by weekday name. Backfill any account row that still has that key and
-- has no rows in public.user_availabilities yet. The metadata key is intentionally
-- retained so rollback remains safe.

INSERT INTO public.user_availabilities (
  user_id,
  day_of_week,
  is_available,
  from_time,
  to_time
)
SELECT
  u.id AS user_id,
  d.day_name AS day_of_week,
  CASE
    WHEN lower(COALESCE(day_obj ->> 'is_available', 'false')) = 'true' THEN true
    ELSE false
  END AS is_available,
  COALESCE(NULLIF(trim(day_obj ->> 'from'), ''), '09:00 AM') AS from_time,
  COALESCE(NULLIF(trim(day_obj ->> 'to'), ''), '05:00 PM') AS to_time
FROM public.users u
CROSS JOIN unnest(
  ARRAY[
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ]
) AS d(day_name)
CROSS JOIN LATERAL (
  SELECT COALESCE(
    u.metadata -> 'availability' -> d.day_name,
    u.metadata -> 'availability' -> upper(d.day_name)
  ) AS day_obj
) AS entry
WHERE u.metadata ? 'availability'
  AND jsonb_typeof(u.metadata -> 'availability') = 'object'
  AND NOT EXISTS (
    SELECT 1
    FROM public.user_availabilities ua
    WHERE ua.user_id = u.id
  )
ON CONFLICT (user_id, day_of_week) DO NOTHING;
