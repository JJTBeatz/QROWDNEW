import SwiftUI
import SafariServices

struct DJPROUpgradeView: View {
    @StateObject private var viewModel = DJPROViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                QROWDTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        PROHeaderView()
                        
                        // Current Status (if already PRO)
                        if let status = viewModel.proStatus, status.isActive {
                            PROStatusCard(status: status, viewModel: viewModel)
                        } else {
                            // Upgrade Card
                            PROUpgradeCard(viewModel: viewModel)
                        }
                        
                        // Features List
                        PROFeaturesView(features: viewModel.proFeatures)
                        
                        // Boost Credits (if PRO)
                        if let status = viewModel.proStatus, status.isActive {
                            PROBoostCreditsView(status: status, viewModel: viewModel)
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
                    Text("QROWD PRO")
                        .font(QROWDTheme.headlineFont)
                        .foregroundColor(QROWDTheme.primaryText)
                }
            }
        }
        .task {
            await viewModel.loadPROStatus()
        }
        .sheet(isPresented: $viewModel.showingSafari) {
            if let url = viewModel.safariURL {
                SafariView(url: url)
            }
        }
        .alert("Success", isPresented: $viewModel.showingSuccess) {
            Button("OK") { }
        } message: {
            Text(viewModel.successMessage)
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Cancel Subscription", isPresented: $viewModel.showingCancelAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                Task {
                    await viewModel.cancelSubscription()
                }
            }
        } message: {
            Text("Are you sure you want to cancel your PRO subscription? You'll lose access to all PRO features.")
        }
    }
}

// MARK: - PRO Header
struct PROHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            // PRO Badge
            HStack {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("QROWD PRO")
                    .font(QROWDTheme.titleFont)
                    .fontWeight(.bold)
                    .foregroundColor(QROWDTheme.primaryText)
                
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
            }
            
            Text("Unlock premium features and grow your DJ career")
                .font(QROWDTheme.bodyFont)
                .foregroundColor(QROWDTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                .fill(QROWDTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - PRO Status Card
struct PROStatusCard: View {
    let status: DJPROStatus
    let viewModel: DJPROViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // PRO Badge
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("PRO Active")
                    .font(QROWDTheme.headlineFont)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                Text("Subscription Status")
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                
                Text(status.subscriptionStatus.capitalized)
                    .font(QROWDTheme.bodyFont)
                    .fontWeight(.medium)
                    .foregroundColor(QROWDTheme.primaryText)
                
                if let periodEnd = status.subscriptionPeriodEnd {
                    Text("Renews on \(status.formattedPeriodEnd)")
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
            }
            
            // Cancel Button
            Button("Cancel Subscription") {
                viewModel.showingCancelAlert = true
            }
            .font(QROWDTheme.captionFont)
            .foregroundColor(.red)
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
    }
}

// MARK: - PRO Upgrade Card
struct PROUpgradeCard: View {
    let viewModel: DJPROViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Price
            VStack(spacing: 4) {
                Text("$\(String(format: "%.0f", viewModel.proPrice))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(QROWDTheme.accentColor)
                
                Text("per month")
                    .font(QROWDTheme.bodyFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            
            // Upgrade Button
            QROWDButton(
                title: viewModel.isLoading ? "Processing..." : "Upgrade to PRO",
                isLoading: viewModel.isLoading,
                isEnabled: !viewModel.isLoading
            ) {
                Task {
                    await viewModel.upgradeToPRO()
                }
            }
            
            Text("Cancel anytime • No long-term commitment")
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                .fill(QROWDTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                        .stroke(QROWDTheme.accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - PRO Features
struct PROFeaturesView: View {
    let features: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PRO Features")
                .font(QROWDTheme.headlineFont)
                .fontWeight(.semibold)
                .foregroundColor(QROWDTheme.primaryText)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundColor(.green)
                        
                        Text(feature.replacingOccurrences(of: "✓ ", with: ""))
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
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
}

// MARK: - PRO Boost Credits
struct PROBoostCreditsView: View {
    let status: DJPROStatus
    let viewModel: DJPROViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "rocket.fill")
                    .font(.title2)
                    .foregroundColor(QROWDTheme.accentColor)
                
                Text("Profile Boosts")
                    .font(QROWDTheme.headlineFont)
                    .fontWeight(.semibold)
                    .foregroundColor(QROWDTheme.primaryText)
                
                Spacer()
                
                Text("\(status.boostCredits) credits")
                    .font(QROWDTheme.bodyFont)
                    .fontWeight(.medium)
                    .foregroundColor(QROWDTheme.accentColor)
            }
            
            Text("Boost your profile to appear higher in search results for 24 hours")
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.secondaryText)
                .multilineTextAlignment(.leading)
            
            QROWDButton(
                title: viewModel.isLoading ? "Boosting..." : "Use Boost Credit",
                isLoading: viewModel.isLoading,
                isEnabled: !viewModel.isLoading && status.boostCredits > 0
            ) {
                Task {
                    await viewModel.useBoostCredit()
                }
            }
            
            if status.boostCredits == 0 {
                Text("You'll receive 5 new boost credits next month")
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                    .multilineTextAlignment(.center)
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
}

// MARK: - Safari View
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    DJPROUpgradeView()
} 