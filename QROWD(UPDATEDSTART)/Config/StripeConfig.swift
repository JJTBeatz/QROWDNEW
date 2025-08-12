import Foundation

// MARK: - Stripe Configuration
struct StripeConfig {
    
    // MARK: - API Keys
    // 🔑 Replace these with your actual Stripe keys from dashboard.stripe.com
    static let publishableKey = "pk_test_51RaUwhPwdjwFbzEkwLJ989Lcu2EyzZU6HO3qFNMDdMjXHI8EvrkGoJawFybXOtlhI80VUTXXqoLWhhr0d58gCrk4005XmEPVUA"
    static let secretKey = "sk_test_51RaUwhPwdjwFbzEk2vDOSEEYh4O0JaImj06sDcs1sOVcj6Tc75uZ0GQMf90VJcZTVb9Ulnt8hMVPwJBltwaoa4AB00hEvsX2aw"
    
    // MARK: - Environment
    static let isLiveMode = false // Set to true when ready for production
    
    // MARK: - Platform Settings
    static let platformFeePercentage: Double = 10.0 // QROWD's 10% platform fee
    static let applicationName = "QROWD"
    
    // MARK: - Computed Properties
    static var currentPublishableKey: String {
        return isLiveMode ? livePublishableKey : publishableKey
    }
    
    static var currentSecretKey: String {
        return isLiveMode ? liveSecretKey : secretKey
    }
    
    // MARK: - Live Keys (Add when ready for production)
    private static let livePublishableKey = "pk_live_YOUR_LIVE_PUBLISHABLE_KEY_HERE"
    private static let liveSecretKey = "sk_live_YOUR_LIVE_SECRET_KEY_HERE"
    
    // MARK: - Validation
    static func validateKeys() -> Bool {
        let pubKey = currentPublishableKey
        let secKey = currentSecretKey
        
        if isLiveMode {
            return pubKey.hasPrefix("pk_live_") && secKey.hasPrefix("sk_live_")
        } else {
            return pubKey.hasPrefix("pk_test_") && secKey.hasPrefix("sk_test_")
        }
    }
    
    static var keysConfigured: Bool {
        return !currentPublishableKey.contains("YOUR_") && 
               !currentSecretKey.contains("YOUR_") &&
               validateKeys()
    }
}

// MARK: - Stripe URLs
extension StripeConfig {
    static let successURL = "qrowd://payment-success"
    static let cancelURL = "qrowd://payment-cancel"
    static let refreshURL = "qrowd://stripe-refresh"
    static let returnURL = "qrowd://stripe-return"
}

// MARK: - Test Cards for Development
extension StripeConfig {
    static let testCards = [
        "4242424242424242", // Visa
        "4000000000000002", // Card declined
        "4000000000009995", // Insufficient funds
        "4000000000000119", // Processing error
        "4000002500003155", // Requires authentication (3D Secure 2)
    ]
    
    static let testCardInfo = """
    Use these test card numbers during development:
    
    ✅ Success: 4242 4242 4242 4242
    ❌ Declined: 4000 0000 0000 0002
    💰 Insufficient Funds: 4000 0000 0000 9995
    🔐 Requires Auth: 4000 0025 0000 3155
    
    Use any future expiry date and any 3-digit CVC.
    """
} 
