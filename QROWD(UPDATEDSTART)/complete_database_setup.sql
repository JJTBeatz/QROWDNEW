-- 🪩 QROWD Complete Database Setup with PRO Subscription
-- Copy and paste this script into your Supabase SQL Editor

-- 1. Create DJs table with PRO subscription fields
CREATE TABLE IF NOT EXISTS djs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    stage_name TEXT NOT NULL,
    city TEXT NOT NULL,
    budget_min DECIMAL(10,2) NOT NULL,
    budget_max DECIMAL(10,2) NOT NULL,
    genres TEXT[] DEFAULT '{}',
    cultures TEXT[] DEFAULT '{}',
    equipment TEXT[] DEFAULT '{}',
    promo_media_urls TEXT[] DEFAULT '{}',
    availability JSONB DEFAULT '{}',
    instagram_handle TEXT DEFAULT '',
    soundcloud_url TEXT DEFAULT '',
    stripe_account_id TEXT DEFAULT '',
    is_available BOOLEAN DEFAULT true,
    rating DECIMAL(3,2) DEFAULT 5.0,
    total_bookings INTEGER DEFAULT 0,
    -- PRO Subscription Fields
    is_pro BOOLEAN DEFAULT false,
    stripe_subscription_id TEXT DEFAULT '',
    subscription_status TEXT DEFAULT 'inactive',
    subscription_period_end TIMESTAMP WITH TIME ZONE,
    pro_features_enabled JSONB DEFAULT '{"verified_badge": false, "auto_chat_replies": false, "booking_analytics": false, "scheduled_boosts": false, "priority_search": false}',
    last_boost_date TIMESTAMP WITH TIME ZONE,
    boost_credits INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2. Add constraint for subscription status
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'check_subscription_status' 
                   AND table_name = 'djs') THEN
        ALTER TABLE djs ADD CONSTRAINT check_subscription_status 
            CHECK (subscription_status IN ('active', 'inactive', 'past_due', 'canceled', 'unpaid'));
    END IF;
END $$;

-- 3. Create indexes for DJs table
CREATE INDEX IF NOT EXISTS idx_djs_city ON djs USING gin(to_tsvector('english', city));
CREATE INDEX IF NOT EXISTS idx_djs_genres ON djs USING gin(genres);
CREATE INDEX IF NOT EXISTS idx_djs_available ON djs(is_available);
CREATE INDEX IF NOT EXISTS idx_djs_budget ON djs(budget_min, budget_max);
CREATE INDEX IF NOT EXISTS idx_djs_pro_priority ON djs(is_pro DESC, rating DESC);

-- 4. Enable RLS for DJs table
ALTER TABLE djs ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies for DJs
DO $$
BEGIN
    -- Drop existing policies if they exist
    DROP POLICY IF EXISTS "DJs can update own profile" ON djs;
    DROP POLICY IF EXISTS "Anyone can view available DJs" ON djs;
    DROP POLICY IF EXISTS "DJs can insert own profile" ON djs;
    
    -- Create new policies
    CREATE POLICY "DJs can update own profile" ON djs
        FOR UPDATE USING (auth.uid() = user_id);
    
    CREATE POLICY "Anyone can view available DJs" ON djs
        FOR SELECT USING (is_available = true);
    
    CREATE POLICY "DJs can insert own profile" ON djs
        FOR INSERT WITH CHECK (auth.uid() = user_id);
END $$;

