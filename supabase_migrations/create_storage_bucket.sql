-- Create the community_media bucket with format restrictions (image and video only)
INSERT INTO storage.buckets (id, name, public, allowed_mime_types) 
VALUES (
  'community_media', 
  'community_media', 
  true,
  ARRAY['image/*', 'video/*']::text[]
)
ON CONFLICT (id) DO UPDATE 
SET allowed_mime_types = ARRAY['image/*', 'video/*']::text[];

-- Allow public access to view media
CREATE POLICY "Public Access" ON storage.objects
FOR SELECT USING (bucket_id = 'community_media');

-- Allow authenticated users to upload media
CREATE POLICY "Auth Insert" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'community_media' 
  AND auth.role() = 'authenticated'
);

-- Allow authenticated users to delete their own uploaded media
CREATE POLICY "Auth Delete" ON storage.objects
FOR DELETE USING (
  bucket_id = 'community_media' 
  AND auth.uid()::text = (string_to_array(name, '/'))[1]
);
