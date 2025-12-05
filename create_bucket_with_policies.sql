-- Alternative approach: Create bucket and policies together
-- Run in Supabase SQL Editor

-- Step 1: Drop existing bucket if it exists (to start fresh)
DELETE FROM storage.buckets WHERE id = 'voice_recordings';

-- Step 2: Create bucket with public access for testing
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'voice_recordings',
  'voice_recordings',
  true,  -- Make it public for easier testing
  52428800,
  ARRAY['audio/webm', 'audio/m4a', 'audio/mp3', 'audio/wav', 'audio/ogg']
);

-- Step 3: Check if bucket was created successfully
SELECT * FROM storage.buckets WHERE id = 'voice_recordings';