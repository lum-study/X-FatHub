-- Add gender and birthdate columns to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS birthdate DATE;
