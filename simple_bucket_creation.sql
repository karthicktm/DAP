-- Simple bucket creation - try this first
-- Run in Supabase SQL Editor: https://supabase.com/dashboard/project/bgoasjlsfgaztmvdofvq/sql

-- First create just the bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('voice_recordings', 'voice_recordings', false, 52428800)
ON CONFLICT (id) DO NOTHING;

-- Check if it was created
SELECT * FROM storage.buckets WHERE id = 'voice_recordings';