-- Dummy data seed for booking assignment testing
-- Run this after the schema migration files.
-- Adjust the test user UUIDs below if you want seeded subscriptions/bookings.

-- Gyms
INSERT INTO public.gyms (id, name, venue, address, status)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'X-Fit Central', 'Downtown Hub', '12 Central Avenue, Kuala Lumpur', 'active'),
  ('22222222-2222-2222-2222-222222222222', 'X-Fit North', 'Northpoint Arena', '8 Northpoint Road, Petaling Jaya', 'active'),
  ('33333333-3333-3333-3333-333333333333', 'X-Fit South', 'Southgate Studio', '33 Southgate Boulevard, Subang', 'active')
ON CONFLICT (id) DO UPDATE
SET
  name = EXCLUDED.name,
  venue = EXCLUDED.venue,
  address = EXCLUDED.address,
  status = EXCLUDED.status;

-- Packages
INSERT INTO public.packages (
  id,
  name,
  description,
  price,
  sessions_count,
  badge,
  is_featured,
  icon_name,
  stripe_price_id,
  validity_days,
  allowed_class_names,
  benefits,
  rules
)
VALUES
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
    'Starter 4 Pack',
    'Four flexible sessions for light weekly training.',
    59.00,
    4,
    'starter',
    false,
    'fitness_center',
    'price_1TNt6O2MwtvIP2XlLyaRO8T4',
    30,
    ARRAY['Morning Strength','Lunch Burn','Recovery Yoga'],
    ARRAY['4 guided sessions','Entry-level package for new users','Flexible slot booking'],
    ARRAY['Valid for 30 days after purchase','Applicable to eligible classes only']
  ),
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2',
    'Core Strength 8 Pack',
    'Balanced package for regular training.',
    109.00,
    8,
    'popular',
    true,
    'fitness_center',
    'price_1TNt6O2MwtvIP2XlLyaRO8T4',
    45,
    ARRAY['Morning Strength','Strength Circuit','Push Pull Legs','Sunday Strength'],
    ARRAY['8 sessions included','Best for strength progression','Priority access to peak slots'],
    ARRAY['Valid for 45 days after purchase','Session is deducted only on confirmed booking']
  ),
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
    'HIIT Blast 12 Pack',
    'High intensity training bundle.',
    149.00,
    12,
    'best value',
    true,
    'directions_run',
    'price_1TNt6O2MwtvIP2XlLyaRO8T4',
    60,
    ARRAY['Evening HIIT','Weekend HIIT','HIIT Start','MetCon Madness','Sprint Intervals','Cardio Clash'],
    ARRAY['12 sessions included','Designed for cardio and metabolic training','Coach-led progression blocks'],
    ARRAY['Valid for 60 days after purchase','Only HIIT-linked classes are selectable']
  ),
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4',
    'Premium Athlete 20 Pack',
    'Large bundle for consistent training.',
    249.00,
    20,
    'premium',
    true,
    'sports_gymnastics',
    'price_1TNt6O2MwtvIP2XlLyaRO8T4',
    90,
    ARRAY['Morning Strength','Yoga Flow','Evening HIIT','Strength Circuit','Lunch Burn','Power Mobility','Night Sprint','Core Builder','MetCon Madness','Recovery Yoga','Push Pull Legs','Weekend HIIT','Sunday Strength','Sunday Flow','HIIT Start','Midday Mobility','Evening Power','Sprint Intervals','Athlete Conditioning','Cardio Clash'],
    ARRAY['20 sessions included','Cross-discipline package','Supports high-frequency training plans'],
    ARRAY['Valid for 90 days after purchase','Can be used only at mapped gyms']
  )
ON CONFLICT (id) DO UPDATE
SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  price = EXCLUDED.price,
  sessions_count = EXCLUDED.sessions_count,
  badge = EXCLUDED.badge,
  is_featured = EXCLUDED.is_featured,
  icon_name = EXCLUDED.icon_name,
  stripe_price_id = EXCLUDED.stripe_price_id,
  validity_days = EXCLUDED.validity_days,
  allowed_class_names = EXCLUDED.allowed_class_names,
  benefits = EXCLUDED.benefits,
  rules = EXCLUDED.rules;

-- Package to gym mapping
INSERT INTO public.package_gyms (id, package_id, gym_id, is_active)
VALUES
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', '11111111-1111-1111-1111-111111111111', true),
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', '22222222-2222-2222-2222-222222222222', true),
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '11111111-1111-1111-1111-111111111111', true),
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '33333333-3333-3333-3333-333333333333', true),
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '22222222-2222-2222-2222-222222222222', true),
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '33333333-3333-3333-3333-333333333333', true),
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4', '11111111-1111-1111-1111-111111111111', true),
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4', '22222222-2222-2222-2222-222222222222', true),
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4', '33333333-3333-3333-3333-333333333333', true)
ON CONFLICT (package_id, gym_id) DO UPDATE
SET is_active = EXCLUDED.is_active;

