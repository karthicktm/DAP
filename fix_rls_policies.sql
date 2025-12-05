-- Fix RLS policies for voice_recordings bucket access
-- Run this in Supabase SQL Editor

-- First, enable RLS on the storage.objects table if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Create policies for the voice_recordings bucket

-- Policy 1: Allow anyone to upload to voice_recordings bucket (for testing)
CREATE POLICY "Allow voice recordings upload" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'voice_recordings'
);

-- Policy 2: Allow anyone to read from voice_recordings bucket (for testing)
CREATE POLICY "Allow voice recordings read" ON storage.objects
FOR SELECT USING (
  bucket_id = 'voice_recordings'
);

-- Policy 3: Allow anyone to update voice recordings (for testing)
CREATE POLICY "Allow voice recordings update" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'voice_recordings'
);

-- Policy 4: Allow anyone to delete voice recordings (for testing)
CREATE POLICY "Allow voice recordings delete" ON storage.objects
FOR DELETE USING (
  bucket_id = 'voice_recordings'
);

-- Grant permissions
GRANT ALL ON storage.objects TO anon;
GRANT ALL ON storage.objects TO authenticated;

-- Test the policies
SELECT * FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';