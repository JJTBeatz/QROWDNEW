import Foundation
import UIKit
import Stripe
import StripePaymentSheet

@MainActor
class StripeManager: ObservableObject {
    static let shared = StripeManager()
    
    private let publishableKey = StripeConfig.currentPublishableKey
    private let secretKey = StripeConfig.currentSecretKey
    
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    
    private init() {
        StripeAPI.defaultPublishableKey = publishableKey
    }
    
    // MARK: - Create Payment Intent for Event Tickets
    func createPaymentIntent(
        for event: EventDetail,
        quantity: Int,
        connectedAccountId: String?
    ) async throws -> (clientSecret: String, paymentIntentId: String) {
        
        let ticketPrice = event.ticketPrice
        let subtotal = ticketPrice * Double(quantity)
        let platformFee = subtotal * (event.platformFeePercentage / 100.0)
        let totalAmount = subtotal + platformFee
        
        // Convert to cents for Stripe
        let amountInCents = Int(totalAmount * 100)
        let platformFeeInCents = Int(platformFee * 100)
        
        var parameters: [String: Any] = [
            "amount": amountInCents,
            "currency": "usd",
            "payment_method_types": ["card"],
            "metadata": [
                "event_id": event.id,
                "event_title": event.title,
                "ticket_quantity": quantity,
                "platform_fee": platformFeeInCents
            ]
        ]
        
        // If we have a connected account, use Stripe Connect
        if let connectedAccountId = connectedAccountId {
            parameters["transfer_data"] = [
                "destination": connectedAccountId
            ]
            parameters["application_fee_amount"] = platformFeeInCents
        }
        
        let response = try await makeStripeAPICall(
            endpoint: "payment_intents",
            method: "POST",
            parameters: parameters
        )
        
        guard let clientSecret = response["client_secret"] as? String,
              let paymentIntentId = response["id"] as? String else {
            throw StripeError.invalidResponse
        }
        
        return (clientSecret: clientSecret, paymentIntentId: paymentIntentId)
    }
    
    // MARK: - Create Checkout Session
    func createCheckoutSession(
        for event: EventDetail,
        quantity: Int,
        connectedAccountId: String?,
        successURL: String,
        cancelURL: String
    ) async throws -> String {
        
        let ticketPrice = event.ticketPrice
        let subtotal = ticketPrice * Double(quantity)
        let platformFee = subtotal * (event.platformFeePercentage / 100.0)
        
        // Create price in cents
        let priceInCents = Int(ticketPrice * 100)
        let platformFeeInCents = Int(platformFee * 100)
        
        var parameters: [String: Any] = [
            "payment_method_types": ["card"],
            "line_items": [[
                "price_data": [
                    "currency": "usd",
                    "product_data": [
                        "name": event.title,
                        "description": "Event at \(event.venueName), \(event.location)",
                        "images": event.thumbnailURL.map { [$0] } ?? []
                    ],
                    "unit_amount": priceInCents
                ],
                "quantity": quantity
            ]],
            "mode": "payment",
            "success_url": successURL,
            "cancel_url": cancelURL,
            "metadata": [
                "event_id": event.id,
                "event_title": event.title,
                "ticket_quantity": quantity,
                "platform_fee": platformFeeInCents
            ]
        ]
        
        // Add platform fee as a separate line item
        if platformFee > 0 {
            var lineItems = parameters["line_items"] as! [[String: Any]]
            lineItems.append([
                "price_data": [
                    "currency": "usd",
                    "product_data": [
                        "name": "Service Fee",
                        "description": "QROWD platform fee"
                    ],
                    "unit_amount": Int(platformFee * 100)
                ],
                "quantity": 1
            ])
            parameters["line_items"] = lineItems
        }
        
        // Handle Stripe Connect if host has connected account
        if let connectedAccountId = connectedAccountId {
            parameters["payment_intent_data"] = [
                "transfer_data": [
                    "destination": connectedAccountId
                ],
                "application_fee_amount": platformFeeInCents
            ]
        }
        
        let response = try await makeStripeAPICall(
            endpoint: "checkout/sessions",
            method: "POST",
            parameters: parameters
        )
        
        guard let sessionId = response["id"] as? String else {
            throw StripeError.invalidResponse
        }
        
        return sessionId
    }
    
