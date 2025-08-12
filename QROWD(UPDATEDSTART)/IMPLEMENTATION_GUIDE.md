# 🪩 Trending Public Events + Ticket Booking Implementation Guide

This guide will help you complete the implementation of the trending events feature with Stripe ticket booking.

## ✅ What's Already Implemented

- **Database Schema**: Events and user_tickets tables with all necessary fields
- **Data Models**: Complete event data models and API methods in SupabaseManager
- **UI Components**: 
  - Updated HostSearchView with "Trending Tonight" section
  - TrendingEventCard components with event details
  - EventDetailView with ticket booking interface
  - Skeleton loading states and shimmer effects
- **Stripe Integration**: StripeManager with payment processing and Connect support
- **Notifications**: NotificationManager for host notifications
- **Mock Data**: Sample trending events for demo purposes

## 🚀 Next Steps to Complete Implementation

### 1. Add Stripe SDK to Your Project

#### Option A: Using Swift Package Manager (Recommended)
1. In Xcode, go to `File → Add Package Dependencies`
2. Add these URLs:
   ```
   https://github.com/stripe/stripe-ios
   https://github.com/stripe/stripe-ios-spm
   ```
3. Select the following products:
   - `Stripe`
   - `StripePaymentSheet`

#### Option B: Using CocoaPods
Add to your `Podfile`:
```ruby
pod 'Stripe'
pod 'StripePaymentSheet'
```

### 2. Update Your Stripe Keys

In `StripeManager.swift`, replace the placeholder keys:
```swift
private let publishableKey = "pk_live_..." // Your actual publishable key
private let secretKey = "sk_live_..." // Your actual secret key (use securely!)
```

**⚠️ Security Note**: Never commit secret keys to version control. Use environment variables or a secure configuration system.

### 3. Set Up Database Tables

Run the SQL commands from `DATABASE_SCHEMA.md` in your Supabase SQL Editor:

```sql
-- Events table
CREATE TABLE events (...);

-- User tickets table  
CREATE TABLE user_tickets (...);

-- All the indexes, RLS policies, functions, and triggers
```

### 4. Configure Notification Permissions

Add to your main App file (`QROWD_UPDATEDSTART_App.swift`):

```swift
import UserNotifications

@main
struct QROWD_UPDATEDSTART_App: App {
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some Scene {
        WindowGroup {
            // Your existing content
        }
        .onAppear {
            UNUserNotificationCenter.current().delegate = notificationManager
            Task {
                await notificationManager.requestPermission()
            }
        }
    }
}
```

### 5. Add Missing UI Components

You'll need to create these components (referenced but not yet implemented):

#### QROWDTextField
```swift
struct QROWDTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(QROWDTheme.secondaryText)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(QROWDTheme.primaryText)
        }
        .padding()
        .background(QROWDTheme.cardBackground)
        .cornerRadius(12)
    }
}
```

#### QROWDButton
```swift
struct QROWDButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(title)
                    .font(QROWDTheme.headlineFont)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? QROWDTheme.accentColor : QROWDTheme.secondaryText)
            .cornerRadius(12)
        }
        .disabled(!isEnabled || isLoading)
    }
}
```

#### QuickFilterButton
```swift
struct QuickFilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(QROWDTheme.captionFont)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? QROWDTheme.accentColor : QROWDTheme.cardBackground)
            .foregroundColor(isSelected ? .white : QROWDTheme.primaryText)
            .cornerRadius(20)
        }
    }
}
```

### 6. Update HostSearchViewModel

You'll need to ensure `HostSearchViewModel` exists with these properties:
```swift
@MainActor
class HostSearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var djCards: [DJCard] = []
    @Published var isLoading = false
    @Published var filters = DJSearchFilters()
    @Published var selectedDJ: DJCard?
    
    func searchDJs() async {
        // Your existing DJ search implementation
    }
}
```

### 7. Set Up Stripe Connect for Hosts

For hosts to receive payouts, implement Stripe Connect:

```swift
// In your host onboarding flow
func setupStripeConnect(for hostId: String, email: String) async {
    do {
        let accountId = try await StripeManager.shared.createConnectAccount(
            for: hostId,
            email: email
        )
        
        let onboardingLink = try await StripeManager.shared.createAccountLink(
            accountId: accountId,
            refreshURL: "yourapp://stripe-refresh",
            returnURL: "yourapp://stripe-return"
        )
        
        // Open onboarding link in web view or Safari
    } catch {
        print("Failed to setup Stripe Connect: \(error)")
    }
}
```

### 8. Handle Webhook Events

Set up Stripe webhooks to handle payment confirmations:

```swift
// In your backend or Edge Function
func handleStripeWebhook(_ event: StripeEvent) {
    switch event.type {
    case "payment_intent.succeeded":
        // Update ticket status to "paid"
        // Notify host
        // Send confirmation email
        break
    case "payment_intent.payment_failed":
        // Update ticket status to "failed"
        // Notify user
        break
    }
}
```

### 9. Test the Implementation

1. **Create Test Events**: Add some events to your database
2. **Test Payment Flow**: Use Stripe test cards (4242 4242 4242 4242)
3. **Test Notifications**: Verify host notifications work
4. **Test Edge Cases**: Handle sold out events, payment failures, etc.

## 💡 Advanced Features to Add Later

### Real-time Updates
- Use Supabase Realtime to update ticket availability
- Show live ticket sales to hosts

### Analytics Dashboard
- Track ticket sales metrics
- Popular events and DJs
- Revenue analytics for hosts

### Enhanced Notifications
- Email confirmations
- SMS reminders
- Push notifications with deep linking

### Social Features
- Share events to social media
- Friend invitations
- Event check-ins with QR codes

## 🐛 Troubleshooting

### Common Issues

1. **Stripe Keys Not Working**
   - Ensure you're using the correct environment (test/live)
   - Check key format (starts with pk_ or sk_)

2. **Database Connection Issues**
   - Verify Supabase URL and anon key
   - Check RLS policies are correctly set

3. **Notifications Not Showing**
   - Ensure notification permissions are granted
   - Check notification settings on device

4. **UI Components Missing**
   - Implement the missing QROWDTheme components
   - Add proper color and font definitions

## 📞 Support

If you encounter issues:
1. Check the console for error messages
2. Verify all dependencies are properly installed
3. Test with Stripe's test environment first
4. Use Supabase's built-in debugging tools

Good luck with your implementation! 🚀 