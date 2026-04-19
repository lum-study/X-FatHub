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
INSERT INTO public.posts (id, user_id, content, category, media_url, created_at)
VALUES 
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Just smashed my PR on deadlifts! 120kg feeling incredibly light today. Massive thanks to @CoachRafi for fixing my form.', 'Workouts', NULL, NOW() - INTERVAL '2 hours'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'Morning yoga session complete. Finding my center before the busy week starts! #Mindfulness', 'All Posts', 'placeholder_image', NOW() - INTERVAL '5 hours'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333', 'Any tips on reducing carb intake without feeling starved? Need to stick to my diet plan.', 'Diet', NULL, NOW() - INTERVAL '1 day'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', 'Second workout of the day done ✕ Consistency is key!', 'Workouts', NULL, NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

-- 4. Insert Dummy Comments
INSERT INTO public.post_comments (post_id, user_id, content, created_at) 
VALUES 
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'Wow, amazing job Alex!', NOW() - INTERVAL '1 hour'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', 'Beast mode!', NOW() - INTERVAL '30 minutes'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'Namaste!', NOW() - INTERVAL '4 hours'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', 'Try eating more protein and fiber, it helps keep you full.', NOW() - INTERVAL '20 hours');

-- 5. Insert Dummy Likes
INSERT INTO public.post_likes (post_id, user_id)
VALUES 
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '22222222-2222-2222-2222-222222222222')
ON CONFLICT (post_id, user_id) DO NOTHING;

-- 6. Insert Dummy Favourites
INSERT INTO public.post_favourites (post_id, user_id)
VALUES 
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333')
ON CONFLICT (post_id, user_id) DO NOTHING;

-- 7. Insert Followers (who follows who)
-- Example: Alex follows Sarah and Mike; Sarah follows Alex
INSERT INTO public.user_followers (follower_id, following_id)
VALUES 
  ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222'),
  ('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333'),
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111')
ON CONFLICT (follower_id, following_id) DO NOTHING;
