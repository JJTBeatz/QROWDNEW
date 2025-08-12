//
//  QROWD_UPDATEDSTART_App.swift
//  QROWD(UPDATEDSTART)
//
//  Created by JJ Singh on 6/21/25.
//

import SwiftUI
import SwiftData

@main
 struct QROWD_UPDATEDSTART_App: App {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var showingSplash = true
    @State private var userType: UserTypeSelectionView.UserType?
    @State private var needsProfileSetup = false
    @State private var isCheckingProfile = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showingSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            showingSplash = false
                        }
                    }
                } else if isCheckingProfile {
                    LoadingView()
                } else if supabaseManager.isAuthenticated {
                    if needsProfileSetup {
                        // Show appropriate registration flow based on user type
                        if userType == .dj {
                            DJRegistrationWizardView { 
                                needsProfileSetup = false
                            }
                        } else if userType == .host {
                            HostRegistrationWizardView {
                                needsProfileSetup = false
                            }
                        } else if userType == .guest {
                            GuestRegistrationView {
                                needsProfileSetup = false
                            }
                        }
                    } else {
                        // Main App Content
                        if let userType = userType {
                            MainAppView(userType: userType)
                        } else {
                            MainAppView(userType: .host) // Default fallback
                        }
                    }
                } else {
                    // Onboarding Flow
                    UserTypeSelectionView { selectedType in
                        userType = selectedType
                        print("DEBUG: UserType selected: \(selectedType)")
                        
                        if selectedType == .guest {
                            // Guest users can browse without auth
                            Task {
                                await MainActor.run {
                                    supabaseManager.isAuthenticated = true
                                }
                            }
                        }
                        // For DJ and Host, auth flow will handle authentication
                    }
                }
            }
            .onChange(of: supabaseManager.isAuthenticated) { _, isAuthenticated in
                print("DEBUG: Authentication state changed to: \(isAuthenticated)")
                print("DEBUG: Current userType: \(String(describing: userType))")
                
                // Check profile status for all user types after authentication
                if isAuthenticated {
                    // Give a moment for userType to be set properly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        Task {
                            await checkProfileStatus()
                        }
                    }
                } else {
                    // User signed out - reset all state
                    userType = nil
                    needsProfileSetup = false
                    isCheckingProfile = false
                }
            }
        }
    }
    
    private func checkProfileStatus() async {
        guard let userId = supabaseManager.currentUser?.id.uuidString else { 
            print("DEBUG: No user ID found")
            return 
        }
        guard let currentUserType = userType else { 
            print("DEBUG: No user type set")
            return 
        }
        
        print("DEBUG: Checking profile status for user: \(userId), type: \(currentUserType)")
        
        await MainActor.run {
            isCheckingProfile = true
        }
        
        do {
            var profileExists = false
            
            switch currentUserType {
            case .dj:
                profileExists = try await supabaseManager.checkDJProfileExists(userId: userId)
                print("DEBUG: DJ profile exists: \(profileExists)")
            case .host:
                profileExists = try await supabaseManager.checkHostProfileExists(userId: userId)
                print("DEBUG: Host profile exists: \(profileExists)")
            case .guest:
                // For guests, profile is optional, so we don't force setup
                // But we can check if they have one
                profileExists = try await supabaseManager.checkGuestProfileExists(userId: userId)
                // For guests, we won't force profile setup even if it doesn't exist
                profileExists = true
                print("DEBUG: Guest profile check complete")
            }
            
            await MainActor.run {
                needsProfileSetup = !profileExists
                isCheckingProfile = false
                print("DEBUG: Profile setup needed: \(needsProfileSetup)")
            }
        } catch {
            print("DEBUG: Error checking profile status: \(error)")
            await MainActor.run {
                // Default to requiring setup if check fails (except for guests)
                needsProfileSetup = currentUserType != .guest
                isCheckingProfile = false
                print("DEBUG: Profile setup needed (error case): \(needsProfileSetup)")
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        ZStack {
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Animated QROWD Logo
                QROWDLogo.loading
                
                VStack(spacing: 12) {
                    Text("Setting up your profile...")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text("This will only take a moment")
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
            }
        }
    }
}

// MARK: - Main App View
struct MainAppView: View {
    let userType: UserTypeSelectionView.UserType
    @State private var selectedTab = 0
    @State private var showingAIAssistant = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            Group {
                switch userType {
                case .host:
                    NavigationView {
                        HostSearchViewWithAI() // Temporarily use this until HostDashboardView is defined
                    }
                case .dj:
                    NavigationView {
                        DJDashboardViewWithAI()
                    }
                case .guest:
                    NavigationView {
                        HostSearchViewWithAI() // Guests can browse DJs
                    }
                }
            }
            .tabItem {
                Image(systemName: userType == .dj ? "music.house" : userType == .host ? "person.2" : "magnifyingglass")
                Text(userType == .dj ? "Dashboard" : userType == .host ? "Dashboard" : "Find DJs")
            }
            .tag(0)
            
            // AI Assistant Tab
            NavigationView {
                AILaunchView()
            }
            .tabItem {
                Image(systemName: "brain.head.profile")
                Text("QROWD AI")
            }
            .tag(1)
            
            // Chat Tab
            ChatListView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Messages")
                }
                .tag(2)
            
            // Profile Tab
            ProfileView(userType: userType)
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(QROWDTheme.accentColor)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    let userType: UserTypeSelectionView.UserType
    @StateObject private var supabase = SupabaseManager.shared
    
    var body: some View {
        NavigationView {
            Group {
                if userType == .guest {
                    GuestProfileView()
                } else if userType == .host {
                    HostProfileView()
                } else if userType == .dj {
                    AuthenticatedDJProfileView()
                } else {
                    AuthenticatedProfileView(userType: userType)
                }
            }
        }
    }
}

