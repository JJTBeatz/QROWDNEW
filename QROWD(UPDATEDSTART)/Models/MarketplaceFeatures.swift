import Foundation
import CoreLocation
import Combine

// MARK: - Real-Time DJ Tracking System
class DJTrackingManager: ObservableObject {
    static let shared = DJTrackingManager()
    
    @Published var activeDJLocations: [String: DJLocation] = [:]
    @Published var isTracking = false
    
    private var trackingTimer: Timer?
    
    private init() {}
    
    func startTrackingDJ(djId: String, bookingId: String) {
        isTracking = true
        
        // Start periodic location updates
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            self.requestLocationUpdate(for: djId)
        }
    }
    
    func stopTracking() {
        isTracking = false
        trackingTimer?.invalidate()
        trackingTimer = nil
        activeDJLocations.removeAll()
    }
    
    func updateDJLocation(djId: String, location: CLLocation, status: DJTravelStatus) {
        let djLocation = DJLocation(
            djId: djId,
            coordinate: location.coordinate,
            status: status,
            estimatedArrival: calculateETA(for: location, status: status),
            lastUpdated: Date()
        )
        
        DispatchQueue.main.async {
            self.activeDJLocations[djId] = djLocation
        }
    }
    
    private func requestLocationUpdate(for djId: String) {
        // In a real app, this would make an API call to get DJ location
        // For now, simulate location updates
        if let existingLocation = activeDJLocations[djId] {
            // Simulate movement
            let newCoordinate = CLLocationCoordinate2D(
                latitude: existingLocation.coordinate.latitude + Double.random(in: -0.001...0.001),
                longitude: existingLocation.coordinate.longitude + Double.random(in: -0.001...0.001)
            )
            
            updateDJLocation(
                djId: djId,
                location: CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude),
                status: existingLocation.status
            )
        }
    }
    
    private func calculateETA(for location: CLLocation, status: DJTravelStatus) -> TimeInterval? {
        switch status {
        case .preparing: return 3600 // 1 hour
        case .enRoute: return 1800 // 30 minutes
        case .nearby: return 300 // 5 minutes
        case .arrived: return 0
        }
    }
}

// MARK: - Surge Pricing System
class SurgePricingManager {
    static let shared = SurgePricingManager()
    
    private init() {}
    
    func calculateSurgeMultiplier(
        for location: String,
        at dateTime: Date,
        eventType: EventType
    ) async -> SurgeInfo {
        
        let demandScore = await calculateDemandScore(location: location, dateTime: dateTime)
        let supplyScore = await calculateSupplyScore(location: location, dateTime: dateTime)
        let timeMultiplier = getTimeBasedMultiplier(dateTime: dateTime)
        let eventMultiplier = getEventTypeMultiplier(eventType: eventType)
        
        let baseMultiplier = max(1.0, demandScore / supplyScore)
        let finalMultiplier = baseMultiplier * timeMultiplier * eventMultiplier
        
        return SurgeInfo(
            multiplier: min(finalMultiplier, 3.0), // Cap at 3x
            reason: getSurgeReason(finalMultiplier),
            estimatedDuration: estimateSurgeDuration(finalMultiplier),
            affectedRadius: "5 miles"
        )
    }
    
    private func calculateDemandScore(location: String, dateTime: Date) async -> Double {
        // Mock implementation - in reality, query active bookings and searches
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: dateTime)
        let dayOfWeek = calendar.component(.weekday, from: dateTime)
        
        var score: Double = 1.0
        
        // Friday/Saturday night boost
        if dayOfWeek == 6 || dayOfWeek == 7 { // Friday or Saturday
            if hour >= 20 || hour <= 2 { // 8 PM - 2 AM
                score *= 2.5
            }
        }
        
        // Peak hours
        if hour >= 18 && hour <= 23 { // 6 PM - 11 PM
            score *= 1.5
        }
        
