-- Clean up all booking-related test data
-- Run this to delete all bookings, subscriptions, gym_slots and related data

BEGIN;

-- Delete in reverse dependency order (bookings depend on slots/subscriptions, etc.)
DELETE FROM public.bookings;
DELETE FROM public.user_subscriptions;
DELETE FROM public.gym_slots;
DELETE FROM public.package_gyms;
DELETE FROM public.packages;
DELETE FROM public.gyms;

COMMIT;

-- Optional: Verify cleanup
SELECT 'bookings' as table_name, COUNT(*) as remaining_rows FROM public.bookings
UNION ALL
SELECT 'user_subscriptions', COUNT(*) FROM public.user_subscriptions
UNION ALL
SELECT 'gym_slots', COUNT(*) FROM public.gym_slots
UNION ALL
SELECT 'package_gyms', COUNT(*) FROM public.package_gyms
UNION ALL
SELECT 'packages', COUNT(*) FROM public.packages
UNION ALL
SELECT 'gyms', COUNT(*) FROM public.gyms;