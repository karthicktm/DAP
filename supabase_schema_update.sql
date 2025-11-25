-- Add missing columns to tracks table for AI music processing workflow
-- This fixes the PGRST204 error about missing columns

-- Add processing-related columns
ALTER TABLE public.tracks
ADD COLUMN IF NOT EXISTS is_processing BOOLEAN DEFAULT false;

ALTER TABLE public.tracks
ADD COLUMN IF NOT EXISTS processing_status TEXT DEFAULT '';

ALTER TABLE public.tracks
ADD COLUMN IF NOT EXISTS processing_completed BOOLEAN DEFAULT false;

ALTER TABLE public.tracks
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Create function to auto-update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_tracks_updated_at ON public.tracks;
CREATE TRIGGER update_tracks_updated_at
    BEFORE UPDATE ON public.tracks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create index for processing queries
CREATE INDEX IF NOT EXISTS idx_tracks_processing ON public.tracks(is_processing, processing_completed);
CREATE INDEX IF NOT EXISTS idx_tracks_updated_at ON public.tracks(updated_at DESC);

-- Update RLS policy to include new columns
DROP POLICY IF EXISTS "Allow all operations on tracks" ON public.tracks;
CREATE POLICY "Allow all operations on tracks" ON public.tracks
FOR ALL USING (true);

-- Grant permissions for new columns
GRANT ALL ON public.tracks TO anon;
GRANT ALL ON public.tracks TO authenticated;

-- Display current table structure for verification
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'tracks'
ORDER BY ordinal_position;