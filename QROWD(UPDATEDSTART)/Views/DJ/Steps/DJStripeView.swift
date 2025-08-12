import SwiftUI

struct DJStripeView: View {
    @ObservedObject var viewModel: DJRegistrationViewModel
    
    var body: some View {
        ZStack {
            // Background
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: QROWDTheme.sectionSpacing) {
                    
                    // Header
                    VStack(spacing: 12) {
                        Text("Get Paid Securely")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Connect your Stripe account to receive payments")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, QROWDTheme.cardPadding)
                    }
                    .padding(.top, 40)
                    
                    // Stripe Status Card
                    VStack(spacing: 20) {
                        if viewModel.isStripeConnected {
                            ConnectedCard(accountId: viewModel.stripeConnectId ?? "")
                        } else {
                            ConnectCard(isLoading: viewModel.isLoading) {
                                Task {
                                    await viewModel.connectStripe()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Benefits Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Why Stripe?")
                            .font(QROWDTheme.headlineFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        VStack(spacing: 12) {
                            StripeFeatureCard(
                                icon: "shield.checkered",
                                title: "Secure Payments",
                                description: "Bank-level security for all transactions"
                            )
                            
                            StripeFeatureCard(
                                icon: "creditcard.fill",
                                title: "Multiple Payment Methods",
                                description: "Accept cards, Apple Pay, and more"
                            )
                            
                            StripeFeatureCard(
                                icon: "clock.fill",
                                title: "Fast Payouts",
                                description: "Get paid within 2 business days"
                            )
                            
                            StripeFeatureCard(
                                icon: "chart.bar.fill",
                                title: "Detailed Reports",
                                description: "Track all your earnings and fees"
                            )
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // How it Works
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How It Works")
                            .font(QROWDTheme.headlineFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        VStack(spacing: 12) {
                            ProcessStep(
                                number: "1",
                                title: "Connect Account",
                                description: "Link or create your Stripe account"
                            )
                            
                            ProcessStep(
                                number: "2",
                                title: "Get Booked",
                                description: "Clients book and pay through the platform"
                            )
                            
                            ProcessStep(
                                number: "3",
                                title: "Receive Payment",
                                description: "Money appears in your bank account automatically"
                            )
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Fees Information
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(QROWDTheme.accentColor)
                            
                            Text("Fees & Processing")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeeRow(label: "Platform Fee", value: "5%")
                            FeeRow(label: "Stripe Processing", value: "2.9% + $0.30")
                            FeeRow(label: "Your Earnings", value: "~92% of booking")
                        }
                        
                        Text("All fees are deducted automatically before payout")
                            .font(QROWDTheme.captionFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .padding(.top, 8)
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
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Skip Option
                    if !viewModel.isStripeConnected {
                        VStack(spacing: 8) {
                            Text("You can set up payments later in your profile settings")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                                .multilineTextAlignment(.center)
                            
                            Button("Skip for now") {
                                // Skip logic handled by the wizard
                            }
                            .font(QROWDTheme.captionFont.weight(.medium))
                            .foregroundColor(QROWDTheme.accentColor)
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
        }
    }
}

struct ConnectCard: View {
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Stripe Logo Placeholder
            ZStack {
                Circle()
                    .fill(QROWDTheme.cardGradient)
                    .frame(width: 80, height: 80)
                
                Text("Stripe")
                    .font(.title2.weight(.bold))
                    .foregroundColor(QROWDTheme.accentColor)
            }
            
            VStack(spacing: 8) {
                Text("Connect with Stripe")
                    .font(QROWDTheme.headlineFont)
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text("Set up secure payments to start earning")
                    .font(QROWDTheme.bodyFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            QROWDButton(
                title: "Connect Stripe Account",
                isLoading: isLoading,
                isEnabled: !isLoading
            ) {
                action()
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

struct ConnectedCard: View {
    let accountId: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(QROWDTheme.buttonGradient)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "checkmark")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stripe Connected")
                        .font(QROWDTheme.headlineFont)
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text("Ready to receive payments")
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
                
                Spacer()
            }
            
            HStack {
                Text("Account ID:")
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                
                Text(accountId.prefix(15) + "...")
                    .font(QROWDTheme.captionFont.weight(.medium))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Spacer()
                
                Button("Manage") {
                    // Open Stripe dashboard
                }
                .font(QROWDTheme.captionFont.weight(.medium))
                .foregroundColor(QROWDTheme.accentColor)
            }
        }
        .padding(QROWDTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                .fill(QROWDTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                        .stroke(.green.opacity(0.5), lineWidth: 2)
                )
        )
    }
}

struct StripeFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(QROWDTheme.accentColor)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(QROWDTheme.bodyFont.weight(.medium))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text(description)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding(16)
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

struct ProcessStep: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(QROWDTheme.buttonGradient)
                    .frame(width: 32, height: 32)
                
                Text(number)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(QROWDTheme.bodyFont.weight(.medium))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text(description)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            
            Spacer()
        }
    }
}

struct FeeRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(QROWDTheme.captionFont.weight(.medium))
                .foregroundColor(QROWDTheme.primaryText)
        }
    }
}

#Preview {
    DJStripeView(viewModel: DJRegistrationViewModel())
} 