-- 6. Create bookings table
CREATE TABLE IF NOT EXISTS bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    host_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    dj_id UUID REFERENCES djs(id) ON DELETE CASCADE,
    event_location TEXT NOT NULL,
    guest_count INTEGER NOT NULL,
    event_date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_hours INTEGER NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status TEXT DEFAULT 'pending',
    special_requests TEXT DEFAULT '',
    payment_status TEXT DEFAULT 'pending',
    stripe_payment_intent_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 7. Add constraints for bookings
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'check_booking_status' 
                   AND table_name = 'bookings') THEN
        ALTER TABLE bookings ADD CONSTRAINT check_booking_status 
            CHECK (status IN ('pending', 'accepted', 'declined', 'completed', 'cancelled'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'check_payment_status' 
                   AND table_name = 'bookings') THEN
        ALTER TABLE bookings ADD CONSTRAINT check_payment_status 
            CHECK (payment_status IN ('pending', 'paid', 'refunded'));
    END IF;
END $$;

-- 8. Create indexes for bookings
CREATE INDEX IF NOT EXISTS idx_bookings_host_id ON bookings(host_id);
CREATE INDEX IF NOT EXISTS idx_bookings_dj_id ON bookings(dj_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_event_date ON bookings(event_date);

-- 9. Enable RLS for bookings
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- 10. Create RLS policies for bookings
DO $$
BEGIN
    DROP POLICY IF EXISTS "Hosts can view own bookings" ON bookings;
    DROP POLICY IF EXISTS "DJs can view own bookings" ON bookings;
    DROP POLICY IF EXISTS "Hosts can create bookings" ON bookings;
    DROP POLICY IF EXISTS "DJs can update booking status" ON bookings;
    
    CREATE POLICY "Hosts can view own bookings" ON bookings
        FOR SELECT USING (auth.uid() = host_id);
    
    CREATE POLICY "DJs can view own bookings" ON bookings
        FOR SELECT USING (auth.uid() IN (
            SELECT user_id FROM djs WHERE id = bookings.dj_id
        ));
    
    CREATE POLICY "Hosts can create bookings" ON bookings
        FOR INSERT WITH CHECK (auth.uid() = host_id);
    
    CREATE POLICY "DJs can update booking status" ON bookings
        FOR UPDATE USING (auth.uid() IN (
            SELECT user_id FROM djs WHERE id = bookings.dj_id
        ));
END $$;

-- 11. Create chats table
CREATE TABLE IF NOT EXISTS chats (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 12. Create indexes for chats
CREATE INDEX IF NOT EXISTS idx_chats_booking_id ON chats(booking_id);

-- 13. Enable RLS for chats
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;

-- 14. Create RLS policies for chats
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can access own booking chats" ON chats;
    
    CREATE POLICY "Users can access own booking chats" ON chats
        FOR ALL USING (
            auth.uid() IN (
                SELECT host_id FROM bookings WHERE id = chats.booking_id
                UNION
                SELECT djs.user_id FROM bookings 
                JOIN djs ON djs.id = bookings.dj_id 
                WHERE bookings.id = chats.booking_id
            )
        );
END $$;

-- 15. Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    message_type TEXT DEFAULT 'text',
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 16. Add constraint for chat_messages
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'check_message_type' 
                   AND table_name = 'chat_messages') THEN
        ALTER TABLE chat_messages ADD CONSTRAINT check_message_type 
            CHECK (message_type IN ('text', 'image', 'file', 'system'));
    END IF;
END $$;

-- 17. Create indexes for chat_messages
CREATE INDEX IF NOT EXISTS idx_chat_messages_chat_id ON chat_messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);

-- 18. Enable RLS for chat_messages
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- 19. Create RLS policies for chat_messages
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view messages in accessible chats" ON chat_messages;
    DROP POLICY IF EXISTS "Users can send messages in accessible chats" ON chat_messages;
    
    CREATE POLICY "Users can view messages in accessible chats" ON chat_messages
        FOR SELECT USING (
            chat_id IN (
                SELECT chats.id FROM chats
                WHERE auth.uid() IN (
                    SELECT host_id FROM bookings WHERE id = chats.booking_id
                    UNION
                    SELECT djs.user_id FROM bookings 
                    JOIN djs ON djs.id = bookings.dj_id 
                    WHERE bookings.id = chats.booking_id
                )
            )
        );
    
    CREATE POLICY "Users can send messages in accessible chats" ON chat_messages
        FOR INSERT WITH CHECK (
            sender_id = auth.uid() AND
            chat_id IN (
                SELECT chats.id FROM chats
                WHERE auth.uid() IN (
                    SELECT host_id FROM bookings WHERE id = chats.booking_id
                    UNION
                    SELECT djs.user_id FROM bookings 
                    JOIN djs ON djs.id = bookings.dj_id 
                    WHERE bookings.id = chats.booking_id
                )
            )
        );
END $$;

-- 20. Create events table (for public events)
CREATE TABLE IF NOT EXISTS events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    host_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    dj_id UUID REFERENCES djs(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    event_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME,
    location TEXT NOT NULL,
    venue_name TEXT DEFAULT '',
    capacity INTEGER NOT NULL,
    tickets_sold INTEGER DEFAULT 0,
    ticket_price DECIMAL(10,2) NOT NULL,
    thumbnail_url TEXT DEFAULT '',
    is_public BOOLEAN DEFAULT true,
    status TEXT DEFAULT 'active',
    stripe_product_id TEXT DEFAULT '',
    platform_fee_percentage DECIMAL(5,2) DEFAULT 10.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 21. Add constraint for events
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'check_event_status' 
                   AND table_name = 'events') THEN
        ALTER TABLE events ADD CONSTRAINT check_event_status 
            CHECK (status IN ('active', 'cancelled', 'completed', 'sold_out'));
    END IF;
END $$;

-- 22. Create indexes for events
CREATE INDEX IF NOT EXISTS idx_events_date ON events(event_date);
CREATE INDEX IF NOT EXISTS idx_events_public ON events(is_public);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);

