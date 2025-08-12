import Foundation
import SwiftUI
import os.log

// MARK: - Error Types
enum QROWDError: LocalizedError {
    case authenticationFailed(String)
    case networkError(String)
    case validationError(String)
    case paymentError(String)
    case supabaseError(String)
    case stripeError(String)
    case fileUploadError(String)
    case permissionDenied(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .paymentError(let message):
            return "Payment error: \(message)"
        case .supabaseError(let message):
            return "Database error: \(message)"
        case .stripeError(let message):
            return "Payment processing error: \(message)"
        case .fileUploadError(let message):
            return "File upload error: \(message)"
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .authenticationFailed:
            return "Unable to sign in. Please check your credentials and try again."
        case .networkError:
            return "Connection problem. Please check your internet and try again."
        case .validationError(let message):
            return message
        case .paymentError:
            return "Payment failed. Please check your payment method and try again."
        case .supabaseError:
            return "Server error. Please try again later."
        case .stripeError:
            return "Payment processing failed. Please try again."
        case .fileUploadError:
            return "Failed to upload file. Please try again."
        case .permissionDenied:
            return "Permission required. Please check your settings."
        case .unknownError:
            return "Something went wrong. Please try again."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .authenticationFailed, .permissionDenied:
            return .high
        case .paymentError, .stripeError:
            return .critical
        case .networkError, .supabaseError:
            return .medium
        case .validationError, .fileUploadError:
            return .low
        case .unknownError:
            return .high
        }
    }
}

enum ErrorSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Error Manager
@MainActor
class ErrorManager: ObservableObject {
    static let shared = ErrorManager()
    
    @Published var currentError: QROWDError?
    @Published var showingErrorAlert = false
    
    private let logger = Logger(subsystem: "com.qrowd.app", category: "ErrorManager")
    private var errorHistory: [ErrorEvent] = []
    
    private init() {}
    
    // MARK: - Public Methods
    func handleError(_ error: Error, context: String = "") {
        let qrowdError: QROWDError
        
        if let qError = error as? QROWDError {
            qrowdError = qError
        } else {
            qrowdError = .unknownError(error.localizedDescription)
        }
        
        logError(qrowdError, context: context)
        
        // Show error to user if it's user-facing
        if shouldShowToUser(qrowdError) {
            currentError = qrowdError
            showingErrorAlert = true
        }
        
        // Send to analytics (in production, send to your analytics service)
        sendToAnalytics(qrowdError, context: context)
    }
    
    func clearError() {
        currentError = nil
        showingErrorAlert = false
    }
    
    // MARK: - Private Methods
    private func logError(_ error: QROWDError, context: String) {
        let errorEvent = ErrorEvent(
            error: error,
            context: context,
            timestamp: Date(),
            userAgent: getUserAgent()
        )
        
        errorHistory.append(errorEvent)
        
        // Keep only last 100 errors
        if errorHistory.count > 100 {
            errorHistory.removeFirst()
        }
        
        // Log to system
        switch error.severity {
        case .low:
            logger.info("Error: \(error.localizedDescription ?? "Unknown") - Context: \(context)")
        case .medium:
            logger.notice("Error: \(error.localizedDescription ?? "Unknown") - Context: \(context)")
        case .high:
            logger.error("Error: \(error.localizedDescription ?? "Unknown") - Context: \(context)")
        case .critical:
            logger.critical("CRITICAL Error: \(error.localizedDescription ?? "Unknown") - Context: \(context)")
        }
    }
    
    private func shouldShowToUser(_ error: QROWDError) -> Bool {
        switch error {
        case .authenticationFailed, .validationError, .paymentError, .stripeError:
            return true
        case .networkError, .supabaseError, .fileUploadError, .permissionDenied:
            return true
        case .unknownError:
            return true
        }
    }
    
    private func sendToAnalytics(_ error: QROWDError, context: String) {
        // In production, implement your analytics service here
        // e.g., Firebase Analytics, Mixpanel, etc.
        
        let analyticsData: [String: Any] = [
            "error_type": String(describing: error),
            "error_message": error.localizedDescription ?? "Unknown",
            "severity": error.severity.rawValue,
            "context": context,
            "timestamp": Date().timeIntervalSince1970,
            "user_agent": getUserAgent()
        ]
        
        #if DEBUG
        print("📊 Analytics Event - Error:", analyticsData)
        #endif
    }
    
