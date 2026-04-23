-- Booking module seed data (single seed file)
-- Date window intentionally fixed for test scenario: 23 Apr 2026 - 30 Apr 2026 (+08)

BEGIN;

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
  category,
  badge,
  is_featured,
  icon_name,
  stripe_price_id,
  validity_days,
  allowed_class_names,
  benefits,
  rules,
  gym_names
)
VALUES
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
    'Starter 4 Pack',
    'Four flexible sessions for light weekly training.',
    59.00,
    4,
    'Gym',
    'starter',
    false,
    'fitness_center',
    'price_1TP0zK2MwtvIP2XlRS7DDdWz',
    30,
    ARRAY['Morning Strength', 'Lunch Burn', 'Recovery Yoga'],
    ARRAY['4 guided sessions', 'Entry-level package for new users', 'Flexible slot booking'],
    ARRAY['Valid for 30 days after purchase', 'Applicable to eligible classes only'],
    ARRAY['X-Fit Central', 'X-Fit North']
  ),
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2',
    'Core Strength 8 Pack',
    'Balanced package for regular training.',
    109.00,
    8,
    'Gym',
    'popular',
    true,
    'fitness_center',
    'price_1TP0ze2MwtvIP2XlK4MBJw2g',
    45,
    ARRAY['Morning Strength', 'Strength Circuit', 'Push Pull Legs', 'Sunday Strength'],
    ARRAY['8 sessions included', 'Best for strength progression', 'Priority access to peak slots'],
    ARRAY['Valid for 45 days after purchase', 'Session is deducted only on confirmed booking'],
    ARRAY['X-Fit Central', 'X-Fit South']
  ),
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
    'HIIT Blast 12 Pack',
    'High intensity training bundle.',
    149.00,
    12,
    'HIIT',
    'best value',
    true,
    'directions_run',
    'price_1TP0zs2MwtvIP2Xl0U76jB9M',
    60,
    ARRAY['Evening HIIT', 'Weekend HIIT', 'HIIT Start', 'MetCon Madness', 'Sprint Intervals', 'Cardio Clash'],
    ARRAY['12 sessions included', 'Designed for cardio and metabolic training', 'Coach-led progression blocks'],
    ARRAY['Valid for 60 days after purchase', 'Only HIIT-linked classes are selectable'],
    ARRAY['X-Fit North', 'X-Fit South']
  ),
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4',
    'Yoga Flow 6 Pack',
    'Mindful mobility and recovery-focused sessions.',
    99.00,
    6,
    'Yoga',
    'popular',
    false,
    'self_improvement',
    'price_1TP10A2MwtvIP2XlB4E2PjJY',
    40,
    ARRAY['Recovery Yoga', 'Power Mobility', 'Sunday Flow'],
    ARRAY['6 sessions included', 'Great for recovery and flexibility', 'Beginner-friendly pace'],
    ARRAY['Valid for 40 days after purchase', 'Yoga classes only'],
    ARRAY['X-Fit South']
  ),
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa5',
    'Swim Conditioning 6 Pack',
    'Technique and endurance sessions for swimmers.',
    129.00,
    6,
    'Swim',
    'starter',
    false,
    'pool',
    'price_1TP10P2MwtvIP2Xlc5Xzc4Jp',
    45,
    ARRAY['Swim Intervals', 'Swim Endurance', 'Aqua Recovery'],
    ARRAY['6 sessions included', 'Structured swim progression', 'Coach-assisted drills'],
    ARRAY['Valid for 45 days after purchase', 'Swim classes only'],
    ARRAY['X-Fit North']
  )
ON CONFLICT (id) DO UPDATE
SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  price = EXCLUDED.price,
  sessions_count = EXCLUDED.sessions_count,
  category = EXCLUDED.category,
  badge = EXCLUDED.badge,
  is_featured = EXCLUDED.is_featured,
  icon_name = EXCLUDED.icon_name,
  stripe_price_id = EXCLUDED.stripe_price_id,
  validity_days = EXCLUDED.validity_days,
  allowed_class_names = EXCLUDED.allowed_class_names,
  benefits = EXCLUDED.benefits,
  rules = EXCLUDED.rules,
  gym_names = EXCLUDED.gym_names;

-- Package to gym mapping
INSERT INTO public.package_gyms (id, package_id, gym_id, is_active)
VALUES
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', '11111111-1111-1111-1111-111111111111', true),
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', '22222222-2222-2222-2222-222222222222', true),
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '11111111-1111-1111-1111-111111111111', true),
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '33333333-3333-3333-3333-333333333333', true),
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '22222222-2222-2222-2222-222222222222', true),
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '33333333-3333-3333-3333-333333333333', true),
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4', '33333333-3333-3333-3333-333333333333', true),
  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa5', '22222222-2222-2222-2222-222222222222', true)
ON CONFLICT (package_id, gym_id) DO UPDATE
SET is_active = EXCLUDED.is_active;

-- Reset only the target window to keep seed idempotent and predictable.
DELETE FROM public.gym_slots
WHERE start_time >= '2026-04-23 00:00:00+08'::timestamptz
  AND start_time < '2026-05-01 00:00:00+08'::timestamptz;

