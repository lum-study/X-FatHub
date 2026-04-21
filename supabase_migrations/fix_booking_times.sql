-- Migrate slot and booking times to use local Malaysia timezone consistently
-- This ensures what's stored in DB matches what the user sees in the app

BEGIN;

-- 1. Update existing gym_slots to show Malaysia time
UPDATE public.gym_slots 
SET start_time = start_time AT TIME ZONE 'Asia/Kuala_Lumpur',
    end_time = end_time AT TIME ZONE 'Asia/Kuala_Lumpur'
WHERE start_time IS NOT NULL;

-- 2. Update existing bookings to show the slot time
UPDATE public.bookings b
SET booking_date = gs.start_time AT TIME ZONE 'Asia/Kuala_Lumpur'
FROM public.gym_slots gs
WHERE b.slot_id = gs.id AND gs.start_time IS NOT NULL;

-- 3. Update the SQL function to use Malaysia timezone for comparisons
-- (The function is already using 'Asia/Kuala_Lumpur' for NOW(), so this should work)

COMMIT;

-- Verify the changes
SELECT 
  id, 
  class_name, 
  start_time as "stored_time",
  start_time AT TIME ZONE 'Asia/Kuala_Lumpur' as "malaysia_time"
FROM public.gym_slots 
ORDER BY start_time 
LIMIT 10;

SELECT 
  id, 
  booking_date as "stored_date",
  booking_date AT TIME ZONE 'Asia/Kuala_Lumpur' as "malaysia_date"
FROM public.bookings 
ORDER BY booking_date 
LIMIT 10;