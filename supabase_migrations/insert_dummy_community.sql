-- 1. Insert Dummy Users into auth.users
-- We use predefined UUIDs so we can link them to posts, likes, and comments.
-- Note: inserting into auth.users will automatically trigger your 'on_auth_user_created' 
-- function to create matching rows in the 'public.profiles' table.

INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
VALUES 
  ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'alex@dummy.com', 'dummy123', now(), '{"provider":"email","providers":["email"]}', '{"name":"Alex Fit"}', now(), now()),
  ('22222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'sarah@dummy.com', 'dummy123', now(), '{"provider":"email","providers":["email"]}', '{"name":"Sarah J."}', now(), now()),
  ('33333333-3333-3333-3333-333333333333', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'mike@dummy.com', 'dummy123', now(), '{"provider":"email","providers":["email"]}', '{"name":"Mike B."}', now(), now())
ON CONFLICT (id) DO NOTHING;

-- 2. Insert/Update profiles with names and bios
-- Ensure they exist in profiles table (in case the trigger didn't fire due to ON CONFLICT)
INSERT INTO public.profiles (id, email, name, bio)
VALUES 
  ('11111111-1111-1111-1111-111111111111', 'alex@dummy.com', 'Alex Fit', 'Fitness enthusiast'),
  ('22222222-2222-2222-2222-222222222222', 'sarah@dummy.com', 'Sarah J.', 'Yoga lover'),
  ('33333333-3333-3333-3333-333333333333', 'mike@dummy.com', 'Mike B.', 'Diet conscious')
ON CONFLICT (id) DO UPDATE SET 
  name = EXCLUDED.name, 
  bio = EXCLUDED.bio;

-- 3. Insert Dummy Posts
-- Using predefined UUIDs for posts so we can reference them in likes/comments.
INSERT INTO public.posts (id, user_id, content, media_url, created_at)
VALUES 
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Just smashed my PR on deadlifts! 120kg feeling incredibly light today. Massive thanks to @CoachRafi for fixing my form.', NULL, NOW() - INTERVAL '2 hours'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'Morning yoga session complete. Finding my center before the busy week starts! #Mindfulness', NULL, NOW() - INTERVAL '5 hours'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333', 'Any tips on reducing carb intake without feeling starved? Need to stick to my diet plan.', NULL, NOW() - INTERVAL '1 day'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', 'Second workout of the day done ✕ Consistency is key!', NULL, NOW() - INTERVAL '2 days'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '22222222-2222-2222-2222-222222222222', 'Quick 20-minute stretch session before bed. Sleep quality has improved a lot lately.', NULL, NOW() - INTERVAL '3 hours'),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', '33333333-3333-3333-3333-333333333333', 'Meal prep done for three days. Keeping portions simple and clean this week.', NULL, NOW() - INTERVAL '7 hours'),
  ('12121212-1212-1212-1212-121212121212', '11111111-1111-1111-1111-111111111111', 'Leg day checklist complete: squats, lunges, calf raises. Feeling strong!', NULL, NOW() - INTERVAL '10 hours'),
  ('34343434-3434-3434-3434-343434343434', '22222222-2222-2222-2222-222222222222', 'Hydration reminder: finished 3 liters today and energy levels stayed stable.', NULL, NOW() - INTERVAL '14 hours'),
  ('56565656-5656-5656-5656-565656565656', '33333333-3333-3333-3333-333333333333', 'Tried replacing late-night snacks with greek yogurt and fruit. So far so good.', NULL, NOW() - INTERVAL '26 hours'),
  ('78787878-7878-7878-7878-787878787878', '11111111-1111-1111-1111-111111111111', 'Recovery day today: light walk, foam rolling, and early bedtime.', NULL, NOW() - INTERVAL '40 hours')
ON CONFLICT (id) DO NOTHING;

-- 4. Insert Dummy Comments
INSERT INTO public.post_comments (post_id, user_id, content, created_at) 
VALUES 
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'Wow, amazing job Alex!', NOW() - INTERVAL '1 hour'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', 'Beast mode!', NOW() - INTERVAL '30 minutes'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'Namaste!', NOW() - INTERVAL '4 hours'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', 'Try eating more protein and fiber, it helps keep you full.', NOW() - INTERVAL '20 hours'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '11111111-1111-1111-1111-111111111111', 'Nice routine. Stretching before sleep really helps recovery.', NOW() - INTERVAL '2 hours'),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', '22222222-2222-2222-2222-222222222222', 'Meal prep is a game changer for consistency.', NOW() - INTERVAL '6 hours'),
  ('12121212-1212-1212-1212-121212121212', '33333333-3333-3333-3333-333333333333', 'Solid session. Progressive overload next week?', NOW() - INTERVAL '8 hours'),
  ('34343434-3434-3434-3434-343434343434', '11111111-1111-1111-1111-111111111111', 'Great reminder, I always forget to drink enough water.', NOW() - INTERVAL '12 hours'),
  ('56565656-5656-5656-5656-565656565656', '22222222-2222-2222-2222-222222222222', 'That snack swap is smart and still satisfying.', NOW() - INTERVAL '22 hours');

-- 5. Insert Dummy Likes
INSERT INTO public.post_likes (post_id, user_id)
VALUES 
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '22222222-2222-2222-2222-222222222222'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '11111111-1111-1111-1111-111111111111'),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', '22222222-2222-2222-2222-222222222222'),
  ('12121212-1212-1212-1212-121212121212', '33333333-3333-3333-3333-333333333333'),
  ('34343434-3434-3434-3434-343434343434', '11111111-1111-1111-1111-111111111111'),
  ('56565656-5656-5656-5656-565656565656', '22222222-2222-2222-2222-222222222222'),
  ('78787878-7878-7878-7878-787878787878', '33333333-3333-3333-3333-333333333333')
ON CONFLICT (post_id, user_id) DO NOTHING;

-- 6. Insert Dummy Favourites
INSERT INTO public.post_favourites (post_id, user_id)
VALUES 
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '33333333-3333-3333-3333-333333333333'),
  ('12121212-1212-1212-1212-121212121212', '22222222-2222-2222-2222-222222222222'),
  ('78787878-7878-7878-7878-787878787878', '22222222-2222-2222-2222-222222222222')
ON CONFLICT (post_id, user_id) DO NOTHING;

-- 7. Insert Followers (who follows who)
INSERT INTO public.user_followers (follower_id, following_id)
VALUES 
  ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222'),
  ('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333'),
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111')
ON CONFLICT (follower_id, following_id) DO NOTHING;
