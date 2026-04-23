-- Add tracker goal columns to profiles table so tracker and profile share one goal source
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS hydration_goal INTEGER;

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS step_goal INTEGER;