-- Gym slots for 23 Apr 2026 - 30 Apr 2026 (+08)
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
  -- 23 Apr
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '2026-04-23 07:00:00+08', '2026-04-23 08:00:00+08', 'Morning Strength', 'Coach Rafi', 'Zone A', 20, 8),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', '2026-04-23 09:00:00+08', '2026-04-23 10:00:00+08', 'Power Mobility', 'Coach Aina', 'Studio 1', 14, 6),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-23 18:00:00+08', '2026-04-23 19:00:00+08', 'Evening HIIT', 'Coach Ben', 'Zone B', 25, 16),

  -- 24 Apr
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', '2026-04-24 08:00:00+08', '2026-04-24 09:00:00+08', 'Recovery Yoga', 'Coach Aina', 'Studio 2', 15, 5),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '2026-04-24 17:00:00+08', '2026-04-24 18:00:00+08', 'Push Pull Legs', 'Coach Rafi', 'Zone A', 20, 11),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-24 20:00:00+08', '2026-04-24 21:00:00+08', 'Sprint Intervals', 'Coach Ben', 'Track 1', 22, 9),

  -- 25 Apr
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '2026-04-25 07:30:00+08', '2026-04-25 08:30:00+08', 'Strength Circuit', 'Coach Rafi', 'Zone A', 20, 10),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-25 11:00:00+08', '2026-04-25 12:00:00+08', 'Weekend HIIT', 'Coach Ben', 'Zone B', 25, 18),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', '2026-04-25 17:00:00+08', '2026-04-25 18:00:00+08', 'Sunday Flow', 'Coach Aina', 'Studio 2', 15, 7),

  -- 26 Apr
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-26 08:00:00+08', '2026-04-26 09:00:00+08', 'Swim Intervals', 'Coach Lina', 'Pool Lane 2', 16, 9),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '2026-04-26 12:00:00+08', '2026-04-26 13:00:00+08', 'Lunch Burn', 'Coach Rafi', 'Zone A', 20, 12),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', '2026-04-26 19:00:00+08', '2026-04-26 20:00:00+08', 'Recovery Yoga', 'Coach Aina', 'Studio 2', 15, 6),

  -- 27 Apr
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '2026-04-27 07:00:00+08', '2026-04-27 08:00:00+08', 'Morning Strength', 'Coach Rafi', 'Zone A', 20, 9),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', '2026-04-27 14:00:00+08', '2026-04-27 15:00:00+08', 'Power Mobility', 'Coach Aina', 'Studio 1', 14, 7),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-27 18:00:00+08', '2026-04-27 19:00:00+08', 'Evening HIIT', 'Coach Ben', 'Zone B', 25, 15),

  -- 28 Apr
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-28 08:30:00+08', '2026-04-28 09:30:00+08', 'Swim Endurance', 'Coach Lina', 'Pool Lane 1', 16, 8),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '2026-04-28 17:30:00+08', '2026-04-28 18:30:00+08', 'Push Pull Legs', 'Coach Rafi', 'Zone A', 20, 10),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', '2026-04-28 20:00:00+08', '2026-04-28 21:00:00+08', 'Sunday Flow', 'Coach Aina', 'Studio 2', 15, 8),

  -- 29 Apr
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '2026-04-29 07:00:00+08', '2026-04-29 08:00:00+08', 'Strength Circuit', 'Coach Rafi', 'Zone A', 20, 9),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-29 09:30:00+08', '2026-04-29 10:30:00+08', 'Sprint Intervals', 'Coach Ben', 'Track 1', 22, 11),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', '2026-04-29 19:00:00+08', '2026-04-29 20:00:00+08', 'Recovery Yoga', 'Coach Aina', 'Studio 2', 15, 6),

  -- 30 Apr
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-30 07:00:00+08', '2026-04-30 08:00:00+08', 'Swim Intervals', 'Coach Lina', 'Pool Lane 2', 16, 7),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '2026-04-30 12:00:00+08', '2026-04-30 13:00:00+08', 'Lunch Burn', 'Coach Rafi', 'Zone A', 20, 13),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-30 18:00:00+08', '2026-04-30 19:00:00+08', 'Evening HIIT', 'Coach Ben', 'Zone B', 25, 17),
  
  -- Additional classes for variety
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '2026-04-23 12:00:00+08', '2026-04-23 13:00:00+08', 'Lunch Burn', 'Coach Sarah', 'Zone C', 15, 5),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-24 19:00:00+08', '2026-04-24 20:00:00+08', 'MetCon Madness', 'Coach Ben', 'Track 2', 20, 12),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', '2026-04-25 09:00:00+08', '2026-04-25 10:00:00+08', 'HIIT Start', 'Coach Aina', 'Studio 1', 12, 10),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '2026-04-26 18:00:00+08', '2026-04-26 19:00:00+08', 'Cardio Clash', 'Coach Rafi', 'Zone B', 25, 20),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-27 10:00:00+08', '2026-04-27 11:00:00+08', 'Aqua Recovery', 'Coach Lina', 'Pool Lane 1', 10, 4),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', '2026-04-28 12:00:00+08', '2026-04-28 13:00:00+08', 'Recovery Yoga', 'Coach Aina', 'Studio 2', 15, 14),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '2026-04-29 18:00:00+08', '2026-04-29 19:00:00+08', 'Push Pull Legs', 'Coach Sarah', 'Zone A', 20, 18),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '2026-04-30 20:00:00+08', '2026-04-30 21:00:00+08', 'Sprint Intervals', 'Coach Ben', 'Track 1', 20, 8);

COMMIT;

-- Quick verification
-- SELECT class_name, start_time, end_time FROM public.gym_slots
-- WHERE start_time >= '2026-04-23 00:00:00+08'::timestamptz
--   AND start_time < '2026-05-01 00:00:00+08'::timestamptz
-- ORDER BY start_time;
