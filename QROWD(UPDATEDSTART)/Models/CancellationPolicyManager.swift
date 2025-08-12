import Foundation

// MARK: - Cancellation Policy Manager
class CancellationPolicyManager {
    static let shared = CancellationPolicyManager()
    
    private init() {}
    
    // MARK: - Cancellation Policies
    
    /// Calculate cancellation penalties and refunds based on timing and user type
    func calculateCancellationPolicy(
        for booking: BookingDetail,
        cancelledBy userType: UserType,
        at cancellationTime: Date = Date()
    ) -> CancellationResult {
        
        let timeUntilEvent = booking.eventDate.timeIntervalSince(cancellationTime)
        let hoursUntilEvent = timeUntilEvent / 3600
        
        switch userType {
        case .host:
            return calculateHostCancellationPolicy(booking: booking, hoursUntilEvent: hoursUntilEvent)
        case .dj:
            return calculateDJCancellationPolicy(booking: booking, hoursUntilEvent: hoursUntilEvent)
        }
    }
    
    // MARK: - Host Cancellation Policies
    private func calculateHostCancellationPolicy(booking: BookingDetail, hoursUntilEvent: Double) -> CancellationResult {
        let totalAmount = booking.totalPrice
        
        if hoursUntilEvent >= 48 { // 48+ hours before event
            return CancellationResult(
                refundPercentage: 1.0, // 100% refund
                penalty: 0,
                djCompensation: 0,
                reason: "Free cancellation - 48+ hours notice",
                severity: .none
            )
        } else if hoursUntilEvent >= 24 { // 24-48 hours before
            return CancellationResult(
                refundPercentage: 0.75, // 75% refund
                penalty: totalAmount * 0.25, // 25% penalty
                djCompensation: totalAmount * 0.20, // DJ gets 20% for blocked time
                reason: "Late cancellation - 24-48 hours notice",
                severity: .moderate
            )
        } else if hoursUntilEvent >= 6 { // 6-24 hours before
            return CancellationResult(
                refundPercentage: 0.50, // 50% refund
                penalty: totalAmount * 0.50, // 50% penalty
                djCompensation: totalAmount * 0.35, // DJ gets 35%
                reason: "Very late cancellation - 6-24 hours notice",
                severity: .high
            )
        } else if hoursUntilEvent >= 2 { // 2-6 hours before
            return CancellationResult(
                refundPercentage: 0.25, // 25% refund
                penalty: totalAmount * 0.75, // 75% penalty
                djCompensation: totalAmount * 0.60, // DJ gets 60%
                reason: "Last-minute cancellation - 2-6 hours notice",
                severity: .severe
            )
        } else { // Less than 2 hours or day-of
            return CancellationResult(
                refundPercentage: 0.0, // No refund
                penalty: totalAmount, // Full penalty
                djCompensation: totalAmount * 0.80, // DJ gets 80%
                reason: "Emergency cancellation - less than 2 hours notice",
                severity: .critical
            )
        }
    }
    
    // MARK: - DJ Cancellation Policies
    private func calculateDJCancellationPolicy(booking: BookingDetail, hoursUntilEvent: Double) -> CancellationResult {
        let totalAmount = booking.totalPrice
        
        if hoursUntilEvent >= 72 { // 72+ hours before event
            return CancellationResult(
                refundPercentage: 1.0, // Host gets full refund
                penalty: 0,
                djCompensation: 0,
                reason: "Early DJ cancellation - 72+ hours notice",
                severity: .none
            )
        } else if hoursUntilEvent >= 48 { // 48-72 hours before
            return CancellationResult(
                refundPercentage: 1.0, // Host gets full refund
                penalty: totalAmount * 0.10, // DJ penalty: 10% of booking
                djCompensation: 0,
                reason: "DJ cancellation - 48-72 hours notice",
                severity: .low,
                additionalConsequences: .ratingSuspension(days: 3)
            )
        } else if hoursUntilEvent >= 24 { // 24-48 hours before
            return CancellationResult(
                refundPercentage: 1.0, // Host gets full refund
                penalty: totalAmount * 0.25, // DJ penalty: 25% of booking
                djCompensation: 0,
                reason: "Late DJ cancellation - 24-48 hours notice", 
                severity: .moderate,
                additionalConsequences: .ratingSuspension(days: 7)
            )
        } else if hoursUntilEvent >= 6 { // 6-24 hours before
            return CancellationResult(
                refundPercentage: 1.0, // Host gets full refund
                penalty: totalAmount * 0.50, // DJ penalty: 50% of booking
                djCompensation: 0,
                reason: "Very late DJ cancellation - 6-24 hours notice",
                severity: .high,
                additionalConsequences: .temporaryBan(days: 14)
            )
        } else { // Less than 6 hours or day-of
            return CancellationResult(
                refundPercentage: 1.0, // Host gets full refund
                penalty: totalAmount * 1.0, // DJ penalty: 100% of booking
                djCompensation: 0,
                reason: "Emergency DJ cancellation - less than 6 hours notice",
                severity: .critical,
                additionalConsequences: .accountReview
            )
        }
    }
    
