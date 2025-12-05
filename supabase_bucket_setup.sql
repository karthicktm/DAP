-- Supabase Storage Bucket Setup for Voice Recordings
-- Run this SQL in your Supabase SQL Editor: https://supabase.com/dashboard/project/bgoasjlsfgaztmvdofvq/sql

-- Step 1: Create the storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'voice_recordings',
  'voice_recordings',
  false,
  52428800, -- 50MB in bytes
  ARRAY['audio/webm', 'audio/m4a', 'audio/mp3', 'audio/wav', 'audio/ogg']
);

-- Step 2: Create RLS policies for the bucket
-- Policy to allow users to upload voice recordings
CREATE POLICY "Users can upload voice recordings" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'voice_recordings' AND
  auth.role() = 'authenticated'
);

-- Policy to allow users to read their own voice recordings
CREATE POLICY "Users can read own voice recordings" ON storage.objects
FOR SELECT USING (
  bucket_id = 'voice_recordings' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy to allow users to update their own voice recordings
CREATE POLICY "Users can update own voice recordings" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'voice_recordings' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy to allow users to delete their own voice recordings
CREATE POLICY "Users can delete own voice recordings" ON storage.objects
FOR DELETE USING (
  bucket_id = 'voice_recordings' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Step 3: Grant necessary permissions
GRANT ALL ON storage.buckets TO authenticated;
GRANT ALL ON storage.objects TO authenticated;

-- Step 4: Verify bucket creation (optional)
SELECT * FROM storage.buckets WHERE id = 'voice_recordings';

-- Step 5: Test the bucket setup (optional)
-- This will show the RLS policies for the bucket
SELECT * FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';