-- 23. Enable RLS for events
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- 24. Create RLS policies for events
DO $$
BEGIN
    DROP POLICY IF EXISTS "Anyone can view public events" ON events;
    DROP POLICY IF EXISTS "Hosts can manage own events" ON events;
    
    CREATE POLICY "Anyone can view public events" ON events
        FOR SELECT USING (is_public = true AND status = 'active');
    
    CREATE POLICY "Hosts can manage own events" ON events
        FOR ALL USING (auth.uid() = host_id);
END $$;

-- 25. Create user_tickets table
CREATE TABLE IF NOT EXISTS user_tickets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    ticket_quantity INTEGER NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    platform_fee DECIMAL(10,2) NOT NULL,
    payment_status TEXT DEFAULT 'pending',
    stripe_payment_intent_id TEXT DEFAULT '',
    ticket_code TEXT UNIQUE NOT NULL,
    checked_in BOOLEAN DEFAULT false,
    check_in_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 26. Add constraint for user_tickets
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'check_ticket_payment_status' 
                   AND table_name = 'user_tickets') THEN
        ALTER TABLE user_tickets ADD CONSTRAINT check_ticket_payment_status 
            CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded'));
    END IF;
END $$;

-- 27. Create indexes for user_tickets
CREATE INDEX IF NOT EXISTS idx_user_tickets_user_id ON user_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_user_tickets_event_id ON user_tickets(event_id);
CREATE INDEX IF NOT EXISTS idx_user_tickets_code ON user_tickets(ticket_code);

-- 28. Enable RLS for user_tickets
ALTER TABLE user_tickets ENABLE ROW LEVEL SECURITY;

-- 29. Create RLS policies for user_tickets
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view own tickets" ON user_tickets;
    DROP POLICY IF EXISTS "Users can create own tickets" ON user_tickets;
    
    CREATE POLICY "Users can view own tickets" ON user_tickets
        FOR SELECT USING (auth.uid() = user_id);
    
    CREATE POLICY "Users can create own tickets" ON user_tickets
        FOR INSERT WITH CHECK (auth.uid() = user_id);
END $$;

-- 30. Create Stripe webhook events table
CREATE TABLE IF NOT EXISTS stripe_webhook_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    stripe_event_id TEXT UNIQUE NOT NULL,
    event_type TEXT NOT NULL,
    processed BOOLEAN DEFAULT false,
    data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 31. Create indexes for webhook events
CREATE INDEX IF NOT EXISTS idx_stripe_webhook_events_processed ON stripe_webhook_events(processed);
CREATE INDEX IF NOT EXISTS idx_stripe_webhook_events_type ON stripe_webhook_events(event_type);

-- 32. Enable RLS for webhook events
ALTER TABLE stripe_webhook_events ENABLE ROW LEVEL SECURITY;

-- 33. Create policy for webhook events
DO $$
BEGIN
    DROP POLICY IF EXISTS "System only access to webhook events" ON stripe_webhook_events;
    
    CREATE POLICY "System only access to webhook events" ON stripe_webhook_events
        FOR ALL USING (false); -- This will be handled by service role
END $$;

-- 34. Create PRO subscription management functions
CREATE OR REPLACE FUNCTION reset_monthly_boost_credits()
RETURNS void AS $$
BEGIN
    UPDATE djs 
    SET boost_credits = 5
    WHERE is_pro = true 
    AND subscription_status = 'active';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_expired_subscriptions()
RETURNS void AS $$
BEGIN
    UPDATE djs 
    SET 
        is_pro = false,
        subscription_status = 'inactive',
        pro_features_enabled = '{"verified_badge": false, "auto_chat_replies": false, "booking_analytics": false, "scheduled_boosts": false, "priority_search": false}',
        boost_credits = 0
    WHERE subscription_period_end < NOW() 
    AND subscription_status = 'active';
