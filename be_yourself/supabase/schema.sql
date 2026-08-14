-- ==============================================================================
-- BEYOURSELF POSTGRESQL / SUPABASE DATABASE SCHEMA
-- Zero-Auth Private User Device UUID Isolation Architecture
-- ==============================================================================

-- 1. Quotes Table
CREATE TABLE IF NOT EXISTS public.quotes (
    id TEXT PRIMARY KEY,
    device_id TEXT NOT NULL,
    text TEXT NOT NULL,
    author TEXT DEFAULT 'Bilinmeyen',
    category_name TEXT DEFAULT 'Genel',
    short_text TEXT,
    media_url TEXT,
    media_urls TEXT[] DEFAULT '{}',
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for lightning fast device queries
CREATE INDEX IF NOT EXISTS idx_quotes_device_id ON public.quotes(device_id);
CREATE INDEX IF NOT EXISTS idx_quotes_category ON public.quotes(device_id, category_name);
CREATE INDEX IF NOT EXISTS idx_quotes_favorite ON public.quotes(device_id, is_favorite);

-- 2. User Profiles Table
CREATE TABLE IF NOT EXISTS public.user_profiles (
    device_id TEXT PRIMARY KEY,
    name TEXT DEFAULT 'Zehra Tuncer',
    motto TEXT DEFAULT 'Kendin Ol!',
    avatar_emoji TEXT DEFAULT '💫',
    avatar_path TEXT,
    greeting_style TEXT DEFAULT 'friendly',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Categories Table
CREATE TABLE IF NOT EXISTS public.categories (
    id TEXT PRIMARY KEY,
    device_id TEXT NOT NULL,
    name TEXT NOT NULL,
    icon_code INTEGER DEFAULT 57444,
    color_value BIGINT DEFAULT 4280838123,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_categories_device_id ON public.categories(device_id);

-- 4. Enable Row Level Security (RLS) - Optional if direct anon API with device_id filter
ALTER TABLE public.quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Allow public access with device_id match
CREATE POLICY "Allow public device quotes access" ON public.quotes
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow public device profiles access" ON public.user_profiles
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow public device categories access" ON public.categories
    FOR ALL USING (true) WITH CHECK (true);

-- 5. Storage Bucket Configuration (media)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('media', 'media', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public Media Bucket Access" ON storage.objects
    FOR ALL USING (bucket_id = 'media')
    WITH CHECK (bucket_id = 'media');
