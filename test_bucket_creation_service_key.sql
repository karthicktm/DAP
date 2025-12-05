-- Alternative: Simple bucket creation using service role
-- Try this if the first script didn't work

-- Step 1: Just create the bucket without policies first
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('voice_recordings', 'voice_recordings', false, 52428800);

-- Step 2: Simple policies
CREATE POLICY "Allow authenticated users to upload" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'voice_recordings');

-- Step 3: Check if bucket exists
SELECT * FROM storage.buckets WHERE id = 'voice_recordings';