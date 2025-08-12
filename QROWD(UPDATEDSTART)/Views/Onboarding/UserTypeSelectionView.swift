import SwiftUI

struct UserTypeSelectionView: View {
    @State private var selectedType: UserType?
    @State private var buttonScale: [UserType: CGFloat] = [:]
    @State private var showingAuth = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    
    let onUserTypeSelected: (UserType) -> Void
    
    enum UserType: String, CaseIterable {
        case dj = "I'm a DJ"
        case host = "I'm a Host"
        case guest = "Continue as Guest"
        
        var icon: String {
            switch self {
            case .dj: return "music.note.house"
            case .host: return "party.popper"
            case .guest: return "person.circle"
            }
        }
        
        var description: String {
            switch self {
            case .dj: return "Create your profile and get booked for events"
            case .host: return "Find and book DJs for your events"
            case .guest: return "Explore events and DJs in your area"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: QROWDTheme.sectionSpacing) {
                
                // Header with Logo
                VStack(spacing: 24) {
                    // QROWD Logo with title
                    QROWDLogo.largeDisplay
                    
                    VStack(spacing: 16) {
                        Text("Welcome to QROWD")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Spin, host, or pull up?")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, QROWDTheme.cardPadding)
                    }
                }
                .padding(.top, 60)
                
                Spacer()
                
                // User Type Buttons
                VStack(spacing: 20) {
                    ForEach(UserType.allCases, id: \.self) { userType in
                        UserTypeButton(
                            userType: userType,
                            isSelected: selectedType == userType,
                            scale: buttonScale[userType] ?? 1.0
                        ) {
                            handleUserTypeSelection(userType)
                        }
                    }
                }
                .padding(.horizontal, QROWDTheme.cardPadding)
                
                Spacer()
                
                // Footer
                VStack(spacing: 12) {
                    Text("By continuing, you agree to our")
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                    
                    HStack(spacing: 8) {
                        Button("Terms of Service") {
                            showingTerms = true
                        }
                        .foregroundColor(QROWDTheme.accentColor)
                        
                        Text("and")
                            .foregroundColor(QROWDTheme.secondaryText)
                        
                        Button("Privacy Policy") {
                            showingPrivacy = true
                        }
                        .foregroundColor(QROWDTheme.accentColor)
                    }
                    .font(QROWDTheme.captionFont)
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingAuth) {
            if let selectedType = selectedType {
                AuthView(userType: selectedType) { authenticatedUserType in
                    // Authentication completed - let main app handle the flow
                    print("DEBUG: Authentication completed for: \(authenticatedUserType)")
                    onUserTypeSelected(authenticatedUserType)
                }
            }
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
    }
    
    private func handleUserTypeSelection(_ userType: UserType) {
        selectedType = userType
        print("DEBUG: User selected type: \(userType)")
        
        // Button animation
        withAnimation(.easeOut(duration: 0.2)) {
            buttonScale[userType] = 0.95
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                buttonScale[userType] = 1.0
            }
        }
        
        // Navigate based on selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if userType == .guest {
                // For guests, go directly to main app
                onUserTypeSelected(userType)
            } else {
                // For DJ and Host, show authentication first
                showingAuth = true
            }
        }
    }
}

// MARK: - User Type Button Component
struct UserTypeButton: View {
    let userType: UserTypeSelectionView.UserType
    let isSelected: Bool
    let scale: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: userType.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 30)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(userType.rawValue)
                        .font(QROWDTheme.headlineFont)
                        .foregroundColor(.white)
                    
                    Text(userType.description)
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(QROWDTheme.cardPadding)
            .frame(maxWidth: .infinity, minHeight: QROWDTheme.buttonHeight + 20)
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(QROWDTheme.buttonGradient)
                    .shadow(
                        color: QROWDTheme.buttonGlow,
                        radius: isPressed ? 15 : 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .scaleEffect(scale)
        .animation(.easeOut(duration: 0.2), value: scale)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Terms and Privacy Views
struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms of Service")
                        .font(QROWDTheme.titleFont)
                        .foregroundColor(QROWDTheme.primaryText)
                        .padding(.top, 20)
                    
                    Text("Welcome to QROWD! By using our app, you agree to these terms...")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text("1. Acceptance of Terms")
                        .font(QROWDTheme.headlineFont)
                        .foregroundColor(QROWDTheme.primaryText)
                        .padding(.top)
                    
                    Text("By accessing and using QROWD, you accept and agree to be bound by the terms and provision of this agreement.")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                    
                    Text("2. Use License")
                        .font(QROWDTheme.headlineFont)
                        .foregroundColor(QROWDTheme.primaryText)
                        .padding(.top)
                    
                    Text("Permission is granted to temporarily download one copy of QROWD per device for personal, non-commercial transitory viewing only.")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                    
                    // Add more terms sections as needed
                }
                .padding(.horizontal, QROWDTheme.cardPadding)
                .padding(.bottom, 40)
            }
            .background(QROWDTheme.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(QROWDTheme.accentColor)
                }
            }
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(QROWDTheme.titleFont)
                        .foregroundColor(QROWDTheme.primaryText)
                        .padding(.top, 20)
                    
                    Text("Your privacy is important to us. This policy explains how we collect, use, and protect your information.")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text("Information We Collect")
                        .font(QROWDTheme.headlineFont)
                        .foregroundColor(QROWDTheme.primaryText)
                        .padding(.top)
                    
                    Text("We collect information you provide directly to us, such as when you create an account, make a booking, or contact us for support.")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                    
                    Text("How We Use Your Information")
                        .font(QROWDTheme.headlineFont)
                        .foregroundColor(QROWDTheme.primaryText)
                        .padding(.top)
                    
                    Text("We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you.")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                    
                    // Add more privacy sections as needed
                }
                .padding(.horizontal, QROWDTheme.cardPadding)
                .padding(.bottom, 40)
            }
            .background(QROWDTheme.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(QROWDTheme.accentColor)
                }
            }
        }
    }
}

#Preview {
    UserTypeSelectionView { _ in }
} 
