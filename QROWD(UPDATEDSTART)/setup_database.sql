-- 🪩 QROWD Events & Tickets Database Setup
-- Copy and paste this entire script into your Supabase SQL Editor

-- 1. Create events table
CREATE TABLE IF NOT EXISTS events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    host_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    dj_id UUID REFERENCES djs(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    thumbnail_url TEXT DEFAULT '',
    event_date TIMESTAMP WITH TIME ZONE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME,
    location TEXT NOT NULL,
    venue_name TEXT DEFAULT '',
    ticket_price DECIMAL(10,2) NOT NULL,
    total_capacity INTEGER NOT NULL,
    available_tickets INTEGER NOT NULL,
    is_public BOOLEAN DEFAULT true,
    is_trending BOOLEAN DEFAULT false,
    stripe_price_id TEXT,
    platform_fee_percentage DECIMAL(5,2) DEFAULT 10.00,
    host_stripe_account_id TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'sold_out', 'cancelled', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2. Create user_tickets table
CREATE TABLE IF NOT EXISTS user_tickets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    ticket_quantity INTEGER NOT NULL DEFAULT 1,
    total_amount DECIMAL(10,2) NOT NULL,
    platform_fee DECIMAL(10,2) NOT NULL,
    host_payout DECIMAL(10,2) NOT NULL,
    stripe_payment_intent_id TEXT NOT NULL,
    stripe_checkout_session_id TEXT,
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded', 'failed')),
    ticket_code TEXT UNIQUE NOT NULL DEFAULT ('QROWD-' || UPPER(SUBSTRING(gen_random_uuid()::TEXT, 1, 8))),
    checked_in BOOLEAN DEFAULT false,
    check_in_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 3. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_events_public ON events(is_public);
CREATE INDEX IF NOT EXISTS idx_events_trending ON events(is_trending);
CREATE INDEX IF NOT EXISTS idx_events_event_date ON events(event_date);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_user_tickets_user_id ON user_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_user_tickets_event_id ON user_tickets(event_id);
CREATE INDEX IF NOT EXISTS idx_user_tickets_payment_status ON user_tickets(payment_status);

-- 4. Enable RLS (Row Level Security)
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tickets ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies for events
CREATE POLICY "Anyone can view public events" ON events
    FOR SELECT USING (is_public = true AND status = 'active');

CREATE POLICY "Hosts can create events" ON events
    FOR INSERT WITH CHECK (auth.uid() = host_id);

CREATE POLICY "Hosts can update own events" ON events
    FOR UPDATE USING (auth.uid() = host_id);

CREATE POLICY "Hosts can view own events" ON events
    FOR SELECT USING (auth.uid() = host_id);

-- 6. Create RLS policies for user_tickets
CREATE POLICY "Users can view own tickets" ON user_tickets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tickets" ON user_tickets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Hosts can view event tickets" ON user_tickets
    FOR SELECT USING (
        event_id IN (
            SELECT id FROM events WHERE host_id = auth.uid()
        )
    );

-- 7. Create function to update available tickets
CREATE OR REPLACE FUNCTION update_event_capacity()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.payment_status = 'paid' THEN
        UPDATE events 
        SET available_tickets = available_tickets - NEW.ticket_quantity,
            status = CASE 
                WHEN available_tickets - NEW.ticket_quantity <= 0 THEN 'sold_out'
                ELSE status 
            END
        WHERE id = NEW.event_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.payment_status != 'paid' AND NEW.payment_status = 'paid' THEN
        UPDATE events 
        SET available_tickets = available_tickets - NEW.ticket_quantity,
            status = CASE 
                WHEN available_tickets - NEW.ticket_quantity <= 0 THEN 'sold_out'
                ELSE status 
            END
        WHERE id = NEW.event_id;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 8. Create trigger for capacity updates
DROP TRIGGER IF EXISTS update_event_capacity_trigger ON user_tickets;
CREATE TRIGGER update_event_capacity_trigger 
    AFTER INSERT OR UPDATE ON user_tickets
    FOR EACH ROW EXECUTE PROCEDURE update_event_capacity();

-- 9. Create function for trending events
CREATE OR REPLACE FUNCTION get_trending_events(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    event_id UUID,
    title TEXT,
    thumbnail_url TEXT,
    event_date TIMESTAMP WITH TIME ZONE,
    start_time TIME,
    location TEXT,
    venue_name TEXT,
    ticket_price DECIMAL(10,2),
    available_tickets INTEGER,
    dj_stage_name TEXT,
    recent_sales_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.id,
        e.title,
        e.thumbnail_url,
        e.event_date,
        e.start_time,
        e.location,
        e.venue_name,
        e.ticket_price,
        e.available_tickets,
        d.stage_name,
        COALESCE(recent_sales.sales_count, 0) as recent_sales_count
    FROM events e
    LEFT JOIN djs d ON e.dj_id = d.id
    LEFT JOIN (
        SELECT 
            event_id,
            COUNT(*) as sales_count
        FROM user_tickets 
        WHERE payment_status = 'paid' 
        AND created_at >= NOW() - INTERVAL '24 hours'
        GROUP BY event_id
    ) recent_sales ON e.id = recent_sales.event_id
    WHERE e.is_public = true 
    AND e.status = 'active'
    AND e.event_date >= NOW()
    ORDER BY 
        e.is_trending DESC,
        recent_sales_count DESC,
        e.event_date ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 10. Insert sample events for testing
INSERT INTO events (
    host_id, title, description, thumbnail_url, event_date, start_time, 
    location, venue_name, ticket_price, total_capacity, available_tickets, is_trending
) VALUES
(
    (SELECT id FROM auth.users LIMIT 1), -- Uses first user as host
    'Midnight Vibes',
    'An electrifying night of deep house and techno music',
    'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500',
    NOW() + INTERVAL '1 day',
    '23:00',
    'Los Angeles, CA',
    'Skybar Rooftop',
    45.00,
    150,
    123,
    true
),
(
    (SELECT id FROM auth.users LIMIT 1),
    'House Music Revival',
    'Classic house beats with modern twists',
    'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500',
    NOW() + INTERVAL '2 days',
    '22:30',
    'Miami, FL',
    'Electric Paradise',
    65.00,
    200,
    87,
    true
),
(
    (SELECT id FROM auth.users LIMIT 1),
    'Latin Nights',
    'Spicy rhythms and dancing until dawn',
    'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=500',
    NOW() + INTERVAL '3 days',
    '21:00',
    'Austin, TX',
    'Salsa Club Downtown',
    35.00,
    100,
    78,
    false
);

-- ✅ Setup Complete!
-- Your events and tickets tables are now ready.
-- Next: Add your Stripe keys and test the app! 