-- Gym slots
INSERT INTO public.gym_slots (
  id,
  gym_id,
  start_time,
  end_time,
  class_name,
  coach_name,
  location,
  total_spots,
  occupied_spots
)
VALUES
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '2026-04-20 07:00:00+08', '2026-04-20 08:00:00+08', 'Morning Strength', 'Coach Rafi', 'Zone A', 20, 12),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '2026-04-21 07:00:00+08', '2026-04-21 08:00:00+08', 'Strength Circuit', 'Coach Rafi', 'Zone A', 20, 9),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '2026-04-24 17:00:00+08', '2026-04-24 18:00:00+08', 'Push Pull Legs', 'Coach Rafi', 'Zone A', 20, 17),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '2026-05-01 07:00:00+08', '2026-05-01 08:00:00+08', 'May Day Strength', 'Coach Aina', 'Zone A', 20, 7),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-20 18:00:00+08', '2026-04-20 19:00:00+08', 'Evening HIIT', 'Coach Ben', 'Zone B', 25, 23),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-22 19:00:00+08', '2026-04-22 20:00:00+08', 'Night Sprint', 'Coach Ben', 'Track 1', 22, 14),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-25 11:00:00+08', '2026-04-25 12:00:00+08', 'Weekend HIIT', 'Coach Ben', 'Zone B', 25, 19),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-29 09:30:00+08', '2026-04-29 10:30:00+08', 'Sprint Intervals', 'Coach Ben', 'Track 1', 22, 8),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', '2026-04-20 10:00:00+08', '2026-04-20 11:00:00+08', 'Yoga Flow', 'Coach Aina', 'Studio 2', 15, 8),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', '2026-04-22 09:00:00+08', '2026-04-22 10:00:00+08', 'Power Mobility', 'Coach Aina', 'Studio 1', 14, 7),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', '2026-04-24 08:00:00+08', '2026-04-24 09:00:00+08', 'Recovery Yoga', 'Coach Aina', 'Studio 2', 15, 4),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', '2026-05-03 08:00:00+08', '2026-05-03 09:00:00+08', 'Athlete Conditioning', 'Coach Rafi', 'Zone C', 24, 16)
ON CONFLICT DO NOTHING;

-- Rolling future slots for testing (next 21 days from today, local +08).
-- This keeps booking screens populated even when static seed dates are in the past.
WITH day_offsets AS (
  SELECT generate_series(0, 20) AS day_offset
),
slot_templates AS (
  SELECT *
  FROM (
    VALUES
      ('11111111-1111-1111-1111-111111111111', 'Morning Strength', 'Coach Rafi', 'Zone A', TIME '07:00', 20, 9),
      ('11111111-1111-1111-1111-111111111111', 'Strength Circuit', 'Coach Rafi', 'Zone A', TIME '12:00', 20, 7),
      ('11111111-1111-1111-1111-111111111111', 'Push Pull Legs', 'Coach Rafi', 'Zone A', TIME '18:00', 20, 8),
      ('22222222-2222-2222-2222-222222222222', 'Evening HIIT', 'Coach Ben', 'Zone B', TIME '18:00', 25, 15),
      ('22222222-2222-2222-2222-222222222222', 'Weekend HIIT', 'Coach Ben', 'Zone B', TIME '10:00', 25, 12),
      ('22222222-2222-2222-2222-222222222222', 'Sprint Intervals', 'Coach Ben', 'Track 1', TIME '20:00', 22, 11),
      ('33333333-3333-3333-3333-333333333333', 'Recovery Yoga', 'Coach Aina', 'Studio 2', TIME '08:00', 15, 5),
      ('33333333-3333-3333-3333-333333333333', 'Power Mobility', 'Coach Aina', 'Studio 1', TIME '14:00', 14, 6),
      ('33333333-3333-3333-3333-333333333333', 'Athlete Conditioning', 'Coach Rafi', 'Zone C', TIME '19:00', 24, 10)
  ) AS t(gym_id, class_name, coach_name, location, start_time_local, total_spots, base_occupied)
),
generated_slots AS (
  SELECT
    st.gym_id::UUID AS gym_id,
    st.class_name,
    st.coach_name,
    st.location,
    ((CURRENT_DATE + d.day_offset)::timestamp + st.start_time_local)::timestamptz AS start_time,
    (((CURRENT_DATE + d.day_offset)::timestamp + st.start_time_local) + INTERVAL '1 hour')::timestamptz AS end_time,
    st.total_spots,
    LEAST(st.total_spots - 1, GREATEST(0, st.base_occupied + ((d.day_offset % 4) - 1))) AS occupied_spots
  FROM slot_templates st
  CROSS JOIN day_offsets d
)
INSERT INTO public.gym_slots (
  id,
  gym_id,
  start_time,
  end_time,
  class_name,
  coach_name,
  location,
  total_spots,
  occupied_spots
)
SELECT
  gen_random_uuid(),
  gs.gym_id,
  gs.start_time,
  gs.end_time,
  gs.class_name,
  gs.coach_name,
  gs.location,
  gs.total_spots,
  gs.occupied_spots
FROM generated_slots gs
WHERE NOT EXISTS (
  SELECT 1
  FROM public.gym_slots existing
  WHERE existing.gym_id = gs.gym_id
    AND existing.class_name = gs.class_name
    AND existing.start_time = gs.start_time
);

-- Optional sample subscription and bookings.
-- Replace the UUID values below with real auth.users.id values from your test account(s).
-- If you do not want seeded user data yet, leave these commented.

-- INSERT INTO public.user_subscriptions (user_id, package_id, sessions_remaining, expiry_date, last_payment_intent_id)
-- SELECT '00000000-0000-0000-0000-000000000001', id, sessions_count, CURRENT_DATE + validity_days, 'pi_test_001'
-- FROM public.packages
-- WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1';

-- INSERT INTO public.bookings (user_id, package_id, slot_id, status, booking_date, total_paid, session_number, qr_code_data)
-- SELECT
--   '00000000-0000-0000-0000-000000000001',
--   p.id,
--   s.id,
--   'upcoming',
--   now(),
--   0,
--   1,
--   jsonb_build_object('booking_id', gen_random_uuid(), 'user_id', '00000000-0000-0000-0000-000000000001', 'slot_id', s.id, 'package_id', p.id)::text
-- FROM public.packages p
-- CROSS JOIN public.gym_slots s
-- ORDER BY s.start_time
-- LIMIT 3;
