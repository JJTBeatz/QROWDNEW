# QROWD - DJ & Event Booking Platform 🎵

A SwiftUI app for connecting DJs with event hosts, featuring a dark nightclub aesthetic and comprehensive onboarding flow.

## 🖤 Dark Nightclub Theme

**Colors & Gradients:**
- Background: `#0B0B0E` 
- Primary Gradient: `#E35AFF → #A35CFE → #577CFF`
- Accent: `#BE6CFF`
- Text: White `#FFFFFF`, Secondary `#CCCCCC`
- Borders: `#1A1A1A` or translucent white

**Design Elements:**
- **Cards**: 20+ corner radius with pinkish/purple/blue glow shadows
- **Fonts**: Inter or SF Pro Display
- **Layout**: Uber-style padding with large tappable areas
- **Animations**: Soft slide-in, fade transitions, glow effects

## 🚀 Features

### ✅ Completed Features

1. **🎨 Dark Nightclub Theme System**
   - Centralized theme configuration in `Theme.swift`
   - Consistent colors, gradients, and styling
   - Custom UI components with nightclub aesthetics

2. **📱 Onboarding Flow**
   - **SplashView**: Animated logo with gradient sweep
   - **UserTypeSelectionView**: Choose DJ, Host, or Guest
   - **AuthView**: Email/password authentication with Supabase

3. **🎛 DJ Registration Wizard (8 Steps)**
   - **Step 1**: DJ/Stage Name + City (with auto-suggest)
   - **Step 2**: Budget range slider ($50-$5000)
   - **Step 3**: Genre + Culture multi-select tags
   - **Step 4**: Equipment checkboxes with quick setup options
   - **Step 5**: Audio/Video promo uploads to Supabase Storage
   - **Step 6**: Weekly availability time selector
   - **Step 7**: Instagram + SoundCloud social links
   - **Step 8**: Stripe Connect onboarding for payments

4. **🔧 Technical Architecture**
   - MVVM pattern with `@ObservableObject` view models
   - Supabase integration for auth, database, and storage
   - Modular, reusable UI components
   - Form validation and error handling

## 🛠 Setup Instructions

### 1. Xcode Project Setup

1. Open `QROWD(UPDATEDSTART).xcodeproj` in Xcode
2. Add Supabase Swift dependencies:
   - Go to **File → Add Package Dependencies**
   - Add: `https://github.com/supabase/supabase-swift`
   - Select the latest version

### 2. Supabase Configuration

1. **Create Supabase Project**
   - Go to [supabase.com](https://supabase.com)
   - Create a new project
   - Note your project URL and anon key

2. **Update Configuration**
   ```swift
   // In SupabaseManager.swift, replace:
   private let supabaseURL = "YOUR_SUPABASE_URL"
   private let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
   ```

3. **Database Schema**
   ```sql
   -- DJs table
   CREATE TABLE djs (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     user_id UUID REFERENCES auth.users(id),
     stage_name TEXT NOT NULL,
     city TEXT NOT NULL,
     budget_min INTEGER NOT NULL,
     budget_max INTEGER NOT NULL,
     genres TEXT[] NOT NULL,
     cultures TEXT[],
     equipment TEXT[] NOT NULL,
     audio_promo_url TEXT,
     video_promo_url TEXT,
     availability JSONB,
     instagram_handle TEXT,
     soundcloud_url TEXT,
     stripe_connect_id TEXT,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

4. **Storage Buckets**
   ```sql
   -- Create buckets for media uploads
   INSERT INTO storage.buckets (id, name, public) VALUES ('dj-media', 'dj-media', true);
   ```

### 3. Run the App

1. Build and run in Xcode
2. Experience the full onboarding flow:
   - Splash screen animation
   - User type selection
   - Authentication
   - DJ registration wizard (if DJ selected)

## 📱 App Flow

```
SplashView (3s animation)
    ↓
UserTypeSelectionView
    ↓
AuthView (Email/Password + Social)
    ↓ (if DJ selected)
DJRegistrationWizard
    ├── Step 1: Basic Info
    ├── Step 2: Budget Range
    ├── Step 3: Genres & Culture
    ├── Step 4: Equipment
    ├── Step 5: Promo Media
    ├── Step 6: Availability
    ├── Step 7: Social Links
    └── Step 8: Stripe Connect
        ↓
MainApp (Coming Soon)
```

## 🎨 UI Components

### Custom Components Created
- `QROWDTextField` - Themed text input
- `QROWDSecureField` - Password input with show/hide
- `QROWDButton` - Gradient button with loading states
- `QROWDSecondaryButton` - Outlined button
- `SelectableTag` - Multi-select tags for genres
- `EquipmentCard` - Equipment selection cards
- `MediaUploadCard` - File upload with progress
- `ProgressBarView` - Step progress indicator

### Theme System
All components use the centralized `QROWDTheme` configuration:
- Colors, gradients, typography
- Consistent spacing and corner radius
- Hover/tap animations and glow effects

## 🔮 Next Steps

1. **Complete Supabase Integration**
   - Add Row Level Security policies
   - Implement real-time subscriptions
   - Add file upload progress tracking

2. **Main App Features**
   - DJ discovery and search
   - Event creation and booking
   - In-app messaging
   - Payment processing

3. **Enhanced UI**
   - Add ambient background animations
   - Implement swipe gestures
   - Custom loading animations

## 📁 Project Structure

```
QROWD(UPDATEDSTART)/
├── Theme.swift                     # Centralized theme system
├── SupabaseManager.swift          # Database & auth integration
├── ViewModels/
│   └── DJRegistrationViewModel.swift
├── Views/
│   ├── Onboarding/
│   │   ├── SplashView.swift
│   │   ├── UserTypeSelectionView.swift
│   │   └── AuthView.swift
│   └── DJ/
│       ├── DJRegistrationWizardView.swift
│       └── Steps/
│           ├── DJBasicInfoView.swift
│           ├── DJBudgetView.swift
│           ├── DJGenreView.swift
│           ├── DJEquipmentView.swift
│           ├── DJPromoView.swift
│           ├── DJAvailabilityView.swift
│           ├── DJSocialLinksView.swift
│           └── DJStripeView.swift
└── QROWD_UPDATEDSTART_App.swift   # Main app entry point
```

## 🎯 Key Features Implemented

- ✅ **Complete Onboarding Flow** with smooth animations
- ✅ **8-Step DJ Registration** with validation
- ✅ **Supabase Integration** for auth, database, storage
- ✅ **Dark Nightclub Theme** with consistent styling
- ✅ **MVVM Architecture** with proper state management
- ✅ **Form Validation** and error handling
- ✅ **File Uploads** for audio/video promos
- ✅ **Social Media Integration** preview
- ✅ **Stripe Connect** simulation

The app is ready for the next phase of development with a solid foundation, beautiful UI, and complete user onboarding experience! 🚀 