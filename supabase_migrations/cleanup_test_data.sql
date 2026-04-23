-- Clean up all booking-related test data
-- Run this to delete all bookings, subscriptions, gym_slots and related data

BEGIN;

-- Delete in reverse dependency order (bookings depend on slots/subscriptions, etc.)
DELETE FROM bookings;
DELETE FROM user_subscriptions;
DELETE FROM gym_slots;
DELETE FROM package_gyms;
DELETE FROM packages;
DELETE FROM gyms;

COMMIT;

-- Optional: Verify cleanup
SELECT 'bookings' as table_name, COUNT(*) as remaining_rows FROM bookings
UNION ALL
SELECT 'user_subscriptions', COUNT(*) FROM user_subscriptions
UNION ALL
SELECT 'gym_slots', COUNT(*) FROM gym_slots
UNION ALL
SELECT 'package_gyms', COUNT(*) FROM package_gyms
UNION ALL
SELECT 'packages', COUNT(*) FROM packages
UNION ALL
SELECT 'gyms', COUNT(*) FROM gyms;