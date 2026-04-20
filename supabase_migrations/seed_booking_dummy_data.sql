-- Dummy data seed for booking assignment testing
-- Run this after the schema migration files.
-- Adjust the test user UUIDs below if you want seeded subscriptions/bookings.

-- Packages
INSERT INTO public.packages (id, name, description, price, sessions_count, badge, is_featured, icon_name, stripe_price_id, validity_days, allowed_class_names)
VALUES
  (gen_random_uuid(), 'Starter 4 Pack', 'Four flexible sessions for light weekly training.', 59.00, 4, 'starter', false, 'fitness_center', 'price_1TNt6O2MwtvIP2XlLyaRO8T4', 30, ARRAY['Morning Strength','Lunch Burn','Recovery Yoga']),
  (gen_random_uuid(), 'Core Strength 8 Pack', 'Balanced package for regular training.', 109.00, 8, 'popular', true, 'fitness_center', 'price_1TNt6O2MwtvIP2XlLyaRO8T4', 45, ARRAY['Morning Strength','Strength Circuit','Push Pull Legs','Sunday Strength']),
  (gen_random_uuid(), 'HIIT Blast 12 Pack', 'High intensity training bundle.', 149.00, 12, 'best value', true, 'directions_run', 'price_1TNt6O2MwtvIP2XlLyaRO8T4', 60, ARRAY['Evening HIIT','Weekend HIIT','HIIT Start','MetCon Madness','Sprint Intervals','Cardio Clash']),
  (gen_random_uuid(), 'Mobility Reset 6 Pack', 'Recovery-focused mobility sessions.', 79.00, 6, null, false, 'self_improvement', 'price_1TNt6O2MwtvIP2XlLyaRO8T4', 30, ARRAY['Yoga Flow','Recovery Yoga','Midday Mobility','Sunday Flow','Power Mobility']),
  (gen_random_uuid(), 'Power Endurance 10 Pack', 'Build stamina and endurance.', 129.00, 10, null, false, 'fitness_center', 'price_1TNt6O2MwtvIP2XlLyaRO8T4', 45, ARRAY['Strength Circuit','Lunch Burn','Push Pull Legs','Sprint Intervals','Evening Power','Athlete Conditioning']),
  (gen_random_uuid(), 'Premium Athlete 20 Pack', 'Large bundle for consistent training.', 249.00, 20, 'premium', true, 'sports_gymnastics', 'price_1TNt6O2MwtvIP2XlLyaRO8T4', 90, ARRAY['Morning Strength','Yoga Flow','Evening HIIT','Strength Circuit','Lunch Burn','Power Mobility','Night Sprint','Core Builder','MetCon Madness','Recovery Yoga','Push Pull Legs','Weekend Squash Clinic','Weekend HIIT','Sunday Strength','Sunday Flow','HIIT Start','Midday Mobility','Evening Power','Sprint Intervals','End of Month Burn','May Day Strength','Weekend Recharge','Athlete Conditioning','Cardio Clash'])
ON CONFLICT DO NOTHING;