// MARK: - Host Profile View
struct HostProfileView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @State private var hostProfile: HostProfile?
    @State private var isLoading = true
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    
    var body: some View {
        ZStack {
            QROWDTheme.backgroundColor.ignoresSafeArea()
            
            if isLoading {
                EnhancedLoadingView()
            } else {
                ScrollView {
                    VStack(spacing: QROWDTheme.sectionSpacing) {
                        // Profile Header
                        if let profile = hostProfile {
                            HostProfileHeader(profile: profile)
                        }
                        
                        // Host Stats
                        HostStatsSection(profile: hostProfile)
                        
                        // Recent Events
                        HostRecentEventsSection()
                        
                        // Profile Actions
                        HostProfileActions(
                            onEditProfile: { showingEditProfile = true },
                            onSettings: { showingSettings = true }
                        )
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    .padding(.top, 20)
                }
            }
        }
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(QROWDTheme.primaryText)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            Text("Host Settings - Coming Soon!")
        }
        .sheet(isPresented: $showingEditProfile) {
            EditHostProfileView(profile: hostProfile)
        }
        .task {
            await loadHostProfile()
        }
    }
    
    private func loadHostProfile() async {
        guard let userId = supabase.currentUser?.id.uuidString else { return }
        
        do {
            hostProfile = try await supabase.getHostProfile(userId: userId)
        } catch {
            print("Failed to load host profile: \(error)")
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
}

struct HostProfileHeader: View {
    let profile: HostProfile
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture
            ZStack {
                Circle()
                    .fill(QROWDTheme.buttonGradient)
                    .frame(width: 100, height: 100)
                
                Text(profile.firstName.prefix(1))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Basic Info
            VStack(spacing: 8) {
                Text("\(profile.firstName) \(profile.lastName)")
                    .font(QROWDTheme.titleFont)
                    .foregroundColor(QROWDTheme.primaryText)
                
                if let company = profile.companyName, !company.isEmpty {
                    Text(company)
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
                
                Text(profile.city)
                    .font(QROWDTheme.bodyFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                
                // Preferred Genres
                if !profile.preferredGenres.isEmpty {
                    Text(profile.preferredGenres.prefix(3).joined(separator: " • "))
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.accentColor)
                }
            }
        }
        .padding(QROWDTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                .fill(QROWDTheme.cardBackground)
        )
    }
}

struct HostStatsSection: View {
    let profile: HostProfile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Stats")
                .font(QROWDTheme.headlineFont)
                .foregroundColor(QROWDTheme.primaryText)
            
            HStack(spacing: 16) {
                StatCard(title: "Events Hosted", value: "\(profile?.totalBookings ?? 0)")
                StatCard(title: "Host Rating", value: String(format: "%.1f", profile?.rating ?? 0.0))
                StatCard(title: "Verified", value: profile?.verified == true ? "✓" : "—")
            }
        }
        .padding(QROWDTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                .fill(QROWDTheme.cardBackground)
        )
    }
}