    private func getUserAgent() -> String {
        let device = UIDevice.current
        return "\(device.systemName) \(device.systemVersion) - \(device.model)"
    }
}

// MARK: - Error Event
private struct ErrorEvent {
    let error: QROWDError
    let context: String
    let timestamp: Date
    let userAgent: String
}

// MARK: - Error Alert View
struct ErrorAlertView: ViewModifier {
    @StateObject private var errorManager = ErrorManager.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorManager.showingErrorAlert) {
                Button("OK") {
                    errorManager.clearError()
                }
                
                if let error = errorManager.currentError, error.severity == .critical {
                    Button("Report Issue") {
                        reportIssue(error)
                        errorManager.clearError()
                    }
                }
            } message: {
                if let error = errorManager.currentError {
                    Text(error.userFriendlyMessage)
                }
            }
    }
    
    private func reportIssue(_ error: QROWDError) {
        // In production, implement issue reporting
        // e.g., open email, send to support system, etc.
        #if DEBUG
        print("🐛 Issue reported: \(error)")
        #endif
    }
}

// MARK: - View Extension
extension View {
    func withErrorHandling() -> some View {
        modifier(ErrorAlertView())
    }
}

// MARK: - Analytics Manager
@MainActor
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private let logger = Logger(subsystem: "com.qrowd.app", category: "Analytics")
    
    private init() {}
    
    // MARK: - Event Tracking
    func track(event: AnalyticsEvent, parameters: [String: Any] = [:]) {
        var eventData = parameters
        eventData["timestamp"] = Date().timeIntervalSince1970
        eventData["user_agent"] = getUserAgent()
        
        #if DEBUG
        logger.info("📊 Analytics Event: \(event.rawValue) - \(eventData)")
        #endif
        
        // In production, send to your analytics service
        sendToAnalyticsService(event: event, data: eventData)
    }
    
    func trackUserAction(_ action: String, in screen: String, parameters: [String: Any] = [:]) {
        var data = parameters
        data["action"] = action
        data["screen"] = screen
        
        track(event: .userAction, parameters: data)
    }
    
    func trackPerformance(operation: String, duration: TimeInterval) {
        track(event: .performance, parameters: [
            "operation": operation,
            "duration_ms": duration * 1000
        ])
    }
    
    private func sendToAnalyticsService(event: AnalyticsEvent, data: [String: Any]) {
        // Implement your analytics service integration here
        // Examples: Firebase Analytics, Mixpanel, Amplitude, etc.
    }
    
    private func getUserAgent() -> String {
        let device = UIDevice.current
        return "\(device.systemName) \(device.systemVersion) - \(device.model)"
    }
}

// MARK: - Analytics Events
enum AnalyticsEvent: String, CaseIterable {
    case appLaunch = "app_launch"
    case userRegistration = "user_registration"
    case profileCompleted = "profile_completed"
    case djSearchPerformed = "dj_search_performed"
    case bookingCreated = "booking_created"
    case paymentCompleted = "payment_completed"
    case proSubscribed = "pro_subscribed"
    case userAction = "user_action"
    case performance = "performance"
    case error = "error"
}

// MARK: - Performance Monitor
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var operations: [String: Date] = [:]
    private let analytics = AnalyticsManager.shared
    
    private init() {}
    
    func startOperation(_ name: String) {
        operations[name] = Date()
    }
    
    func endOperation(_ name: String) {
        guard let startTime = operations[name] else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        operations.removeValue(forKey: name)
        
        // Call analytics on main actor
        Task { @MainActor in
            analytics.trackPerformance(operation: name, duration: duration)
        }
        
        // Log slow operations
        if duration > 2.0 {
            Logger().warning("⚠️ Slow operation: \(name) took \(duration)s")
        }
    }
    
    func measureOperation<T>(_ name: String, operation: () throws -> T) rethrows -> T {
        startOperation(name)
        defer { endOperation(name) }
        return try operation()
    }
    
    func measureAsyncOperation<T>(_ name: String, operation: () async throws -> T) async rethrows -> T {
        startOperation(name)
        defer { endOperation(name) }
        return try await operation()
    }
} 