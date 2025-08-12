# QROWD Supabase Database Schema

This document contains the SQL commands to create all necessary tables for the QROWD app's Host booking flow, real-time chat system, and public events with ticket booking.

## 📋 Table Overview

1. **djs** - DJ profiles and information
2. **bookings** - Booking requests and status
3. **chats** - Chat rooms for bookings
4. **chat_messages** - Individual chat messages
5. **events** - Public events for ticket sales
6. **user_tickets** - User purchased tickets

## 🗃️ SQL Schema

### 1. DJs Table (Enhanced)

```sql
-- Create DJs table
CREATE TABLE djs (
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
    subscription_status TEXT DEFAULT 'inactive' CHECK (subscription_status IN ('active', 'inactive', 'past_due', 'canceled', 'unpaid')),
    subscription_period_end TIMESTAMP WITH TIME ZONE,
    pro_features_enabled JSONB DEFAULT '{"verified_badge": false, "auto_chat_replies": false, "booking_analytics": false, "scheduled_boosts": false, "priority_search": false}',
    last_boost_date TIMESTAMP WITH TIME ZONE,
    boost_credits INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add indexes for search performance
CREATE INDEX idx_djs_city ON djs USING gin(to_tsvector('english', city));
CREATE INDEX idx_djs_genres ON djs USING gin(genres);
CREATE INDEX idx_djs_available ON djs(is_available);
CREATE INDEX idx_djs_budget ON djs(budget_min, budget_max);

-- Add RLS (Row Level Security)
ALTER TABLE djs ENABLE ROW LEVEL SECURITY;

-- DJs can only update their own profiles
CREATE POLICY "DJs can update own profile" ON djs
    FOR UPDATE USING (auth.uid() = user_id);

-- Anyone can view available DJs
CREATE POLICY "Anyone can view available DJs" ON djs
    FOR SELECT USING (is_available = true);

-- DJs can insert their own profile
CREATE POLICY "DJs can insert own profile" ON djs
    FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### 2. Bookings Table

```sql
-- Create bookings table
CREATE TABLE bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    host_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    dj_id UUID REFERENCES djs(id) ON DELETE CASCADE,
    event_location TEXT NOT NULL,
    guest_count INTEGER NOT NULL,
    event_date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_hours INTEGER NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'completed', 'cancelled')),
    special_requests TEXT DEFAULT '',
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded')),
    stripe_payment_intent_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add indexes