struct HostRecentEventsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Events")
                .font(QROWDTheme.headlineFont)
                .foregroundColor(QROWDTheme.primaryText)
            
            EmptyStateCard(
                icon: "calendar.badge.clock",
                title: "No Recent Events",
                description: "Your hosted events will appear here"
            )
        }
        .padding(QROWDTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                .fill(QROWDTheme.cardBackground)
        )
    }
}

struct HostProfileActions: View {
    let onEditProfile: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            MagneticButton(title: "Edit Profile", icon: "pencil") {
                onEditProfile()
            }
            
            MagneticButton(title: "Settings", icon: "gearshape") {
                onSettings()
            }
        }
        .padding(QROWDTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                .fill(QROWDTheme.cardBackground)
        )
    }
}

// MARK: - DJ Profile View
struct AuthenticatedDJProfileView: View {
    var body: some View {
        DJProfileTabView()
    }
}

struct EditHostProfileView: View {
    let profile: HostProfile?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Edit Host Profile")
                    .font(QROWDTheme.titleFont)
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text("Profile editing coming soon!")
                    .font(QROWDTheme.bodyFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - DJ Dashboard View removed - using dedicated DJDashboardView.swift file

// MARK: - Guest Profile View
struct GuestProfileView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @State private var showingAuthForGuest = false
    
    var body: some View {
        ZStack {
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: QROWDTheme.sectionSpacing) {
                    // Welcome Section
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 60))
                            .foregroundColor(QROWDTheme.accentColor)
                            .glow(color: QROWDTheme.accentColor, intensity: 0.3)
                        
                        Text("Browse as Guest")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        Text("Discover amazing DJs and events in your area")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Benefits Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Benefits of Creating an Account")
                            .font(QROWDTheme.headlineFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        ForEach([
                            ("Book DJs", "Calendar and messaging with DJs", "calendar.badge.plus"),
                            ("Save Favorites", "Keep a list of your favorite DJs", "heart.circle"),
                            ("Event Planning", "AI-powered event planning tools", "sparkles"),
                            ("Secure Payments", "Safe and secure payment processing", "creditcard.circle"),
                            ("24/7 Support", "Get help whenever you need it", "questionmark.circle")
                        ], id: \.0) { benefit in
                            GuestBenefitRow(
                                title: benefit.0,
                                description: benefit.1,
                                icon: benefit.2
                            )
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Sign Up Button
                    VStack(spacing: 12) {
                        MagneticButton(title: "Sign Up as Host", icon: "person.badge.plus") {
                            showingAuthForGuest = true
                        }
                        
                        Button("Already have an account? Sign In") {
                            showingAuthForGuest = true
                        }
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.accentColor)
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAuthForGuest) {
            UserTypeSelectionView { userType in
                // Handle user type selection from guest profile
                showingAuthForGuest = false
            }
        }
    }
}

// MARK: - Authenticated Profile View
struct AuthenticatedProfileView: View {
    let userType: UserTypeSelectionView.UserType
    @StateObject private var supabase = SupabaseManager.shared
    @State private var showingSettings = false
    @State private var showingPaymentMethods = false
    @State private var showingCreateEvent = false
    
