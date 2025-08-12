-- QROWD Host & Guest Database Schema
-- Run this in your Supabase SQL Editor

-- ===================================
-- 1. HOSTS TABLE
-- ===================================

CREATE TABLE hosts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    company_name TEXT,
    phone_number TEXT,
    city TEXT NOT NULL,
    preferred_genres TEXT[] DEFAULT '{}',
    typical_event_types TEXT[] DEFAULT '{}', -- ['corporate', 'wedding', 'birthday', 'nightclub', 'festival']
    typical_budget_range TEXT, -- ['$100-500', '$500-1000', '$1000-2500', '$2500+']
    instagram_handle TEXT DEFAULT '',
    website_url TEXT DEFAULT '',
    stripe_account_id TEXT DEFAULT '',
    is_verified BOOLEAN DEFAULT false,
    verification_documents TEXT[] DEFAULT '{}',
    rating DECIMAL(3,2) DEFAULT 5.0,
    total_bookings INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add indexes for hosts
CREATE INDEX idx_hosts_city ON hosts USING gin(to_tsvector('english', city));
CREATE INDEX idx_hosts_user_id ON hosts(user_id);
CREATE INDEX idx_hosts_company_name ON hosts USING gin(to_tsvector('english', company_name));
CREATE INDEX idx_hosts_verified ON hosts(is_verified);

-- ===================================
-- 2. GUESTS TABLE (OPTIONAL PROFILES)
-- ===================================

CREATE TABLE guests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT,
    last_name TEXT,
    city TEXT,
    preferred_genres TEXT[] DEFAULT '{}',
    favorite_djs TEXT[] DEFAULT '{}', -- Array of DJ IDs they've liked/bookmarked
    instagram_handle TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add indexes for guests
CREATE INDEX idx_guests_user_id ON guests(user_id);
CREATE INDEX idx_guests_city ON guests USING gin(to_tsvector('english', city));

-- ===================================
-- 3. USER PROFILES TABLE (UNIFIED)
-- ===================================

CREATE TABLE user_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    user_type TEXT NOT NULL CHECK (user_type IN ('dj', 'host', 'guest')),
    email TEXT NOT NULL,
    profile_picture_url TEXT DEFAULT '',
    notification_preferences JSONB DEFAULT '{"booking_updates": true, "messages": true, "promotions": false, "events": true}',
    privacy_settings JSONB DEFAULT '{"profile_visible": true, "contact_info_visible": false, "activity_visible": true}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add indexes for user_profiles
CREATE UNIQUE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_user_profiles_type ON user_profiles(user_type);

-- ===================================
-- 4. ROW LEVEL SECURITY POLICIES
-- ===================================

-- Enable RLS on all tables
ALTER TABLE hosts ENABLE ROW LEVEL SECURITY;
ALTER TABLE guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- HOSTS POLICIES
CREATE POLICY "Hosts can view own profile" ON hosts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Hosts can update own profile" ON hosts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Hosts can insert own profile" ON hosts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Anyone can view verified hosts" ON hosts
    FOR SELECT USING (is_verified = true);

-- GUESTS POLICIES
CREATE POLICY "Guests can view own profile" ON guests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Guests can update own profile" ON guests
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Guests can insert own profile" ON guests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- USER_PROFILES POLICIES
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ===================================
-- 5. FUNCTIONS & TRIGGERS
-- ===================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for updated_at
CREATE TRIGGER update_hosts_updated_at
    BEFORE UPDATE ON hosts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_guests_updated_at
    BEFORE UPDATE ON guests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically create user_profile when user signs up
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (user_id, user_type, email)
    VALUES (NEW.id, 'guest', NEW.email); -- Default to guest, can be updated later
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create user profile on signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_user_profile();

-- ===================================
-- 6. SAMPLE DATA (OPTIONAL)
-- ===================================

-- Sample host profiles for testing
-- INSERT INTO hosts (user_id, first_name, last_name, company_name, city, preferred_genres, typical_event_types, typical_budget_range)
-- VALUES 
--     (gen_random_uuid(), 'Sarah', 'Johnson', 'Elite Events Co.', 'Los Angeles', ARRAY['Electronic', 'Hip-Hop'], ARRAY['corporate', 'nightclub'], '$1000-2500'),
--     (gen_random_uuid(), 'Michael', 'Chen', 'Chen Celebrations', 'San Francisco', ARRAY['Pop', 'R&B'], ARRAY['wedding', 'birthday'], '$500-1000'); 