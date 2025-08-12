import SwiftUI

struct AuthView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var isLoading = false
    
    @Environment(\.dismiss) private var dismiss
    
    let userType: UserTypeSelectionView.UserType
    let onAuthComplete: (UserTypeSelectionView.UserType) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                QROWDTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: QROWDTheme.sectionSpacing) {
                        
                        // Header with Logo
                        VStack(spacing: 20) {
                            // QROWD Logo
                            QROWDLogo.medium
                            
                            VStack(spacing: 16) {
                                Text(isSignUp ? "Create Account" : "Welcome Back")
                                    .font(QROWDTheme.titleFont)
                                    .foregroundColor(QROWDTheme.primaryText)
                                
                                Text(isSignUp ? "Join the QROWD community" : "Sign in to continue")
                                    .font(QROWDTheme.bodyFont)
                                    .foregroundColor(QROWDTheme.secondaryText)
                            }
                        }
                        .padding(.top, 40)
                        
                        // Auth Form
                        VStack(spacing: 20) {
                            
                            // Email Field
                            QROWDTextField(
                                text: $email,
                                placeholder: "Email",
                                icon: "envelope"
                            )
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            
                            // Password Field
                            QROWDSecureField(
                                text: $password,
                                placeholder: "Password",
                                icon: "lock"
                            )
                            .textContentType(isSignUp ? .newPassword : .password)
                            
                            // Confirm Password (Sign Up only)
                            if isSignUp {
                                QROWDSecureField(
                                    text: $confirmPassword,
                                    placeholder: "Confirm Password",
                                    icon: "lock.fill"
                                )
                                .textContentType(.newPassword)
                            }
                            
                            // Submit Button
                            QROWDButton(
                                title: isSignUp ? "Create Account" : "Sign In",
                                isLoading: isLoading,
                                isEnabled: isFormValid
                            ) {
                                Task {
                                    await handleAuth()
                                }
                            }
                            .padding(.top, 20)
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        // Toggle Auth Mode
                        HStack {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                            
                            Button(isSignUp ? "Sign In" : "Sign Up") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isSignUp.toggle()
                                    clearForm()
                                }
                            }
                            .font(QROWDTheme.captionFont.weight(.semibold))
                            .foregroundColor(QROWDTheme.accentColor)
                        }
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(QROWDTheme.borderColor)
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                                .padding(.horizontal, 16)
                            
                            Rectangle()
                                .fill(QROWDTheme.borderColor)
                                .frame(height: 1)
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        // Social Auth Buttons
                        VStack(spacing: 12) {
                            SocialAuthButton(
                                title: "Continue with Apple",
                                icon: "apple.logo",
                                backgroundColor: .white
                            ) {
                                handleSocialAuth(provider: "apple")
                            }
                            
                            SocialAuthButton(
                                title: "Continue with Google",
                                icon: "globe",
                                backgroundColor: Color(hex: "#4285F4")
                            ) {
                                handleSocialAuth(provider: "google")
                            }
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(QROWDTheme.primaryText)
                }
            }
        }
        .alert("Authentication Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Form Validation
    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6
        
        if isSignUp {
            return emailValid && passwordValid && password == confirmPassword
        } else {
            return emailValid && passwordValid
        }
    }
    
    // MARK: - Auth Methods
    private func handleAuth() async {
        isLoading = true
        
        do {
            if isSignUp {
                try await supabase.signUp(email: email, password: password)
            } else {
                try await supabase.signIn(email: email, password: password)
            }
            
            // Navigate to main app - pass through the correct user type
            await MainActor.run {
                dismiss()
                onAuthComplete(userType)
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                isLoading = false
            }
        }
    }
    
    private func handleSocialAuth(provider: String) {
        // For now, show a placeholder message
        errorMessage = "\(provider.capitalized) Sign In coming soon!"
        showingError = true
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = ""
    }
}

// MARK: - Custom Text Field Components
// QROWDTextField moved to QROWDComponents.swift

struct QROWDSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @State private var isSecure = true
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(QROWDTheme.accentColor)
                .frame(width: 20)
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.placeholderText)
                }
                
                Group {
                    if isSecure {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .font(QROWDTheme.bodyFont)
                .foregroundColor(QROWDTheme.primaryText)
            }
            
            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(QROWDTheme.secondaryText)
            }
        }
        .padding(QROWDTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                .fill(QROWDTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                        .stroke(QROWDTheme.borderColor, lineWidth: 1)
                )
        )
    }
}

// QROWDButton moved to QROWDComponents.swift

struct SocialAuthButton: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(backgroundColor == .white ? .black : .white)
                
                Text(title)
                    .font(QROWDTheme.bodyFont)
                    .foregroundColor(backgroundColor == .white ? .black : .white)
            }
            .frame(maxWidth: .infinity, minHeight: QROWDTheme.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                            .stroke(QROWDTheme.borderColor, lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    AuthView(userType: .dj) { _ in }
} 