    var body: some View {
        ZStack {
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: QROWDTheme.sectionSpacing) {
                    if userType == .host {
                        HostProfileContent(
                            showingSettings: $showingSettings,
                            showingPaymentMethods: $showingPaymentMethods,
                            showingCreateEvent: $showingCreateEvent
                        )
                    } else {
                        // DJ Profile content would go here
                        DJProfileContent(showingSettings: $showingSettings)
                    }
                }
                .padding(.horizontal, QROWDTheme.cardPadding)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(QROWDTheme.primaryText)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            ProfileSettingsView()
        }
        .sheet(isPresented: $showingPaymentMethods) {
            PaymentMethodsView()
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventView()
        }
    }
}

// MARK: - Host Profile Content
struct HostProfileContent: View {
    @Binding var showingSettings: Bool
    @Binding var showingPaymentMethods: Bool
    @Binding var showingCreateEvent: Bool
    @StateObject private var supabase = SupabaseManager.shared
    
    var body: some View {
        VStack(spacing: QROWDTheme.sectionSpacing) {
            // My Info Section
            ProfileSection(title: "My Info") {
                VStack(spacing: 12) {
                    HostInfoRow(label: "Name", value: supabase.currentUser?.email ?? "User")
                    HostInfoRow(label: "Email", value: supabase.currentUser?.email ?? "user@example.com")
                    HostInfoRow(label: "City", value: "Los Angeles, CA")
                    
                    NavigationLink(destination: FavoriteDJsView()) {
                        HostInfoRowWithChevron(label: "Favorite DJs", value: "3 saved")
                    }
                    
                    NavigationLink(destination: PastBookingsView()) {
                        HostInfoRowWithChevron(label: "Recent Events", value: "View history")
                    }
                }
            }
            
            // Upcoming Events Section
            ProfileSection(title: "Upcoming Events") {
                VStack(spacing: 12) {
                    if true { // Replace with actual check for upcoming events
                        EmptyStateCard(
                            icon: "calendar.badge.plus",
                            title: "No Upcoming Events",
                            description: "Book a DJ for your next event"
                        )
                    } else {
                        // Show upcoming events list
                        ForEach(0..<3) { index in
                            UpcomingEventRow(
                                eventName: "Birthday Party",
                                date: "June 25, 2024",
                                djName: "DJ Alex",
                                status: "Confirmed"
                            )
                        }
                    }
                }
            }
            
            // Event Planning Section
            ProfileSection(title: "Event Planning") {
                VStack(spacing: 12) {
                    NavigationLink(destination: DraftedEventsView()) {
                        EventPlanningRow(
                            icon: "doc.text",
                            title: "Drafted Event Briefs",
                            subtitle: "2 drafts saved",
                            showChevron: true
                        )
                    }
                    
                    NavigationLink(destination: AIPlansView()) {
                        EventPlanningRow(
                            icon: "doc.richtext",
                            title: "AI-Generated Plans",
                            subtitle: "Download PDFs",
                            showChevron: true
                        )
                    }
                    
                    MagneticButton(title: "Create New Event", icon: "plus.circle") {
                        showingCreateEvent = true
                    }
                }
            }
        }
    }
}

// MARK: - DJ Profile Content (Placeholder)
struct DJProfileContent: View {
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(spacing: QROWDTheme.sectionSpacing) {
            Text("DJ Profile Content")
                .font(QROWDTheme.headlineFont)
                .foregroundColor(QROWDTheme.primaryText)
            
            Text("DJ-specific profile sections would go here")
                .font(QROWDTheme.bodyFont)
                .foregroundColor(QROWDTheme.secondaryText)
        }
    }
}

