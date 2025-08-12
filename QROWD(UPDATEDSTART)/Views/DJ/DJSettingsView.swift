import SwiftUI

struct DJSettingsView: View {
    let profile: DJProfile
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabase = SupabaseManager.shared
    @StateObject private var stripe = StripeManager.shared
    @StateObject private var proViewModel = DJPROViewModel()
    
    @State private var showingPROUpgrade = false
    @State private var showingPaymentMethods = false
    @State private var showingSubscriptionInfo = false
    @State private var showingProfileEdit = false
    @State private var showingAnalytics = false
    @State private var showingAutoReplySettings = false
    @State private var showingNotificationSettings = false
    @State private var showingHelpSupport = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                QROWDTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // PRO Subscription Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("QROWD PRO")
                                .font(QROWDTheme.headlineFont)
                                .fontWeight(.semibold)
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            if let proStatus = proViewModel.proStatus {
                                if proStatus.isActive {
                                    // PRO Active Card
                                    VStack(spacing: 16) {
                                        HStack {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.title2)
                                                .foregroundColor(.green)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("PRO Active")
                                                    .font(QROWDTheme.bodyFont)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.green)
                                                
                                                Text("Next billing: \(proStatus.formattedPeriodEnd)")
                                                    .font(QROWDTheme.captionFont)
                                                    .foregroundColor(QROWDTheme.secondaryText)
                                            }
                                            
                                            Spacer()
                                            
                                            Button("Manage") {
                                                showingPROUpgrade = true
                                            }
                                            .font(QROWDTheme.captionFont)
                                            .foregroundColor(QROWDTheme.accentColor)
                                        }
                                        
                                        // PRO Features Status
                                        VStack(spacing: 8) {
                                            PROFeatureIndicator(feature: "Verified Badge", isEnabled: proStatus.features.verifiedBadge)
                                            PROFeatureIndicator(feature: "Auto-Chat Replies", isEnabled: proStatus.features.autoChatReplies)
                                            PROFeatureIndicator(feature: "Booking Analytics", isEnabled: proStatus.features.bookingAnalytics)
                                            PROFeatureIndicator(feature: "Profile Boosts (\(proStatus.boostCredits) left)", isEnabled: proStatus.features.scheduledBoosts)
                                            PROFeatureIndicator(feature: "Priority Search", isEnabled: proStatus.features.prioritySearch)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                                            .fill(QROWDTheme.cardGradient)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                } else {
                                    // Upgrade to PRO Card
                                    PROToggleButton(isPro: false) {
                                        showingPROUpgrade = true
                                    }
                                }
                            } else {
                                // Loading state
                                if proViewModel.isLoading {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: QROWDTheme.accentColor))
                                        
                                        Text("Loading PRO status...")
                                            .font(QROWDTheme.bodyFont)
                                            .foregroundColor(QROWDTheme.secondaryText)
                                    }
                                    .padding()
                                } else {
                                    PROToggleButton(isPro: false) {
                                        showingPROUpgrade = true
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .background(QROWDTheme.borderColor)
                        
                        // Other Settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account Settings")
                                .font(QROWDTheme.headlineFont)
                                .fontWeight(.semibold)
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            VStack(spacing: 12) {
                                                        SettingsRow(
                            icon: "person.circle",
                            title: "Edit Profile",
                            subtitle: "Update your DJ information"
                        ) {
                            showingProfileEdit = true
                        }
                                
                                SettingsRow(
                                    icon: "chart.bar",
                                    title: "Analytics",
                                    subtitle: "View your booking statistics",
                                    isPROFeature: true,
                                    isEnabled: proViewModel.proStatus?.features.bookingAnalytics ?? false
                                ) {
                                    if proViewModel.proStatus?.features.bookingAnalytics == true {
                                        showingAnalytics = true
                                    } else {
                                        showingPROUpgrade = true
                                    }
                                }
                                
                                SettingsRow(
                                    icon: "message.circle",
                                    title: "Auto-Reply Templates",
                                    subtitle: "Set up automatic responses",
                                    isPROFeature: true,
                                    isEnabled: proViewModel.proStatus?.features.autoChatReplies ?? false
                                ) {
                                    if proViewModel.proStatus?.features.autoChatReplies == true {
                                        showingAutoReplySettings = true
                                    } else {
                                        showingPROUpgrade = true
                                    }
                                }
                                
                                SettingsRow(
                                    icon: "bell.circle",
                                    title: "Notifications",
                                    subtitle: "Manage notification preferences"
                                ) {
                                    showingNotificationSettings = true
                                }
                                
                                SettingsRow(
                                    icon: "questionmark.circle",
                                    title: "Help & Support",
                                    subtitle: "Get help or contact support"
                                ) {
                                    showingHelpSupport = true
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(QROWDTheme.cardPadding)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(QROWDTheme.accentColor)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(QROWDTheme.headlineFont)
                        .foregroundColor(QROWDTheme.primaryText)
                }
            }
        }
        .task {
            await proViewModel.loadPROStatus()
        }
        .sheet(isPresented: $showingPROUpgrade) {
            DJPROUpgradeView()
        }
        .sheet(isPresented: $showingPaymentMethods) {
            PaymentMethodsView()
        }
        .sheet(isPresented: $showingSubscriptionInfo) {
            SubscriptionInfoView()
        }
        .sheet(isPresented: $showingProfileEdit) {
            DJRegistrationWizardView { }
        }
        .sheet(isPresented: $showingAnalytics) {
            DJAnalyticsView()
        }
        .sheet(isPresented: $showingAutoReplySettings) {
            AutoReplySettingsView()
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingHelpSupport) {
            HelpSupportView()
        }
        .alert("Success", isPresented: $proViewModel.showingSuccess) {
            Button("OK") { }
        } message: {
            Text(proViewModel.successMessage)
        }
        .alert("Error", isPresented: $proViewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(proViewModel.errorMessage)
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isPROFeature: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        isPROFeature: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isPROFeature = isPROFeature
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isEnabled ? QROWDTheme.accentColor : QROWDTheme.secondaryText)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(QROWDTheme.bodyFont)
                            .fontWeight(.medium)
                            .foregroundColor(isEnabled ? QROWDTheme.primaryText : QROWDTheme.secondaryText)
                        
                        if isPROFeature && !isEnabled {
                            PROBadgeView(size: .small)
                        }
                    }
                    
                    Text(subtitle)
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isPROFeature && isEnabled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(QROWDTheme.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                            .stroke(QROWDTheme.borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isEnabled ? 1.0 : 0.7)
    }
}