        return score
    }
    
    private func calculateSupplyScore(location: String, dateTime: Date) async -> Double {
        // Mock implementation - in reality, count available DJs in area
        let availableDJs = await getAvailableDJsCount(location: location, dateTime: dateTime)
        return max(1.0, Double(availableDJs) / 10.0) // Normalize to reasonable range
    }
    
    private func getTimeBasedMultiplier(dateTime: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: dateTime)
        
        if hour >= 22 || hour <= 6 { // Late night/early morning
            return 1.3
        } else if hour >= 18 && hour <= 21 { // Prime time
            return 1.2
        }
        
        return 1.0
    }
    
    private func getEventTypeMultiplier(eventType: EventType) -> Double {
        switch eventType {
        case .wedding: return 1.4
        case .corporate: return 1.2
        case .birthday: return 1.0
        case .club: return 1.3
        case .festival: return 1.5
        case .privateParty: return 1.1
        case .graduation: return 1.0
        case .anniversary: return 1.3
        case .lastMinute: return 2.0
        }
    }
    
    private func getSurgeReason(_ multiplier: Double) -> String {
        if multiplier >= 2.5 {
            return "Very high demand in your area"
        } else if multiplier >= 2.0 {
            return "High demand - peak hours"
        } else if multiplier >= 1.5 {
            return "Increased demand"
        } else {
            return "Standard pricing"
        }
    }
    
    private func estimateSurgeDuration(_ multiplier: Double) -> TimeInterval {
        if multiplier >= 2.0 {
            return 3600 * 2 // 2 hours
        } else {
            return 3600 // 1 hour
        }
    }
    
    private func getAvailableDJsCount(location: String, dateTime: Date) async -> Int {
        // Mock implementation
        return Int.random(in: 5...25)
    }
}

// MARK: - Instant Booking System
class InstantBookingManager {
    static let shared = InstantBookingManager()
    
    private init() {}
    