// MARK: - Supporting Components
struct GuestBenefitRow: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(QROWDTheme.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(QROWDTheme.bodyFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text(description)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct ProfileSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(QROWDTheme.headlineFont)
                .foregroundColor(QROWDTheme.primaryText)
            
            VStack(spacing: 8) {
                content
            }
            .padding(QROWDTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(QROWDTheme.cardBackground)
            )
        }
    }
}

struct HostInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(QROWDTheme.bodyFont)
                .foregroundColor(QROWDTheme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(QROWDTheme.bodyFont.weight(.medium))
                .foregroundColor(QROWDTheme.primaryText)
        }
        .padding(.vertical, 4)
    }
}

struct HostInfoRowWithChevron: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(QROWDTheme.bodyFont)
                .foregroundColor(QROWDTheme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(QROWDTheme.bodyFont.weight(.medium))
                .foregroundColor(QROWDTheme.accentColor)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(QROWDTheme.secondaryText)
        }
        .padding(.vertical, 8)
    }
}

struct UpcomingEventRow: View {
    let eventName: String
    let date: String
    let djName: String
    let status: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(eventName)
                    .font(QROWDTheme.bodyFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Spacer()
                
                Text(status)
                    .font(QROWDTheme.captionFont.weight(.medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack {
                Text(date)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                
                Spacer()
                
                Text("with \(djName)")
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.accentColor)
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(QROWDTheme.backgroundColor.opacity(0.3))
        )
    }
}

struct EventPlanningRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let showChevron: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(QROWDTheme.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(QROWDTheme.bodyFont.weight(.medium))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text(subtitle)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
        }
        .padding(.vertical, 8)
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(QROWDTheme.secondaryText)
            
            Text(title)
                .font(QROWDTheme.bodyFont.weight(.medium))
                .foregroundColor(QROWDTheme.primaryText)
            
            Text(description)
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Placeholder Views for Navigation
struct FavoriteDJsView: View {
    var body: some View {
        Text("Favorite DJs")
            .navigationTitle("Favorite DJs")
    }
}

struct PastBookingsView: View {
    var body: some View {
        Text("Past Bookings")
            .navigationTitle("Recent Events")
    }
}

struct DraftedEventsView: View {
    var body: some View {
        Text("Drafted Events")
            .navigationTitle("Event Briefs")
    }
}

struct AIPlansView: View {
    var body: some View {
        Text("AI Plans")
            .navigationTitle("AI-Generated Plans")
    }
}

struct CreateEventView: View {
    var body: some View {
        Text("Create Event")
            .navigationTitle("Create New Event")
    }
}

struct ProfileSettingsView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    
    var body: some View {
        NavigationView {
            ZStack {
                QROWDTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: QROWDTheme.sectionSpacing) {
                    // Payment Methods
                    SettingsRow(
                        icon: "creditcard",
                        title: "Payment Methods",
                        subtitle: "Manage your payment options"
                    ) {
                        // Show payment methods
                    }
                    
                    // Notifications toggle
                    HStack(spacing: 16) {
                        Image(systemName: "bell")
                            .font(.title2)
                            .foregroundColor(QROWDTheme.accentColor)
                            .frame(width: 30)
                        
                        Text("Notifications")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        Spacer()
                        
                        Toggle("", isOn: $notificationsEnabled)
                            .tint(QROWDTheme.accentColor)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    .background(
                        RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                            .fill(QROWDTheme.cardBackground)
                    )
                    
                    Spacer()
                    
                    // Sign Out
                    QROWDButton(
                        title: "Sign Out",
                        isLoading: false,
                        isEnabled: true
                    ) {
                        Task {
                            try? await supabase.signOut()
                            dismiss()
                        }
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, QROWDTheme.cardPadding)
                .padding(.top, 20)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PaymentMethodsView: View {
    var body: some View {
        Text("Payment Methods")
            .navigationTitle("Payment Methods")
    }
}

// Settings components moved to DJSettingsView.swift to avoid duplication