// MARK: - Placeholder Views for DJ Settings Navigation
struct DJAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                QROWDTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    QROWDLogo.medium
                    
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 60))
                        .foregroundColor(QROWDTheme.accentColor)
                    
                    Text("Analytics Coming Soon")
                        .font(QROWDTheme.titleFont)
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text("Track your bookings, earnings, and performance metrics")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(QROWDTheme.accentColor)
                }
            }
        }
    }
}

struct AutoReplySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                QROWDTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 60))
                        .foregroundColor(QROWDTheme.accentColor)
                    
                    Text("Auto-Reply Settings")
                        .font(QROWDTheme.titleFont)
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text("Customize automatic responses to booking inquiries")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Auto-Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(QROWDTheme.accentColor)
                }
            }
        }
    }
}

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var bookingNotifications = true
    @State private var messageNotifications = true
    @State private var promotionalNotifications = false
    
    var body: some View {
        NavigationView {
            ZStack {
                QROWDTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notification Preferences")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                                .padding(.horizontal)
                            
                            NotificationToggleRow(
                                title: "Booking Requests",
                                subtitle: "Get notified when someone wants to book you",
                                isOn: $bookingNotifications
                            )
                            
                            NotificationToggleRow(
                                title: "New Messages",
                                subtitle: "Get notified when you receive new messages",
                                isOn: $messageNotifications
                            )
                            
                            NotificationToggleRow(
                                title: "Promotional Updates",
                                subtitle: "Get notified about new features and offers",
                                isOn: $promotionalNotifications
                            )
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(QROWDTheme.accentColor)
                }
            }
        }
    }
}

struct NotificationToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(QROWDTheme.bodyFont)
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text(subtitle)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(QROWDTheme.accentColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                .fill(QROWDTheme.cardBackground)
        )
        .padding(.horizontal)
    }
}

struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                QROWDTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(QROWDTheme.accentColor)
                            .padding(.top, 20)
                        
                        Text("Help & Support")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        VStack(spacing: 12) {
                            HelpSupportRow(
                                icon: "book.fill",
                                title: "User Guide",
                                subtitle: "Learn how to use QROWD effectively"
                            ) { }
                            
                            HelpSupportRow(
                                icon: "envelope.fill",
                                title: "Contact Support",
                                subtitle: "Get help from our support team"
                            ) { }
                            
                            HelpSupportRow(
                                icon: "bubble.left.and.bubble.right.fill",
                                title: "Live Chat",
                                subtitle: "Chat with support representatives"
                            ) { }
                            
                            HelpSupportRow(
                                icon: "phone.fill",
                                title: "Call Support",
                                subtitle: "Speak directly with our team"
                            ) { }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(QROWDTheme.accentColor)
                }
            }
        }
    }
}

struct HelpSupportRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(QROWDTheme.accentColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text(subtitle)
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(QROWDTheme.cardBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SubscriptionInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                QROWDTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundColor(QROWDTheme.accentColor)
                    
                    Text("Subscription Info")
                        .font(QROWDTheme.titleFont)
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text("Manage your QROWD PRO subscription details")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(QROWDTheme.accentColor)
                }
            }
        }
    }
}

#Preview {
    DJSettingsView(profile: DJProfile(
        id: "1",
        userId: "user123",
        stageName: "DJ John",
        city: "New York",
        genres: ["House", "Techno"],
        budgetMin: 100.0,
        budgetMax: 200.0,
        equipment: ["Turntables", "Mixer", "Speakers"],
        availability: ["Friday": ["8:00 PM", "11:00 PM"], "Saturday": ["9:00 PM", "12:00 AM"]],
        instagramHandle: "@djjohn",
        soundcloudUrl: "https://soundcloud.com/djjohn",
        stripeAccountId: "acct_123",
        audioPromoUrl: "https://example.com/promo.mp3",
        videoPromoUrl: "https://example.com/promo.mp4",
        bio: "Professional DJ with 10 years experience",
        profileImageUrl: "https://example.com/profile.jpg",
        rating: 4.5,
        isPro: false
    ))
} 