    // MARK: - Payment Sheet Configuration
    func configurePaymentSheet(
        paymentIntentClientSecret: String,
        customerID: String? = nil
    ) {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "QROWD"
        configuration.customer = customerID.map { PaymentSheet.CustomerConfiguration(id: $0, ephemeralKeySecret: "") }
        
        // Configure appearance
        configuration.appearance.colors.primary = UIColor(red: 0.98, green: 0.27, blue: 0.46, alpha: 1.0) // QROWDTheme accent color
        configuration.appearance.cornerRadius = 12.0
        
        self.paymentSheet = PaymentSheet(
            paymentIntentClientSecret: paymentIntentClientSecret,
            configuration: configuration
        )
    }
    
    // MARK: - Handle Payment Result
    func handlePaymentResult(_ result: PaymentSheetResult) {
        DispatchQueue.main.async {
            self.paymentResult = result
        }
    }
    
    // MARK: - PRO Subscription Methods
    func createPROSubscription(
        customerId: String,
        priceId: String = "price_1RcZQzPwdjwFbzEkCDQsJNqw" // ⚠️ UPDATE: Replace with $14.99/month Price ID
    ) async throws -> String {
        
        let parameters: [String: Any] = [
            "customer": customerId,
            "items": [[
                "price": priceId
            ]],
            "payment_behavior": "default_incomplete",
            "payment_settings": [
                "save_default_payment_method": "on_subscription"
            ],
            "expand": ["latest_invoice.payment_intent"],
            "metadata": [
                "subscription_type": "dj_pro",
                "platform": "qrowd"
            ]
        ]
        
        let response = try await makeStripeAPICall(
            endpoint: "subscriptions",
            method: "POST",
            parameters: parameters
        )
        
        guard let subscriptionId = response["id"] as? String else {
            throw StripeError.invalidResponse
        }
        
        return subscriptionId
    }
    
    func createPROCheckoutSession(
        customerId: String? = nil,
        successURL: String,
        cancelURL: String
    ) async throws -> String {
        
        var parameters: [String: Any] = [
            "payment_method_types": ["card"],
            "line_items": [[
                "price": "price_1RcZQzPwdjwFbzEkCDQsJNqw", // ⚠️ UPDATE: Replace with $14.99/month Price ID
                "quantity": 1
            ]],
            "mode": "subscription",
            "success_url": successURL,
            "cancel_url": cancelURL,
            "metadata": [
                "subscription_type": "dj_pro",
                "platform": "qrowd"
            ]
        ]
        
        if let customerId = customerId {
            parameters["customer"] = customerId
        }
        
        let response = try await makeStripeAPICall(
            endpoint: "checkout/sessions",
            method: "POST",
            parameters: parameters
        )
        
        guard let sessionId = response["id"] as? String else {
            throw StripeError.invalidResponse
        }
        
        return sessionId
    }
    
    func getSubscriptionStatus(subscriptionId: String) async throws -> SubscriptionStatus {
        let response = try await makeStripeAPICall(
            endpoint: "subscriptions/\(subscriptionId)",
            method: "GET",
            parameters: [:]
        )
        
        guard let status = response["status"] as? String,
              let currentPeriodEnd = response["current_period_end"] as? TimeInterval else {
            throw StripeError.invalidResponse
        }
        
        return SubscriptionStatus(
            id: subscriptionId,
            status: status,
            currentPeriodEnd: Date(timeIntervalSince1970: currentPeriodEnd),
            isActive: status == "active"
        )
    }
    
    func cancelSubscription(subscriptionId: String) async throws {
        _ = try await makeStripeAPICall(
            endpoint: "subscriptions/\(subscriptionId)",
            method: "DELETE",
            parameters: [:]
        )
    }
    
    func createCustomer(email: String, name: String) async throws -> String {
        let parameters: [String: Any] = [
            "email": email,
            "name": name,
            "metadata": [
                "platform": "qrowd",
                "user_type": "dj"
            ]
        ]
        
        let response = try await makeStripeAPICall(
            endpoint: "customers",
            method: "POST",
            parameters: parameters
        )
        
        guard let customerId = response["id"] as? String else {
            throw StripeError.invalidResponse
        }
        
        return customerId
    }
    
    // MARK: - Stripe Connect Account Creation
    func createConnectAccount(
        for hostId: String,
        email: String,
        businessType: String = "individual"
    ) async throws -> String {
        
        let parameters: [String: Any] = [
            "type": "express",
            "country": "US",
            "email": email,
            "capabilities": [
                "card_payments": ["requested": true],
                "transfers": ["requested": true]
            ],
            "business_type": businessType,
            "metadata": [
                "host_id": hostId,
                "platform": "qrowd"
            ]
        ]
        
        let response = try await makeStripeAPICall(
            endpoint: "accounts",
            method: "POST",
            parameters: parameters
        )
        
        guard let accountId = response["id"] as? String else {
            throw StripeError.invalidResponse
        }
        
        return accountId
    }
    