-- Gym slots for the next 10 days
INSERT INTO public.gym_slots (id, start_time, end_time, class_name, coach_name, location, total_spots, occupied_spots)
VALUES
  (gen_random_uuid(), '2026-04-20 07:00:00+08', '2026-04-20 08:00:00+08', 'Morning Strength', 'Coach Rafi', 'Zone A', 20, 12),
  (gen_random_uuid(), '2026-04-20 10:00:00+08', '2026-04-20 11:00:00+08', 'Yoga Flow', 'Coach Aina', 'Studio 2', 15, 8),
  (gen_random_uuid(), '2026-04-20 18:00:00+08', '2026-04-20 19:00:00+08', 'Evening HIIT', 'Coach Ben', 'Zone B', 25, 23),
  (gen_random_uuid(), '2026-04-21 07:00:00+08', '2026-04-21 08:00:00+08', 'Strength Circuit', 'Coach Rafi', 'Zone A', 20, 9),
  (gen_random_uuid(), '2026-04-21 12:00:00+08', '2026-04-21 13:00:00+08', 'Lunch Burn', 'Coach Hana', 'Zone C', 18, 5),
  (gen_random_uuid(), '2026-04-22 09:00:00+08', '2026-04-22 10:00:00+08', 'Power Mobility', 'Coach Aina', 'Studio 1', 14, 7),
  (gen_random_uuid(), '2026-04-22 19:00:00+08', '2026-04-22 20:00:00+08', 'Night Sprint', 'Coach Ben', 'Track 1', 22, 14),
  (gen_random_uuid(), '2026-04-23 07:30:00+08', '2026-04-23 08:30:00+08', 'Core Builder', 'Coach Amir', 'Zone B', 16, 6),
  (gen_random_uuid(), '2026-04-23 18:30:00+08', '2026-04-23 19:30:00+08', 'MetCon Madness', 'Coach Hana', 'Zone C', 24, 20),
  (gen_random_uuid(), '2026-04-24 08:00:00+08', '2026-04-24 09:00:00+08', 'Recovery Yoga', 'Coach Aina', 'Studio 2', 15, 4),
  (gen_random_uuid(), '2026-04-24 17:00:00+08', '2026-04-24 18:00:00+08', 'Push Pull Legs', 'Coach Rafi', 'Zone A', 20, 17),
  (gen_random_uuid(), '2026-04-25 09:00:00+08', '2026-04-25 10:00:00+08', 'Weekend Squash Clinic', 'Coach Sam', 'Court 1', 10, 2),
  (gen_random_uuid(), '2026-04-25 11:00:00+08', '2026-04-25 12:00:00+08', 'Weekend HIIT', 'Coach Ben', 'Zone B', 25, 19),
  (gen_random_uuid(), '2026-04-26 08:00:00+08', '2026-04-26 09:00:00+08', 'Sunday Strength', 'Coach Amir', 'Zone A', 20, 10),
  (gen_random_uuid(), '2026-04-26 16:00:00+08', '2026-04-26 17:00:00+08', 'Sunday Flow', 'Coach Aina', 'Studio 1', 15, 11),
  (gen_random_uuid(), '2026-04-27 07:00:00+08', '2026-04-27 08:00:00+08', 'HIIT Start', 'Coach Ben', 'Zone C', 24, 13),
  (gen_random_uuid(), '2026-04-27 12:30:00+08', '2026-04-27 13:30:00+08', 'Midday Mobility', 'Coach Hana', 'Studio 2', 16, 5),
  (gen_random_uuid(), '2026-04-28 18:00:00+08', '2026-04-28 19:00:00+08', 'Evening Power', 'Coach Rafi', 'Zone A', 20, 18),
  (gen_random_uuid(), '2026-04-29 09:30:00+08', '2026-04-29 10:30:00+08', 'Sprint Intervals', 'Coach Ben', 'Track 1', 22, 8),
  (gen_random_uuid(), '2026-04-30 19:00:00+08', '2026-04-30 20:00:00+08', 'End of Month Burn', 'Coach Amir', 'Zone B', 26, 21),
  (gen_random_uuid(), '2026-05-01 07:00:00+08', '2026-05-01 08:00:00+08', 'May Day Strength', 'Coach Aina', 'Zone A', 20, 7),
  (gen_random_uuid(), '2026-05-02 10:00:00+08', '2026-05-02 11:00:00+08', 'Weekend Recharge', 'Coach Hana', 'Studio 1', 18, 3),
  (gen_random_uuid(), '2026-05-03 08:00:00+08', '2026-05-03 09:00:00+08', 'Athlete Conditioning', 'Coach Rafi', 'Zone C', 24, 16),
  (gen_random_uuid(), '2026-05-04 17:30:00+08', '2026-05-04 18:30:00+08', 'Cardio Clash', 'Coach Ben', 'Track 1', 22, 12)
ON CONFLICT DO NOTHING;

-- Optional sample subscription and bookings.
-- Replace the UUID values below with real auth.users.id values from your test account(s).
-- If you do not want seeded user data yet, leave these commented.

-- INSERT INTO public.user_subscriptions (user_id, package_id, sessions_remaining, expiry_date, last_payment_intent_id)
-- SELECT '00000000-0000-0000-0000-000000000001', id, sessions_count, CURRENT_DATE + validity_days, 'pi_test_001'
-- FROM public.packages
-- ORDER BY price
-- LIMIT 1;

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