    func findInstantAvailableDJs(
        location: String,
        dateTime: Date,
        duration: TimeInterval,
        budget: ClosedRange<Double>
    ) async -> [InstantDJ] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Return mock instant DJs
        return [
            InstantDJ(
                id: "dj1",
                stageName: "DJ Phoenix",
                rating: 4.8,
                pricePerHour: 150,
                specialties: ["House", "Tech House", "EDM"],
                distance: 2.3,
                responseTime: 600 // 10 minutes
            ),
            InstantDJ(
                id: "dj2",
                stageName: "DJ Nova",
                rating: 4.9,
                pricePerHour: 180,
                specialties: ["Hip-Hop", "R&B", "Pop"],
                distance: 1.8,
                responseTime: 480 // 8 minutes
            ),
            InstantDJ(
                id: "dj3",
                stageName: "DJ Zara",
                rating: 4.7,
                pricePerHour: 200,
                specialties: ["Latin", "Reggaeton", "Salsa"],
                distance: 3.1,
                responseTime: 720 // 12 minutes
            ),
            InstantDJ(
                id: "dj4",
                stageName: "DJ Marcus",
                rating: 4.6,
                pricePerHour: 120,
                specialties: ["Old School", "Funk", "Soul"],
                distance: 4.2,
                responseTime: 900 // 15 minutes
            ),
            InstantDJ(
                id: "dj5",
                stageName: "DJ Luna",
                rating: 4.9,
                pricePerHour: 220,
                specialties: ["Techno", "Progressive", "Trance"],
                distance: 2.7,
                responseTime: 540 // 9 minutes
            )
        ]
    }
    
    func calculateSurgePricing(
        for location: String,
        dateTime: Date,
        basePrice: Double
    ) -> (multiplier: Double, reason: String) {
        let hour = Calendar.current.component(.hour, from: dateTime)
        let dayOfWeek = Calendar.current.component(.weekday, from: dateTime)
        
        // Weekend nights (Friday/Saturday 8PM-2AM)
        if (dayOfWeek == 6 || dayOfWeek == 7) && (hour >= 20 || hour <= 2) {
            return (3.0, "Weekend night peak demand")
        }
        
        // Friday/Saturday regular evening
        if (dayOfWeek == 6 || dayOfWeek == 7) && hour >= 18 {
            return (2.0, "Weekend evening demand")
        }
        
        // Weekday evening
        if hour >= 18 && hour <= 22 {
            return (1.5, "Evening demand")
        }
        
        // Holiday surge (would need actual holiday detection)
        if isHoliday(dateTime) {
            return (4.0, "Holiday surge pricing")
        }
        
        return (1.0, "Standard pricing")
    }
    
    private func isHoliday(_ date: Date) -> Bool {
        // Simplified holiday detection
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        // New Year's Day
        if month == 1 && day == 1 { return true }
        
        // Christmas
        if month == 12 && day == 25 { return true }
        
        // New Year's Eve
        if month == 12 && day == 31 { return true }
        
        return false
    }
    
    // MARK: - Booking Request System
    
    func createBookingRequest(
        djId: String,
        hostId: String,
        details: InstantBookingDetails,
        message: String? = nil
    ) async throws -> InstantBookingResult {
        
        // Calculate surge pricing
        let (surgeMultiplier, _) = calculateSurgePricing(
            for: details.location,
            dateTime: details.startTime,
            basePrice: details.estimatedCost
        )
        
        let finalCost = details.estimatedCost * surgeMultiplier
        
        // Create booking request
        let bookingRequest = BookingRequest(
            id: UUID().uuidString,
            djId: djId,
            hostId: hostId,
            details: details,
            estimatedCost: finalCost,
            surgeMultiplier: surgeMultiplier,
            message: message,
            status: .pending
        )
        
        // Save booking request (mock implementation)
        await saveBookingRequest(bookingRequest)
        
        // Send notification to DJ
        await sendBookingRequestNotification(to: djId, request: bookingRequest)
        
        return InstantBookingResult(
            bookingId: bookingRequest.id,
            djInfo: DJBasicInfo(id: djId, stageName: await getDJStageName(djId: djId)),
            status: .pending,
            estimatedArrival: nil, // Will be set when DJ accepts
            totalCost: finalCost,
            cancellationDeadline: nil, // Will be set when DJ accepts
            responseDeadline: bookingRequest.responseDeadline
        )
    }
    
    func respondToBookingRequest(
        requestId: String,
        djId: String,
        response: BookingRequestResponse
    ) async throws -> BookingRequest {
        
        var bookingRequest = await getBookingRequest(requestId: requestId)
        
        // Check if request is still valid
        guard bookingRequest.status == .pending else {
            throw BookingError.requestAlreadyProcessed
        }
        
        guard Date() <= bookingRequest.responseDeadline else {
            throw BookingError.requestExpired
        }
        
        // Update request status
        switch response {
        case .accepted(let estimatedArrival):
            bookingRequest = await updateBookingRequestStatus(
                requestId: requestId,
                status: .accepted,
                estimatedArrival: estimatedArrival
            )
            
            // Start tracking
            DJTrackingManager.shared.startTrackingDJ(djId: djId, bookingId: requestId)
            
            // Send confirmation to host
            await sendBookingConfirmationNotification(to: bookingRequest.hostId, request: bookingRequest)
            
        case .declined(let reason):
            bookingRequest = await updateBookingRequestStatus(
                requestId: requestId,
                status: .declined,
                declineReason: reason
            )
            
            // Send decline notification to host
            await sendBookingDeclinedNotification(to: bookingRequest.hostId, request: bookingRequest, reason: reason)
            
            // Try to find alternative DJs
            await findAlternativeDJs(for: bookingRequest)
        }
        
        return bookingRequest
    }
    
    // MARK: - Private Helper Methods
    
    private func saveBookingRequest(_ request: BookingRequest) async {
        // In a real app, this would save to database
        print("Booking request saved: \(request.id)")
    }
    
    private func sendBookingRequestNotification(to djId: String, request: BookingRequest) async {
        // Send push notification to DJ
        let message = "New booking request for \(formatDate(request.details.startTime))"
        print("Sending notification to DJ \(djId): \(message)")
        
        // In a real app, this would use NotificationManager
        // NotificationManager.shared.sendPushNotification(
        //     to: djId,
        //     title: "🎵 New Booking Request",
        //     body: message,
        //     data: ["type": "booking_request", "request_id": request.id]
        // )
    }
    
    private func sendBookingConfirmationNotification(to hostId: String, request: BookingRequest) async {
        let message = "Your booking request has been accepted!"
        print("Sending confirmation to host \(hostId): \(message)")
    }
    
    private func sendBookingDeclinedNotification(to hostId: String, request: BookingRequest, reason: String?) async {
        let message = "Your booking request was declined. We're finding alternatives."
        print("Sending decline notification to host \(hostId): \(message)")
    }
    
    private func findAlternativeDJs(for request: BookingRequest) async {
        // Find other available DJs and send new requests
        print("Finding alternative DJs for request \(request.id)")
    }
    
    private func getDJStageName(djId: String) async -> String {
        // Mock implementation
        return "DJ Phoenix"
    }
    
    private func getBookingRequest(requestId: String) async -> BookingRequest {
        // Mock implementation - in real app, fetch from database
        return BookingRequest(
            id: requestId,
            djId: "dj1",
            hostId: "host1",
            details: InstantBookingDetails(
                location: "Los Angeles",
                startTime: Date(),
                duration: 14400,
                estimatedCost: 400
            ),
            estimatedCost: 400,
            surgeMultiplier: 1.0
        )
    }
    
    private func updateBookingRequestStatus(
        requestId: String,
        status: BookingRequestStatus,
        estimatedArrival: Date? = nil,
        declineReason: String? = nil
    ) async -> BookingRequest {
        // Mock implementation - in real app, update database
        return await getBookingRequest(requestId: requestId)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Smart Matching & Recommendations
class SmartMatchingEngine {
    static let shared = SmartMatchingEngine()
    
    private init() {}
    
    func generatePersonalizedRecommendations(
        for hostId: String,
        event: EventContext
    ) async -> [SmartRecommendation] {
        
        let hostProfile = await getHostProfile(hostId: hostId)
        let pastBookings = await getHostBookingHistory(hostId: hostId)
        let preferences = await inferHostPreferences(from: pastBookings)
        
        let candidateDJs = await getAllAvailableDJs(for: event)
        
        var recommendations: [SmartRecommendation] = []
        
        for dj in candidateDJs {
            let matchScore = calculateMatchScore(
                dj: dj,
                hostProfile: hostProfile,
                preferences: preferences,
                event: event
            )
            
            let recommendation = SmartRecommendation(
                dj: dj,
                matchScore: matchScore,
                reasons: generateMatchReasons(dj: dj, preferences: preferences, event: event),
                estimatedSatisfaction: predictSatisfaction(matchScore: matchScore),
                rebookingLikelihood: calculateRebookingLikelihood(dj: dj, hostProfile: hostProfile)
            )
            
            recommendations.append(recommendation)
        }
        
        return recommendations.sorted { $0.matchScore > $1.matchScore }.prefix(10).map { $0 }
    }
    
    private func calculateMatchScore(
        dj: DJProfile,
        hostProfile: HostProfile,
        preferences: HostPreferences,
        event: EventContext
    ) -> Double {
        
        var score: Double = 0.0
        
        // Genre matching (40% weight)
        let genreMatch = calculateGenreMatch(dj.genres, preferences.preferredGenres)
        score += genreMatch * 0.4
        
        // Budget fit (25% weight)
        let djPriceRange = dj.budgetMin...dj.budgetMax
        let budgetFit = calculateBudgetFit(djPriceRange, event.budget)
        score += budgetFit * 0.25
        
        // Rating and reviews (20% weight)
        score += (dj.rating / 5.0) * 0.2
        
        // Location proximity (10% weight)
        let proximityScore = calculateProximityScore(dj.city, event.location)
        score += proximityScore * 0.1
        
        // Past booking success (5% weight) - using default since no completionRate property
        let successRate = 0.95 // Default high completion rate
        score += successRate * 0.05
        
        return min(score, 1.0)
    }
    
    private func generateMatchReasons(dj: DJProfile, preferences: HostPreferences, event: EventContext) -> [String] {
        var reasons: [String] = []
        
        if dj.genres.contains(where: { preferences.preferredGenres.contains($0) }) {
            reasons.append("Plays your favorite music styles")
        }
        
        if dj.rating >= 4.8 {
            reasons.append("Highly rated by other hosts")
        }
        
        // Using default completion rate since property doesn't exist
        if dj.rating >= 4.5 { // Using rating as proxy for reliability
            reasons.append("Extremely reliable track record")
        }
        
        // Using default availability for last-minute bookings
        if event.isLastMinute && dj.isPro {
            reasons.append("Available for last-minute bookings")
        }
        
        return reasons
    }
    
    // Helper functions with mock implementations
    private func calculateGenreMatch(_ djGenres: [String], _ preferredGenres: [String]) -> Double {
        let intersection = Set(djGenres).intersection(Set(preferredGenres))
        return Double(intersection.count) / Double(max(preferredGenres.count, 1))
    }
    
    private func calculateBudgetFit(_ djPriceRange: ClosedRange<Double>, _ budget: Double) -> Double {
        if djPriceRange.contains(budget) {
            return 1.0
        } else if budget < djPriceRange.lowerBound {
            return max(0, 1.0 - (djPriceRange.lowerBound - budget) / budget)
        } else {
            return max(0, 1.0 - (budget - djPriceRange.upperBound) / djPriceRange.upperBound)
        }
    }
    
    private func calculateProximityScore(_ djLocation: String, _ eventLocation: String) -> Double {
        // Mock implementation - would use actual distance calculation
        return 0.8
    }
    
    private func predictSatisfaction(matchScore: Double) -> Double {
        // Simple prediction model
        return 0.3 + (matchScore * 0.7)
    }
    
    private func calculateRebookingLikelihood(dj: DJProfile, hostProfile: HostProfile) -> Double {
        // Mock implementation - would use ML model
        return 0.75
    }
    
    // Mock data access functions
    private func getHostProfile(hostId: String) async -> HostProfile {
        return HostProfile(
            userId: hostId,
            firstName: "Mock",
            lastName: "Host",
            city: "Mock Location",
            typicalBudgetRange: "$1000-2500"
        )
    }
    
    private func getHostBookingHistory(hostId: String) async -> [BookingHistory] {
        return []
    }
    
    private func inferHostPreferences(from bookings: [BookingHistory]) async -> HostPreferences {
        return HostPreferences(preferredGenres: ["House", "Hip Hop"], avgBudget: 300)
    }
    
    private func getAllAvailableDJs(for event: EventContext) async -> [DJProfile] {
        return []
    }
}

// MARK: - Data Models

// MARK: - Real-Time Tracking Models

struct DJLocation {
    let djId: String
    let coordinate: CLLocationCoordinate2D
    let status: DJTravelStatus
    let estimatedArrival: TimeInterval?
    let lastUpdated: Date
    
    init(djId: String, coordinate: CLLocationCoordinate2D, status: DJTravelStatus, estimatedArrival: TimeInterval? = nil, lastUpdated: Date = Date()) {
        self.djId = djId
        self.coordinate = coordinate
        self.status = status
        self.estimatedArrival = estimatedArrival
        self.lastUpdated = lastUpdated
    }
}

enum DJTravelStatus: String, CaseIterable {
    case preparing = "preparing"
    case enRoute = "en_route"
    case nearby = "nearby"
    case arrived = "arrived"
    
    var description: String {
        switch self {
        case .preparing: return "Preparing for event"
        case .enRoute: return "On the way"
        case .nearby: return "Nearby (5 min away)"
        case .arrived: return "Arrived"
        }
    }
}

struct SurgeInfo {
    let multiplier: Double
    let reason: String
    let estimatedDuration: TimeInterval
    let affectedRadius: String
}

// EventType removed - using definition from UserModels.swift

// MARK: - Instant Booking Models

struct InstantDJ: Identifiable {
    let id: String
    let stageName: String
    let rating: Double
    let pricePerHour: Double
    let specialties: [String]
    let distance: Double
    let responseTime: TimeInterval
    let isOnline: Bool
    let availableNow: Bool
    
    init(id: String, stageName: String, rating: Double, pricePerHour: Double, specialties: [String], distance: Double, responseTime: TimeInterval, isOnline: Bool = true, availableNow: Bool = true) {
        self.id = id
        self.stageName = stageName
        self.rating = rating
        self.pricePerHour = pricePerHour
        self.specialties = specialties
        self.distance = distance
        self.responseTime = responseTime
        self.isOnline = isOnline
        self.availableNow = availableNow
    }
}

struct InstantBookingDetails {
    var location: String
    var startTime: Date
    var duration: TimeInterval
    var estimatedCost: Double
    
    init(location: String, startTime: Date, duration: TimeInterval, estimatedCost: Double) {
        self.location = location
        self.startTime = startTime
        self.duration = duration
        self.estimatedCost = estimatedCost
    }
}

struct InstantBookingResult {
    let bookingId: String
    let djInfo: DJBasicInfo
    let status: BookingRequestStatus
    let estimatedArrival: Date?
    let totalCost: Double
    let cancellationDeadline: Date?
    let responseDeadline: Date // DJ must respond by this time
    
    init(bookingId: String, djInfo: DJBasicInfo, status: BookingRequestStatus, estimatedArrival: Date?, totalCost: Double, cancellationDeadline: Date?, responseDeadline: Date) {
        self.bookingId = bookingId
        self.djInfo = djInfo
        self.status = status
        self.estimatedArrival = estimatedArrival
        self.totalCost = totalCost
        self.cancellationDeadline = cancellationDeadline
        self.responseDeadline = responseDeadline
    }
}

enum BookingStatus: String, CaseIterable {
    case pending = "pending"
    case confirmed = "confirmed"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var description: String {
        switch self {
        case .pending: return "Pending confirmation"
        case .confirmed: return "Confirmed"
        case .active: return "In progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

struct BookingRequest: Identifiable {
    let id: String
    let djId: String
    let hostId: String
    let details: InstantBookingDetails
    let estimatedCost: Double
    let surgeMultiplier: Double
    let message: String?
    let status: BookingRequestStatus
    let responseDeadline: Date
    let createdAt: Date
    
    init(id: String, djId: String, hostId: String, details: InstantBookingDetails, estimatedCost: Double, surgeMultiplier: Double, message: String? = nil, status: BookingRequestStatus = .pending) {
        self.id = id
        self.djId = djId
        self.hostId = hostId
        self.details = details
        self.estimatedCost = estimatedCost
        self.surgeMultiplier = surgeMultiplier
        self.message = message
        self.status = status
        self.responseDeadline = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        self.createdAt = Date()
    }
}

struct AutoBooking {
    let id: String
    let dj: DJBasicInfo
    let estimatedArrival: Date
    let totalCost: Double
    let status: BookingStatus
}

struct DJBasicInfo {
    let id: String
    let stageName: String
}

struct SmartRecommendation {
    let dj: DJProfile
    let matchScore: Double
    let reasons: [String]
    let estimatedSatisfaction: Double
    let rebookingLikelihood: Double
}

struct EventContext {
    let location: String
    let date: Date
    let duration: TimeInterval
    let guestCount: Int
    let budget: Double
    let eventType: EventType
    let isLastMinute: Bool
}

// DJProfile removed - using definition from SupabaseManager.swift
// HostProfile removed - using definition from UserModels.swift

struct HostPreferences {
    let preferredGenres: [String]
    let avgBudget: Double
}

struct BookingHistory {
    let djId: String
    let rating: Double
    let genres: [String]
}

enum BookingRequestStatus: String, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case expired = "expired"
    case cancelled = "cancelled"
    
    var description: String {
        switch self {
        case .pending: return "Waiting for DJ response"
        case .accepted: return "Accepted by DJ"
        case .declined: return "Declined by DJ"
        case .expired: return "Request expired"
        case .cancelled: return "Request cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .accepted: return "green"
        case .declined: return "red"
        case .expired: return "gray"
        case .cancelled: return "gray"
        }
    }
}

// BookingRequest removed - using definition from SupabaseManager.swift

enum BookingRequestResponse {
    case accepted(estimatedArrival: Date)
    case declined(reason: String?)
}

enum BookingError: Error {
    case requestAlreadyProcessed
    case requestExpired
    case djNotFound
    case hostNotFound
    case invalidRequest
    
    var description: String {
        switch self {
        case .requestAlreadyProcessed:
            return "This booking request has already been processed"
        case .requestExpired:
            return "This booking request has expired"
        case .djNotFound:
            return "DJ not found"
        case .hostNotFound:
            return "Host not found"
        case .invalidRequest:
            return "Invalid booking request"
        }
    }
} 