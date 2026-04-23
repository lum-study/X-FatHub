-- Destructive reset for local / throwaway Supabase test env only.
-- Wipes app tables, auth users, and storage so `init_schema.sql` + `seed_dummy_data.sql` can be re-run cleanly.

BEGIN;

-- App functions / triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS set_user_subscriptions_updated_at ON public.user_subscriptions;
DROP TRIGGER IF EXISTS set_gyms_updated_at ON public.gyms;
DROP TRIGGER IF EXISTS set_package_gyms_updated_at ON public.package_gyms;
DROP TRIGGER IF EXISTS set_gym_slots_updated_at ON public.gym_slots;

DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.set_updated_at();
DROP FUNCTION IF EXISTS public.get_user_credit_balance(UUID, UUID);
DROP FUNCTION IF EXISTS public.create_booking_with_credit(UUID, UUID, UUID);
DROP FUNCTION IF EXISTS public.cancel_booking_with_refund(UUID, UUID);
DROP FUNCTION IF EXISTS public.reschedule_booking(UUID, UUID, UUID);

-- App tables
DROP TABLE IF EXISTS public.user_followers CASCADE;
DROP TABLE IF EXISTS public.post_favourites CASCADE;
DROP TABLE IF EXISTS public.post_likes CASCADE;
DROP TABLE IF EXISTS public.post_comments CASCADE;
DROP TABLE IF EXISTS public.posts CASCADE;
DROP TABLE IF EXISTS public.step_tracker_daily CASCADE;
DROP TABLE IF EXISTS public.step_tracker_goals CASCADE;
DROP TABLE IF EXISTS public.hydration_daily CASCADE;
DROP TABLE IF EXISTS public.hydration_goals CASCADE;
DROP TABLE IF EXISTS public.stripe_webhook_events CASCADE;
DROP TABLE IF EXISTS public.bookings CASCADE;
DROP TABLE IF EXISTS public.user_subscriptions CASCADE;
DROP TABLE IF EXISTS public.gym_slots CASCADE;
DROP TABLE IF EXISTS public.package_gyms CASCADE;
DROP TABLE IF EXISTS public.gyms CASCADE;
DROP TABLE IF EXISTS public.packages CASCADE;
DROP TABLE IF EXISTS public.weight_history CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Auth users
TRUNCATE TABLE auth.users CASCADE;

COMMIT;