    // MARK: - Create Account Link for Onboarding
    func createAccountLink(
        accountId: String,
        refreshURL: String,
        returnURL: String
    ) async throws -> String {
        
        let parameters: [String: Any] = [
            "account": accountId,
            "refresh_url": refreshURL,
            "return_url": returnURL,
            "type": "account_onboarding"
        ]
        
        let response = try await makeStripeAPICall(
            endpoint: "account_links",
            method: "POST",
            parameters: parameters
        )
        
        guard let url = response["url"] as? String else {
            throw StripeError.invalidResponse
        }
        
        return url
    }
    
    // MARK: - Verify Payment Status
    func verifyPaymentIntent(paymentIntentId: String) async throws -> PaymentIntentStatus {
        let response = try await makeStripeAPICall(
            endpoint: "payment_intents/\(paymentIntentId)",
            method: "GET",
            parameters: [:]
        )
        
        guard let status = response["status"] as? String else {
            throw StripeError.invalidResponse
        }
        
        return PaymentIntentStatus(rawValue: status) ?? .unknown
    }
    
    // MARK: - Private API Helper
    private func makeStripeAPICall(
        endpoint: String,
        method: String,
        parameters: [String: Any]
    ) async throws -> [String: Any] {
        
        guard let url = URL(string: "https://api.stripe.com/v1/\(endpoint)") else {
            throw StripeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        if !parameters.isEmpty {
            let bodyString = parameters.map { key, value in
                if let dict = value as? [String: Any] {
                    return dict.map { "\(key)[\($0.key)]=\($0.value)" }.joined(separator: "&")
                } else if let array = value as? [Any] {
                    return array.enumerated().map { "\(key)[\($0.offset)]=\($0.element)" }.joined(separator: "&")
                } else {
                    return "\(key)=\(value)"
                }
            }.joined(separator: "&")
            
            request.httpBody = bodyString.data(using: .utf8)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StripeError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw StripeError.apiError(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw StripeError.invalidResponse
        }
        
        return json
    }
}

// MARK: - Supporting Types
enum StripeError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError
    case apiError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from Stripe"
        case .networkError:
            return "Network error"
        case .apiError(let code):
            return "Stripe API error: \(code)"
        }
    }
}

enum PaymentIntentStatus: String {
    case succeeded = "succeeded"
    case pending = "requires_payment_method"
    case canceled = "canceled"
    case failed = "payment_failed"
    case unknown = "unknown"
}

// MARK: - Subscription Models
struct SubscriptionStatus {
    let id: String
    let status: String
    let currentPeriodEnd: Date
    let isActive: Bool
}

struct PROFeatures {
    let verifiedBadge: Bool
    let autoChatReplies: Bool
    let bookingAnalytics: Bool
    let scheduledBoosts: Bool
    let prioritySearch: Bool
    
    init(from json: [String: Bool]) {
        self.verifiedBadge = json["verified_badge"] ?? false
        self.autoChatReplies = json["auto_chat_replies"] ?? false
        self.bookingAnalytics = json["booking_analytics"] ?? false
        self.scheduledBoosts = json["scheduled_boosts"] ?? false
        self.prioritySearch = json["priority_search"] ?? false
    }
    
    func toDictionary() -> [String: Bool] {
        return [
            "verified_badge": verifiedBadge,
            "auto_chat_replies": autoChatReplies,
            "booking_analytics": bookingAnalytics,
            "scheduled_boosts": scheduledBoosts,
            "priority_search": prioritySearch
        ]
    }
}

// MARK: - Ticket Purchase Helper
struct TicketPurchaseCalculation {
    let subtotal: Double
    let platformFee: Double
    let total: Double
    let hostPayout: Double
    
    init(ticketPrice: Double, quantity: Int, platformFeePercentage: Double) {
        self.subtotal = ticketPrice * Double(quantity)
        self.platformFee = subtotal * (platformFeePercentage / 100.0)
        self.total = subtotal + platformFee
        self.hostPayout = subtotal
    }
    
    var formattedSubtotal: String {
        String(format: "$%.2f", subtotal)
    }
    
    var formattedPlatformFee: String {
        String(format: "$%.2f", platformFee)
    }
    
    var formattedTotal: String {
        String(format: "$%.2f", total)
    }
    
    var formattedHostPayout: String {
        String(format: "$%.2f", hostPayout)
    }
} 