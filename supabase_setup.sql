-- Create tracks table for AI music storage
CREATE TABLE IF NOT EXISTS public.tracks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    artist TEXT NOT NULL DEFAULT 'AI Artist',
    genre TEXT,
    mood TEXT,
    audio_url TEXT,
    cover_art_url TEXT,
    duration_seconds INTEGER DEFAULT 120,
    is_instrumental BOOLEAN DEFAULT false,
    lyrics TEXT,
    metadata JSONB DEFAULT '{}',
    user_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_tracks_created_at ON public.tracks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tracks_user_id ON public.tracks(user_id);
CREATE INDEX IF NOT EXISTS idx_tracks_genre ON public.tracks(genre);

-- Enable Row Level Security (RLS)
ALTER TABLE public.tracks ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all operations (you can make this more restrictive later)
CREATE POLICY "Allow all operations on tracks" ON public.tracks
FOR ALL USING (true);

-- Grant permissions to anon and authenticated users
GRANT ALL ON public.tracks TO anon;
GRANT ALL ON public.tracks TO authenticated;