    // MARK: - Emergency & Force Majeure Handling
    func handleEmergencyCancellation(
        booking: BookingDetail,
        reason: EmergencyReason,
        evidence: [String]? = nil
    ) -> CancellationResult {
        
        switch reason {
        case .weatherEvent, .venueEmergency, .medicalEmergency:
            return CancellationResult(
                refundPercentage: 1.0,
                penalty: 0,
                djCompensation: booking.totalPrice * 0.25, // Compensation for preparation
                reason: "Emergency cancellation - \(reason.description)",
                severity: .none,
                requiresReview: false
            )
        case .equipmentFailure:
            return CancellationResult(
                refundPercentage: 1.0,
                penalty: 0,
                djCompensation: 0,
                reason: "Equipment failure - full refund provided",
                severity: .none,
                requiresReview: true
            )
        case .governmentRestrictions:
            return CancellationResult(
                refundPercentage: 1.0,
                penalty: 0,
                djCompensation: booking.totalPrice * 0.15, // Small compensation
                reason: "Government restrictions - force majeure",
                severity: .none,
                requiresReview: false
            )
        }
    }
    
    // MARK: - Repeat Offender Handling
    func evaluateRepeatOffender(userId: String, userType: UserType) async -> OffenderStatus {
        // This would query the database for cancellation history
        let recentCancellations = await getCancellationHistory(userId: userId, days: 30)
        let totalCancellations = await getTotalCancellations(userId: userId)
        
        if recentCancellations.filter({ $0.severity == .critical }).count >= 2 {
            return .temporaryBan(days: 30)
        } else if recentCancellations.count >= 3 {
            return .warning(message: "Multiple recent cancellations detected")
        } else if totalCancellations >= 10 {
            return .accountReview
        }
        
        return .clean
    }
    
    // MARK: - Protection Features
    func shouldOfferProtectionPlan(for booking: BookingDetail) -> ProtectionPlan? {
        let bookingValue = booking.totalPrice
        
        if bookingValue >= 1000 {
            return ProtectionPlan(
                cost: bookingValue * 0.05, // 5% of booking value
                coverage: .full,
                benefits: [
                    "Full refund for any cancellation reason",
                    "Emergency DJ replacement service",
                    "Equipment failure protection",
                    "Weather/venue protection"
                ]
            )
        } else if bookingValue >= 500 {
            return ProtectionPlan(
                cost: bookingValue * 0.03, // 3% of booking value
                coverage: .standard,
                benefits: [
                    "Reduced cancellation penalties",
                    "DJ replacement assistance",
                    "Equipment backup options"
                ]
            )
        }
        
        return nil
    }
}

// MARK: - Data Models

struct CancellationResult {
    let refundPercentage: Double // 0.0 - 1.0
    let penalty: Double // Amount charged as penalty
    let djCompensation: Double // Amount DJ receives as compensation
    let reason: String
    let severity: CancellationSeverity
    let additionalConsequences: UserConsequence?
    let requiresReview: Bool
    
    init(refundPercentage: Double, penalty: Double, djCompensation: Double, reason: String, severity: CancellationSeverity, additionalConsequences: UserConsequence? = nil, requiresReview: Bool = false) {
        self.refundPercentage = refundPercentage
        self.penalty = penalty
        self.djCompensation = djCompensation
        self.reason = reason
        self.severity = severity
        self.additionalConsequences = additionalConsequences
        self.requiresReview = requiresReview
    }
}

enum UserType {
    case host, dj
}

enum CancellationSeverity {
    case none, low, moderate, high, severe, critical
    
    var color: String {
        switch self {
        case .none: return "green"
        case .low: return "yellow"
        case .moderate: return "orange"
        case .high: return "red"
        case .severe: return "darkred"
        case .critical: return "purple"
        }
    }
}

enum UserConsequence {
    case ratingSuspension(days: Int)
    case temporaryBan(days: Int)
    case accountReview
    case warningIssued
    
    var description: String {
        switch self {
        case .ratingSuspension(let days):
            return "Rating suspended for \(days) days"
        case .temporaryBan(let days):
            return "Account temporarily banned for \(days) days"
        case .accountReview:
            return "Account flagged for manual review"
        case .warningIssued:
            return "Formal warning issued"
        }
    }
}

enum EmergencyReason {
    case weatherEvent, venueEmergency, medicalEmergency, equipmentFailure, governmentRestrictions
    
    var description: String {
        switch self {
        case .weatherEvent: return "Severe weather event"
        case .venueEmergency: return "Venue emergency closure"
        case .medicalEmergency: return "Medical emergency"
        case .equipmentFailure: return "Critical equipment failure"
        case .governmentRestrictions: return "Government restrictions/lockdown"
        }
    }
}

enum OffenderStatus {
    case clean
    case warning(message: String)
    case temporaryBan(days: Int)
    case accountReview
}

struct ProtectionPlan {
    let cost: Double
    let coverage: Coverage
    let benefits: [String]
    
    enum Coverage {
        case basic, standard, full
    }
}

struct BookingDetail {
    let id: String
    let totalPrice: Double
    let eventDate: Date
    let djId: String
    let hostId: String
    let status: CancellationBookingStatus
}

enum CancellationBookingStatus: String, CaseIterable {
    case pending, confirmed, inProgress, completed, cancelled
}

// MARK: - Mock Database Functions (Replace with actual implementation)
private func getCancellationHistory(userId: String, days: Int) async -> [CancellationResult] {
    // Mock implementation - replace with actual database query
    return []
}

private func getTotalCancellations(userId: String) async -> Int {
    // Mock implementation - replace with actual database query
    return 0
} 