CREATE INDEX idx_bookings_host_id ON bookings(host_id);
CREATE INDEX idx_bookings_dj_id ON bookings(dj_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_event_date ON bookings(event_date);

-- Add RLS
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Hosts can view their own bookings
CREATE POLICY "Hosts can view own bookings" ON bookings
    FOR SELECT USING (auth.uid() = host_id);

-- DJs can view bookings for them
CREATE POLICY "DJs can view own bookings" ON bookings
    FOR SELECT USING (auth.uid() IN (
        SELECT user_id FROM djs WHERE id = bookings.dj_id
    ));

-- Hosts can create bookings
CREATE POLICY "Hosts can create bookings" ON bookings
    FOR INSERT WITH CHECK (auth.uid() = host_id);

-- DJs can update booking status
CREATE POLICY "DJs can update booking status" ON bookings
    FOR UPDATE USING (auth.uid() IN (
        SELECT user_id FROM djs WHERE id = bookings.dj_id
    ));
```

### 3. Chats Table

```sql
-- Create chats table
CREATE TABLE chats (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add indexes
CREATE INDEX idx_chats_booking_id ON chats(booking_id);

-- Add RLS
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;

-- Users can access chats for their bookings
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
```

### 4. Chat Messages Table

```sql
-- Create chat_messages table
CREATE TABLE chat_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'system')),
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add indexes
CREATE INDEX idx_chat_messages_chat_id ON chat_messages(chat_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX idx_chat_messages_sender_id ON chat_messages(sender_id);

-- Add RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Users can view messages in chats they have access to
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

-- Users can send messages in chats they have access to
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
```

### 5. Functions and Triggers

```sql
-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_djs_updated_at BEFORE UPDATE ON djs
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_chats_updated_at BEFORE UPDATE ON chats
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Function to automatically create chat when booking is created
CREATE OR REPLACE FUNCTION create_chat_for_booking()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO chats (booking_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to create chat when booking is created
CREATE TRIGGER create_chat_trigger AFTER INSERT ON bookings
    FOR EACH ROW EXECUTE PROCEDURE create_chat_for_booking();

-- Function to update DJ total_bookings when booking is completed
CREATE OR REPLACE FUNCTION update_dj_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        UPDATE djs 
        SET total_bookings = total_bookings + 1 
        WHERE id = NEW.dj_id;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update DJ stats
CREATE TRIGGER update_dj_stats_trigger AFTER UPDATE ON bookings
    FOR EACH ROW EXECUTE PROCEDURE update_dj_stats();
```

### 6. Real-time Subscriptions

```sql
-- Enable real-time for chat messages
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- Enable real-time for bookings (for status updates)
ALTER PUBLICATION supabase_realtime ADD TABLE bookings;
```

### 7. Storage Buckets

```sql
-- Create storage bucket for DJ media (run in Supabase Dashboard Storage section)
-- Bucket name: dj-media
-- Public: true
-- File size limit: 50MB
-- Allowed file types: image/*, video/*, audio/*
```

### 8. Events Table (Public Events)

```sql
-- Create events table for public events
CREATE TABLE events (
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
    stripe_price_id TEXT, -- Stripe Price ID for checkout
    platform_fee_percentage DECIMAL(5,2) DEFAULT 10.00, -- QROWD's platform fee
    host_stripe_account_id TEXT, -- Host's Stripe Connect account
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'sold_out', 'cancelled', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add indexes for events
CREATE INDEX idx_events_public ON events(is_public);
CREATE INDEX idx_events_trending ON events(is_trending);
CREATE INDEX idx_events_event_date ON events(event_date);
CREATE INDEX idx_events_location ON events USING gin(to_tsvector('english', location));
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_host_id ON events(host_id);
CREATE INDEX idx_events_dj_id ON events(dj_id);

-- Add RLS for events
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Anyone can view public events
CREATE POLICY "Anyone can view public events" ON events
    FOR SELECT USING (is_public = true AND status = 'active');

-- Hosts can create events
CREATE POLICY "Hosts can create events" ON events
    FOR INSERT WITH CHECK (auth.uid() = host_id);

-- Hosts can update their own events
CREATE POLICY "Hosts can update own events" ON events
    FOR UPDATE USING (auth.uid() = host_id);

-- Hosts can view their own events (including private ones)
CREATE POLICY "Hosts can view own events" ON events
    FOR SELECT USING (auth.uid() = host_id);
```

### 9. User Tickets Table

```sql
-- Create user_tickets table for purchased tickets
CREATE TABLE user_tickets (
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
    ticket_code TEXT UNIQUE NOT NULL, -- Unique QR code for entry
    checked_in BOOLEAN DEFAULT false,
    check_in_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add indexes for user_tickets
CREATE INDEX idx_user_tickets_user_id ON user_tickets(user_id);
CREATE INDEX idx_user_tickets_event_id ON user_tickets(event_id);
CREATE INDEX idx_user_tickets_payment_status ON user_tickets(payment_status);
CREATE INDEX idx_user_tickets_ticket_code ON user_tickets(ticket_code);

-- Add RLS for user_tickets
ALTER TABLE user_tickets ENABLE ROW LEVEL SECURITY;

-- Users can view their own tickets
CREATE POLICY "Users can view own tickets" ON user_tickets
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own tickets (after payment)
CREATE POLICY "Users can insert own tickets" ON user_tickets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Event hosts can view tickets for their events
CREATE POLICY "Hosts can view event tickets" ON user_tickets
    FOR SELECT USING (
        event_id IN (
            SELECT id FROM events WHERE host_id = auth.uid()
        )
    );

-- Event hosts can update check-in status
CREATE POLICY "Hosts can update ticket check-in" ON user_tickets
    FOR UPDATE USING (
        event_id IN (
            SELECT id FROM events WHERE host_id = auth.uid()
        )
    );
```

### 10. Event-Related Functions and Triggers

```sql
-- Function to generate unique ticket codes
CREATE OR REPLACE FUNCTION generate_ticket_code()
RETURNS TEXT AS $$
BEGIN
    RETURN 'QROWD-' || UPPER(SUBSTRING(gen_random_uuid()::TEXT, 1, 8));
END;
$$ LANGUAGE plpgsql;

-- Function to update available tickets when ticket is purchased
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
    ELSIF TG_OP = 'UPDATE' AND OLD.payment_status = 'paid' AND NEW.payment_status = 'refunded' THEN
        UPDATE events 
        SET available_tickets = available_tickets + OLD.ticket_quantity,
            status = CASE 
                WHEN status = 'sold_out' THEN 'active'
                ELSE status 
            END
        WHERE id = NEW.event_id;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Add triggers for events
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_user_tickets_updated_at BEFORE UPDATE ON user_tickets
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Trigger to update event capacity
CREATE TRIGGER update_event_capacity_trigger 
    AFTER INSERT OR UPDATE ON user_tickets
    FOR EACH ROW EXECUTE PROCEDURE update_event_capacity();

-- Trigger to generate ticket codes
CREATE TRIGGER generate_ticket_code_trigger 
    BEFORE INSERT ON user_tickets
    FOR EACH ROW EXECUTE PROCEDURE 
    (SELECT CASE WHEN NEW.ticket_code IS NULL THEN generate_ticket_code() ELSE NEW.ticket_code END);

-- Function to get trending events (events with most recent ticket sales)
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
```

## 🔧 Setup Instructions

1. **Create Tables**: Run the SQL commands above in your Supabase SQL Editor in order
2. **Set up Storage**: Create the `dj-media` bucket in the Storage section
3. **Configure RLS**: The Row Level Security policies are included above
4. **Test Real-time**: Enable real-time for `chat_messages` and `bookings` tables

## 🔍 Key Features

- **Full CRUD operations** for DJs, bookings, and chat
- **Real-time chat** using Supabase Realtime
- **Search and filtering** with optimized indexes
- **Row Level Security** for data protection
- **Automatic chat creation** for new bookings
- **DJ statistics tracking** for completed bookings
- **File storage** for promo media
- **Public events** for ticket sales
- **User tickets** for purchased tickets

## 📱 App Integration

The iOS app uses these tables through the `SupabaseManager` class which provides:

- `searchDJs(filters:)` - Search DJs with filters
- `getDJProfile(djId:)` - Get detailed DJ profile
- `createBooking(_:)` - Create new booking request
- `getChatMessages(chatId:)` - Get chat messages
- `sendMessage(chatId:text:)` - Send new message
- `subscribeToChatMessages(chatId:)` - Real-time message subscription

## 🚀 Future Enhancements

- **Push notifications** using Supabase Edge Functions
- **Payment processing** with Stripe webhooks
- **Reviews and ratings** system
- **Advanced search** with geolocation
- **DJ calendar integration**
- **Automatic pricing** based on demand

## 🧠 AI Assistant Integration

### 8. AI Queries Table

```sql
-- AI Queries Table for Analytics
CREATE TABLE ai_queries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    query TEXT NOT NULL,
    intent TEXT, -- dj_search, venue_search, event_search, trending, general
    response_generated BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for AI queries
CREATE INDEX idx_ai_queries_user_id ON ai_queries(user_id);
CREATE INDEX idx_ai_queries_created_at ON ai_queries(created_at);
CREATE INDEX idx_ai_queries_intent ON ai_queries(intent);

-- RLS for AI queries
ALTER TABLE ai_queries ENABLE ROW LEVEL SECURITY;

-- Users can only see their own AI queries
CREATE POLICY "Users can view own AI queries" ON ai_queries
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own AI queries
CREATE POLICY "Users can insert own AI queries" ON ai_queries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Analytics view for admins (optional)
CREATE VIEW ai_query_analytics AS
SELECT 
    intent,
    COUNT(*) as query_count,
    COUNT(DISTINCT user_id) as unique_users,
    DATE_TRUNC('day', created_at) as query_date
FROM ai_queries 
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY intent, DATE_TRUNC('day', created_at)
ORDER BY query_date DESC, query_count DESC;
```

### 9. AI Assistant Setup

**Features:**
- **Query Analytics**: Track user interactions and popular requests
- **Intent Classification**: Categorize queries for better responses
- **GPT Integration**: Uses OpenAI API for intelligent responses
- **Contextual Recommendations**: Provides DJ/venue suggestions based on data
- **Smart Suggestions**: Offers follow-up questions and actions

**Usage in App:**
- Dedicated AI tab in main navigation
- Floating AI button on search screens
- Natural language DJ/venue search
- Trending insights and recommendations
- 24/7 intelligent assistance for users