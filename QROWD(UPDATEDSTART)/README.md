# QROWD App - Complete Flow Documentation

## 🎯 DJ Profile Setup Flow (Core Implementation)

### **Authentication & Onboarding Flow**

1. **App Launch** → `QROWD_UPDATEDSTART_App.swift`
   - Shows splash screen
   - Checks authentication status with Supabase
   - Routes to appropriate flow

2. **User Type Selection** → `UserTypeSelectionView.swift`
   - User chooses: DJ, Host, or Guest
   - If DJ or Host selected → Authentication required
   - If Guest → Direct access to browsing

3. **Authentication** → `AuthView.swift`
   - Sign up or Sign in with email/password
   - Calls `SupabaseManager.signIn()` or `SupabaseManager.signUp()`
   - On success → Sets user as authenticated

4. **DJ Profile Check** → `checkDJProfileStatus()` in Main App
   - **AUTOMATICALLY TRIGGERED** when DJ user authenticates
   - Calls `SupabaseManager.checkDJProfileExists(userId)`
   - If profile doesn't exist → Forces DJ Registration Wizard
   - If profile exists → Goes to DJ Dashboard

### **DJ Profile Setup Wizard** → `DJRegistrationWizardView.swift`

**8-Step Profile Creation Process:**

1. **Basic Info** (`DJBasicInfoView.swift`)
   - Stage name ✅
   - City ✅
   
2. **Budget Range** (`DJBudgetView.swift`)
   - Minimum budget ✅
   - Maximum budget ✅
   
3. **Genres & Culture** (`DJGenreView.swift`)
   - Music genres ✅
   - Cultural preferences ✅
   
4. **Equipment** (`DJEquipmentView.swift`)
   - Available equipment list ✅
   
5. **Promo Media** (`DJPromoView.swift`)
   - Audio promo upload (optional)
   - Video promo upload (optional)
   
6. **Availability** (`DJAvailabilityView.swift`)
   - Weekly schedule ✅
   - Time slots ✅
   
7. **Social Links** (`DJSocialLinksView.swift`)
   - Instagram handle (optional)
   - SoundCloud URL (optional)
   
8. **Stripe Connect** (`DJStripeView.swift`)
   - Payment setup (optional for now)

**Profile Completion Logic:**
- **Required Steps:** 1, 2, 3, 4, 6 (marked with ✅)
- **Optional Steps:** 5, 7, 8
- Profile saves to database on completion
- User redirected to DJ Dashboard

### **Post-Authentication Experience**

#### **For DJs** → `DJDashboardViewWithAI.swift`
- **Dashboard Features:**
  - Welcome header with stage name & rating
  - PRO badge if applicable
  - Quick stats (bookings, earnings)
  - Recent bookings list
  - Profile completion prompt (if incomplete)
  - Settings access
  - Floating AI assistant button

#### **For Hosts** → `HostSearchViewWithAI.swift`
- DJ search and filtering
- DJ profile viewing
- Booking requests
- Chat system

#### **For Guests**
- Browse DJs and events
- View public content
- Limited interaction

### **Key Integrations**

#### **Supabase Backend** → `SupabaseManager.swift`
- Authentication handling
- DJ profile CRUD operations
- Profile existence checking
- File uploads for promo media
- Chat and booking management

#### **Database Schema** → `complete_database_setup.sql`
- Complete table structure with PRO subscription support
- Row Level Security (RLS) policies
- Indexes for performance
- Constraints for data integrity

#### **AI Assistant Integration**
- Context-aware suggestions
- Profile optimization tips
- Booking management assistance

## 🔄 **Critical User Flows**

### **New DJ User Journey:**
1. Select "I'm a DJ" → Authentication → **FORCED Profile Setup** → Dashboard
2. **Cannot access main app until profile is complete**
3. Profile completion tracked and enforced

### **Returning DJ User Journey:**
1. Authentication → Profile check → Dashboard (if complete) OR Profile setup (if incomplete)

### **Profile Management:**
- Edit profile via Dashboard → Settings
- Profile completion status tracked
- PRO subscription features integrated

## 🛠 **Technical Implementation**

### **State Management:**
- `@StateObject` for ViewModels
- `@Published` properties for reactive UI
- `@State` for local component state

### **Navigation:**
- Sheet presentations for modal flows
- NavigationView structure
- Programmatic navigation control

### **Data Flow:**
- SupabaseManager as single source of truth
- Real-time data synchronization
- Error handling with user feedback

### **Security:**
- Row Level Security on all tables
- User-specific data access
- Authentication state management

## 🎯 **Key Features Implemented**

✅ **Forced DJ Profile Setup on First Login**
✅ **Complete 8-Step Registration Wizard**
✅ **Profile Completion Tracking**
✅ **Dashboard with Real DJ Data**
✅ **PRO Subscription Support**
✅ **AI Assistant Integration**
✅ **Comprehensive Database Schema**
✅ **Authentication Flow**
✅ **File Upload for Media**
✅ **Chat System**
✅ **Booking Management**

## 🔧 **Setup Instructions**

1. **Database Setup:**
   ```sql
   -- Run complete_database_setup.sql in Supabase SQL Editor
   ```

2. **Supabase Configuration:**
   - Update URL and API key in `SupabaseManager.swift`
   - Configure storage buckets for media uploads

3. **Stripe Integration:**
   - Add Stripe keys for payment processing
   - Configure webhook endpoints

4. **Build & Run:**
   - Open project in Xcode
   - Install dependencies (already configured)
   - Run on simulator or device

## 📱 **User Experience**

The app now provides a **seamless, enforced onboarding flow** for DJs:
- No way to skip profile setup
- Progressive disclosure of information
- Clear progress indicators
- Immediate value delivery post-completion

**Result:** Every DJ user will have a complete, high-quality profile ready for bookings immediately after onboarding.

## 💰 **PRO Subscription Pricing**

- **QROWD PRO for DJs**: $14.99/month
- **Features**: Verified badge, priority search, analytics, auto-chat replies, 5 monthly boosts
- **Billing**: Monthly recurring, cancel anytime 