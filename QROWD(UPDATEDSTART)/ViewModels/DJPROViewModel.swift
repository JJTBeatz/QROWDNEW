import Foundation
import SwiftUI
import SafariServices

@MainActor
class DJPROViewModel: ObservableObject {
    @Published var proStatus: DJPROStatus?
    @Published var isLoading = false
    @Published var showingError = false
    @Published var showingSuccess = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var showingUpgradeSheet = false
    @Published var showingCancelAlert = false
    @Published var showingSafari = false
    @Published var safariURL: URL?
    
    private let supabase = SupabaseManager.shared
    private let stripe = StripeManager.shared
    
    // PRO Subscription Details
    let proPrice = 14.99
    let proFeatures = [
        "✨ Verified PRO Badge",
        "🚀 Priority in Search Results", 
        "📊 Advanced Booking Analytics",
        "🤖 Auto-Chat Replies",
        "⚡ 5 Profile Boosts per Month"
    ]
    
    func loadPROStatus() async {
        isLoading = true
        
        do {
            guard let djProfile = try await supabase.getCurrentUserDJProfile() else {
                errorMessage = "DJ profile not found"
                showingError = true
                isLoading = false
                return
            }
            
            proStatus = try await supabase.getDJPROStatus(djId: djProfile.id)
            
            // If subscription exists, verify with Stripe
            if let status = proStatus, !status.subscriptionId.isEmpty {
                await verifySubscriptionWithStripe(subscriptionId: status.subscriptionId)
            }
            
        } catch {
            errorMessage = "Failed to load PRO status: \(error.localizedDescription)"
            showingError = true
        }
        
        isLoading = false
    }
    
    func upgradeToPRO() async {
        isLoading = true
        
        do {
            guard let djProfile = try await supabase.getCurrentUserDJProfile() else {
                errorMessage = "DJ profile not found"
                showingError = true
                isLoading = false
                return
            }
            
            guard let userEmail = supabase.currentUser?.email else {
                errorMessage = "User email not found"
                showingError = true
                isLoading = false
                return
            }
            
            // Create Stripe customer if needed
            let customerId = try await stripe.createCustomer(
                email: userEmail,
                name: djProfile.stageName
            )
            
            // Create Stripe Checkout Session for subscription
            let sessionId = try await stripe.createPROCheckoutSession(
                customerId: customerId,
                successURL: "qrowd://pro-upgrade-success",
                cancelURL: "qrowd://pro-upgrade-cancel"
            )
            
            // Open Stripe Checkout in Safari
            if let url = URL(string: "https://checkout.stripe.com/c/pay/\(sessionId)") {
                safariURL = url
                showingSafari = true
            }
            
        } catch {
            errorMessage = "Failed to start upgrade: \(error.localizedDescription)"
            showingError = true
        }
        
        isLoading = false
    }
    
    func handleUpgradeSuccess(subscriptionId: String) async {
        isLoading = true
        
        do {
            guard let djProfile = try await supabase.getCurrentUserDJProfile() else {
                errorMessage = "DJ profile not found"
                showingError = true
                isLoading = false
                return
            }
            
            // Get subscription details from Stripe
            let subscriptionStatus = try await stripe.getSubscriptionStatus(subscriptionId: subscriptionId)
            
            // Update DJ profile with PRO status
            try await supabase.updateDJPROStatus(
                djId: djProfile.id,
                isPro: true,
                subscriptionId: subscriptionId,
                subscriptionStatus: subscriptionStatus.status,
                periodEnd: subscriptionStatus.currentPeriodEnd
            )
            
            // Reload status
            await loadPROStatus()
            
            successMessage = "🎉 Welcome to QROWD PRO! Your account has been upgraded successfully."
            showingSuccess = true
            
        } catch {
            errorMessage = "Failed to activate PRO features: \(error.localizedDescription)"
            showingError = true
        }
        
        isLoading = false
    }
    
    func cancelSubscription() async {
        guard let status = proStatus, !status.subscriptionId.isEmpty else { return }
        
        isLoading = true
        
        do {
            // Cancel subscription with Stripe
            try await stripe.cancelSubscription(subscriptionId: status.subscriptionId)
            
            guard let djProfile = try await supabase.getCurrentUserDJProfile() else {
                errorMessage = "DJ profile not found"
                showingError = true
                isLoading = false
                return
            }
            
            // Update DJ profile to remove PRO status
            try await supabase.updateDJPROStatus(
                djId: djProfile.id,
                isPro: false,
                subscriptionStatus: "canceled"
            )
            
            // Reload status
            await loadPROStatus()
            
            successMessage = "Your PRO subscription has been canceled. You'll retain PRO features until the end of your billing period."
            showingSuccess = true
            
        } catch {
            errorMessage = "Failed to cancel subscription: \(error.localizedDescription)"
            showingError = true
        }
        
        isLoading = false
    }
    
    func useBoostCredit() async {
        guard let djProfile = try? await supabase.getCurrentUserDJProfile() else { return }
        
        isLoading = true
        
        do {
            try await supabase.useDJBoostCredit(djId: djProfile.id)
            
            // Reload status to update boost credits
            await loadPROStatus()
            
            successMessage = "🚀 Profile boosted! Your profile will appear higher in search results for the next 24 hours."
            showingSuccess = true
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isLoading = false
    }
    
    private func verifySubscriptionWithStripe(subscriptionId: String) async {
        do {
            let stripeStatus = try await stripe.getSubscriptionStatus(subscriptionId: subscriptionId)
            
            guard let djProfile = try await supabase.getCurrentUserDJProfile() else { return }
            
            // Update local status if different from Stripe
            if let currentStatus = proStatus, 
               currentStatus.subscriptionStatus != stripeStatus.status {
                
                try await supabase.updateDJPROStatus(
                    djId: djProfile.id,
                    isPro: stripeStatus.isActive,
                    subscriptionId: subscriptionId,
                    subscriptionStatus: stripeStatus.status,
                    periodEnd: stripeStatus.currentPeriodEnd
                )
                
                // Reload status
                await loadPROStatus()
            }
            
        } catch {
            print("Failed to verify subscription with Stripe: \(error)")
        }
    }
} 