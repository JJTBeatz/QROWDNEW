-- 🪩 QROWD PRO Subscription Database Setup
-- Copy and paste this script into your Supabase SQL Editor

-- 1. Add PRO subscription columns to DJs table
ALTER TABLE djs ADD COLUMN IF NOT EXISTS is_pro BOOLEAN DEFAULT false;
ALTER TABLE djs ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT DEFAULT '';
ALTER TABLE djs ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'inactive';
ALTER TABLE djs ADD COLUMN IF NOT EXISTS subscription_period_end TIMESTAMP WITH TIME ZONE;
ALTER TABLE djs ADD COLUMN IF NOT EXISTS pro_features_enabled JSONB DEFAULT '{"verified_badge": false, "auto_chat_replies": false, "booking_analytics": false, "scheduled_boosts": false, "priority_search": false}';
ALTER TABLE djs ADD COLUMN IF NOT EXISTS last_boost_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE djs ADD COLUMN IF NOT EXISTS boost_credits INTEGER DEFAULT 0;

-- 2. Add constraint for subscription status (drop first if exists to avoid conflicts)
DO $$ 
BEGIN
    -- Drop constraint if it exists
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'check_subscription_status' 
               AND table_name = 'djs') THEN
        ALTER TABLE djs DROP CONSTRAINT check_subscription_status;
    END IF;
    
    -- Add the constraint
    ALTER TABLE djs ADD CONSTRAINT check_subscription_status 
        CHECK (subscription_status IN ('active', 'inactive', 'past_due', 'canceled', 'unpaid'));
END $$;

-- 3. Create index for PRO DJs (for priority search)
CREATE INDEX IF NOT EXISTS idx_djs_pro_priority ON djs(is_pro DESC, rating DESC);

-- 4. Create function to reset boost credits monthly (for PRO DJs)
CREATE OR REPLACE FUNCTION reset_monthly_boost_credits()
RETURNS void AS $$
BEGIN
    UPDATE djs 
    SET boost_credits = 5
    WHERE is_pro = true 
    AND subscription_status = 'active';
END;
$$ LANGUAGE plpgsql;

-- 5. Create function to check and update expired subscriptions
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

-- 6. Create Stripe webhook events table (for handling subscription updates)
CREATE TABLE IF NOT EXISTS stripe_webhook_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    stripe_event_id TEXT UNIQUE NOT NULL,
    event_type TEXT NOT NULL,
    processed BOOLEAN DEFAULT false,
    data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 7. Create index for webhook events
CREATE INDEX IF NOT EXISTS idx_stripe_webhook_events_processed ON stripe_webhook_events(processed);
CREATE INDEX IF NOT EXISTS idx_stripe_webhook_events_type ON stripe_webhook_events(event_type);

-- 8. Enable RLS for webhook events
ALTER TABLE stripe_webhook_events ENABLE ROW LEVEL SECURITY;

-- 9. Create policy for webhook events (only system can access)
CREATE POLICY "System only access to webhook events" ON stripe_webhook_events
    FOR ALL USING (false); -- This will be handled by service role

-- 10. Create function to handle subscription webhook events
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

-- 11. Create sample PRO DJ for testing (optional - uncomment to use)
-- UPDATE djs 
-- SET 
--     is_pro = true,
--     subscription_status = 'active',
--     subscription_period_end = NOW() + INTERVAL '1 month',
--     pro_features_enabled = '{"verified_badge": true, "auto_chat_replies": true, "booking_analytics": true, "scheduled_boosts": true, "priority_search": true}',
--     boost_credits = 5
-- WHERE stage_name = 'Your Test DJ Name';

COMMENT ON TABLE djs IS 'DJs table with PRO subscription support';
COMMENT ON COLUMN djs.is_pro IS 'Whether the DJ has an active PRO subscription';
COMMENT ON COLUMN djs.stripe_subscription_id IS 'Stripe subscription ID for PRO plan';
COMMENT ON COLUMN djs.subscription_status IS 'Current subscription status from Stripe';
COMMENT ON COLUMN djs.subscription_period_end IS 'When the current subscription period ends';
COMMENT ON COLUMN djs.pro_features_enabled IS 'JSON object tracking which PRO features are enabled';
COMMENT ON COLUMN djs.boost_credits IS 'Number of profile boost credits available';
COMMENT ON COLUMN djs.last_boost_date IS 'When the DJ last used a boost credit';

-- ✅ Setup Complete!
-- 
-- Next Steps:
-- 1. Update your Stripe Price ID in StripeManager.swift (line with "price_pro_monthly")
-- 2. Set up Stripe webhooks to call handle_subscription_webhook function
-- 3. Test the PRO upgrade flow in your app ($14.99/month)
-- 4. Run reset_monthly_boost_credits() function monthly (via cron job or Edge Function) 