END;
$$ LANGUAGE plpgsql;

-- 35. Create webhook handler function
CREATE OR REPLACE FUNCTION handle_subscription_webhook(
    p_stripe_event_id TEXT,
    p_event_type TEXT,
    p_subscription_id TEXT,
    p_customer_email TEXT,
    p_status TEXT,
    p_current_period_end TIMESTAMP WITH TIME ZONE
)
RETURNS void AS $$
DECLARE
    v_dj_id UUID;
BEGIN
    -- Find DJ by user email
    SELECT d.id INTO v_dj_id
    FROM djs d
    JOIN auth.users u ON d.user_id = u.id
    WHERE u.email = p_customer_email;
    
    IF v_dj_id IS NOT NULL THEN
        -- Update DJ PRO status based on subscription
        IF p_status = 'active' THEN
            UPDATE djs 
            SET 
                is_pro = true,
                stripe_subscription_id = p_subscription_id,
                subscription_status = p_status,
                subscription_period_end = p_current_period_end,
                pro_features_enabled = '{"verified_badge": true, "auto_chat_replies": true, "booking_analytics": true, "scheduled_boosts": true, "priority_search": true}',
                boost_credits = CASE WHEN boost_credits = 0 THEN 5 ELSE boost_credits END
            WHERE id = v_dj_id;
        ELSE
            -- Handle canceled/expired subscriptions
            UPDATE djs 
            SET 
                is_pro = CASE WHEN p_status IN ('canceled', 'unpaid') THEN false ELSE is_pro END,
                subscription_status = p_status,
                subscription_period_end = p_current_period_end,
                pro_features_enabled = CASE 
                    WHEN p_status IN ('canceled', 'unpaid') THEN 
                        '{"verified_badge": false, "auto_chat_replies": false, "booking_analytics": false, "scheduled_boosts": false, "priority_search": false}'
                    ELSE pro_features_enabled 
                END,
                boost_credits = CASE WHEN p_status IN ('canceled', 'unpaid') THEN 0 ELSE boost_credits END
            WHERE id = v_dj_id;
        END IF;
    END IF;
    
    -- Log the webhook event
    INSERT INTO stripe_webhook_events (stripe_event_id, event_type, processed, data)
    VALUES (p_stripe_event_id, p_event_type, true, jsonb_build_object(
        'subscription_id', p_subscription_id,
        'customer_email', p_customer_email,
        'status', p_status,
        'current_period_end', p_current_period_end
    ));
END;
$$ LANGUAGE plpgsql;

-- 36. Create trigger for capacity management
CREATE OR REPLACE FUNCTION update_event_capacity()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.payment_status = 'completed' THEN
        UPDATE events 
        SET tickets_sold = tickets_sold + NEW.ticket_quantity
        WHERE id = NEW.event_id;
        
        -- Check if event is sold out
        UPDATE events 
        SET status = 'sold_out'
        WHERE id = NEW.event_id 
        AND tickets_sold >= capacity;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    DROP TRIGGER IF EXISTS trigger_update_event_capacity ON user_tickets;
    CREATE TRIGGER trigger_update_event_capacity
        AFTER INSERT ON user_tickets
        FOR EACH ROW
        EXECUTE FUNCTION update_event_capacity();
END $$;

-- 37. Create function for trending events
DROP FUNCTION IF EXISTS get_trending_events(INTEGER);

CREATE OR REPLACE FUNCTION get_trending_events(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID,
    title TEXT,
    event_date DATE,
    start_time TIME,
    location TEXT,
    venue_name TEXT,
    ticket_price DECIMAL(10,2),
    tickets_sold INTEGER,
    capacity INTEGER,
    thumbnail_url TEXT,
    dj_stage_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.id,
        e.title,
        e.event_date,
        e.start_time,
        e.location,
        e.venue_name,
        e.ticket_price,
        e.tickets_sold,
        e.capacity,
        e.thumbnail_url,
        d.stage_name as dj_stage_name
    FROM events e
    LEFT JOIN djs d ON e.dj_id = d.id
    WHERE e.is_public = true 
    AND e.status = 'active'
    AND e.event_date >= CURRENT_DATE
    ORDER BY e.tickets_sold DESC, e.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- ✅ Complete Database Setup Finished!
-- All tables, indexes, policies, and functions have been created successfully. 