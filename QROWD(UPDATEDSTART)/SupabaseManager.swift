import Foundation
import Supabase
import Combine

// MARK: - Publisher Extensions
extension Publisher {
    func asyncMap<T>(_ transform: @escaping (Output) async -> T) -> AnyPublisher<T, Failure> {
        flatMap { value in
            Future<T, Failure> { promise in
                Task {
                    let result = await transform(value)
                    promise(.success(result))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - AnyEncodable Wrapper
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    
    init<T: Encodable>(_ value: T) {
        _encode = value.encode
    }
    
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// MARK: - Supabase Configuration
@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    private let supabaseURL = "https://pvfbhuobiaebzyvxjoux.supabase.co" // Your project URL
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2ZmJodW9iaWFlYnp5dnhqb3V4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAwMjIzMDMsImV4cCI6MjA2NTU5ODMwM30.8D0wFc_aEXeG_2ne_UK3NOGcCpxCP-oWXXoXvt160nU" // Replace with your actual key
    
    let client: SupabaseClient
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
        
        // Check for existing session
        Task {
            await checkAuthStatus()
        }
    }
    
    // MARK: - Authentication Methods
    func checkAuthStatus() async {
        do {
            self.currentUser = try await client.auth.user()
            self.isAuthenticated = currentUser != nil
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    @MainActor
    func signUp(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let response = try await client.auth.signUp(email: email, password: password)
        self.currentUser = response.user
        self.isAuthenticated = response.user != nil
    }
    
    @MainActor
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let response = try await client.auth.signIn(email: email, password: password)
        self.currentUser = response.user
        self.isAuthenticated = response.user != nil
    }
    
    @MainActor
    func signOut() async throws {
        do {
            try await client.auth.signOut()
            await MainActor.run {
                self.currentUser = nil
            }
            print("✅ Signed out successfully")
        } catch {
            print("❌ Sign out error: \(error)")
            throw error
        }
    }
    
    // MARK: - DJ Profile Methods
    func createDJProfile(_ profile: DJProfile) async throws {
        // Ensure user is authenticated
        guard let currentUser = self.currentUser else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Verify the profile user_id matches the authenticated user
        guard profile.userId == currentUser.id.uuidString else {
            throw NSError(domain: "Auth", code: 403, userInfo: [NSLocalizedDescriptionKey: "Profile user ID mismatch"])
        }
        
        print("DEBUG: Inserting DJ profile for authenticated user: \(currentUser.id)")
        print("DEBUG: Profile user_id: \(profile.userId)")
        
        do {
            let response = try await client
                .from("djs")
                .insert(profile)
                .execute()
            
            print("DEBUG: Insert response: \(response)")
        } catch {
            print("DEBUG: Database insert error: \(error)")
            throw error
        }
    }
    
    func updateDJProfile(_ profile: DJProfile) async throws {
        try await client
            .from("djs")
            .update(profile)
            .eq("user_id", value: profile.userId)
            .execute()
    }
    
    func checkDJProfileExists(userId: String) async throws -> Bool {
        let response: [DJProfileExistsData] = try await client
            .from("djs")
            .select("id")
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return !response.isEmpty
    }
    
    func getDJProfile(userId: String) async throws -> DJProfile {
        let response: DJProfile = try await client
            .from("djs")
            .select("*")
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value
        
        return response
    }
    
    func getDJProfileSummary(userId: String) async throws -> DJProfileSummary {
        let response: DJProfileSummaryData = try await client
            .from("djs")
            .select("id, stage_name, city, rating, is_pro, equipment, instagram_handle, soundcloud_url, stripe_account_id")
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value
        
        return DJProfileSummary(from: response)
    }
    
    // MARK: - Host Profile Methods
    func createHostProfile(_ profile: HostProfile) async throws {
        // Ensure user is authenticated
        guard let currentUser = self.currentUser else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Verify the profile user_id matches the authenticated user
        guard profile.userId == currentUser.id.uuidString else {
            throw NSError(domain: "Auth", code: 403, userInfo: [NSLocalizedDescriptionKey: "Profile user ID mismatch"])
        }
        
        print("DEBUG: Inserting Host profile for authenticated user: \(currentUser.id)")
        print("DEBUG: Profile user_id: \(profile.userId)")
        
        do {
            let response = try await client
                .from("hosts")
                .insert(profile)
                .execute()
            
            print("DEBUG: Host insert response: \(response)")
        } catch {
            print("DEBUG: Host database insert error: \(error)")
            throw error
        }
    }
    
    func updateHostProfile(_ profile: HostProfile) async throws {
        try await client
            .from("hosts")
            .update(profile)
            .eq("user_id", value: profile.userId)
            .execute()
    }
    
    func checkHostProfileExists(userId: String) async throws -> Bool {
        let response: [HostProfileExistsData] = try await client
            .from("hosts")
            .select("id")
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return !response.isEmpty
    }
    
    func getHostProfile(userId: String) async throws -> HostProfile {
        let response: HostProfile = try await client
            .from("hosts")
            .select("*")
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Guest Profile Methods
    func createGuestProfile(_ profile: GuestProfile) async throws {
        // Ensure user is authenticated
        guard let currentUser = self.currentUser else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Verify the profile user_id matches the authenticated user
        guard profile.userId == currentUser.id.uuidString else {
            throw NSError(domain: "Auth", code: 403, userInfo: [NSLocalizedDescriptionKey: "Profile user ID mismatch"])
        }
        
        print("DEBUG: Inserting Guest profile for authenticated user: \(currentUser.id)")
        print("DEBUG: Profile user_id: \(profile.userId)")
        
        do {
            let response = try await client
                .from("guests")
                .insert(profile)
                .execute()
            
            print("DEBUG: Guest insert response: \(response)")
        } catch {
            print("DEBUG: Guest database insert error: \(error)")
            throw error
        }
    }
    
    func updateGuestProfile(_ profile: GuestProfile) async throws {
        try await client
            .from("guests")
            .update(profile)
            .eq("user_id", value: profile.userId)
            .execute()
    }
    
    func checkGuestProfileExists(userId: String) async throws -> Bool {
        let response: [GuestProfileExistsData] = try await client
            .from("guests")
            .select("id")
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return !response.isEmpty
    }
    
    func getGuestProfile(userId: String) async throws -> GuestProfile {
        let response: GuestProfile = try await client
            .from("guests")
            .select("*")
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - User Profile Management
    func updateUserProfileType(userId: String, userType: String) async throws {
        try await client
            .from("user_profiles")
            .update(["user_type": userType])
            .eq("user_id", value: userId)
            .execute()
    }
    
    func getUserProfile(userId: String) async throws -> UserProfile {
        let response: UserProfile = try await client
            .from("user_profiles")
            .select("*")
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Host Search & Booking Methods
    func searchDJs(filters: DJSearchFilters) async throws -> [DJCard] {
        var query = client
            .from("djs")
            .select("id, stage_name, city, genres, rating, budget_min, promo_media_urls, is_available, is_pro")
        
        // Apply filters
        if !filters.city.isEmpty {
            query = query.ilike("city", pattern: "%\(filters.city)%")
        }
        
        if let minBudget = filters.minBudget {
            query = query.gte("budget_min", value: minBudget)
        }
        
        if let maxBudget = filters.maxBudget {
            query = query.lte("budget_max", value: maxBudget)
        }
        
        if !filters.genres.isEmpty {
            query = query.overlaps("genres", value: filters.genres)
        }
        
        if filters.availableNow {
            query = query.eq("is_available", value: true)
        }
        
        // PRO DJs get priority in search results
        let response: [DJCardData] = try await query
            .order("is_pro", ascending: false)
            .order("rating", ascending: false)
            .execute()
            .value
        return response.map { DJCard(from: $0) }
    }
    
    func getDJProfile(djId: String) async throws -> DJProfileDetail {
        let response: DJProfileDetailData = try await client
            .from("djs")
            .select()
            .eq("id", value: djId)
            .single()
            .execute()
            .value
        
        return DJProfileDetail(from: response)
    }
    
    func createBooking(_ booking: BookingRequest) async throws -> String {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let bookingData = BookingInsertData(
            host_id: booking.hostId,
            dj_id: booking.djId,
            event_location: booking.details.location,
            guest_count: 50, // Default value since not provided in new structure
            event_date: booking.details.startTime.ISO8601Format(),
            duration_hours: Int(booking.details.duration / 3600), // Convert seconds to hours
            total_price: booking.estimatedCost,
            status: booking.status.rawValue,
            special_requests: booking.message ?? ""
        )
        
        let response: BookingResponseData = try await client
            .from("bookings")
            .insert(bookingData)
            .select("id")
            .single()
            .execute()
            .value
        
        return response.id
    }
    
    // MARK: - Chat Methods
    func getChatMessages(chatId: String) async throws -> [ChatMessage] {
        let response: [ChatMessageData] = try await client
            .from("chat_messages")
            .select()
            .eq("chat_id", value: chatId)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        let currentUserId = currentUser?.id.uuidString
        return response.map { ChatMessage(from: $0, currentUserId: currentUserId) }
    }
    
    func sendMessage(chatId: String, text: String) async throws {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let messageData = MessageInsertData(
            chat_id: chatId,
            sender_id: userId.uuidString,
            text: text,
            created_at: Date().ISO8601Format()
        )
        
        try await client
            .from("chat_messages")
            .insert(messageData)
            .execute()
    }
    
    func subscribeToChatMessages(chatId: String) -> AnyPublisher<ChatMessage, Never> {
        // Create a simple polling mechanism for now
        // In a real implementation, you'd use Supabase realtime subscriptions
        return Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .asyncMap { _ in
                try? await self.getChatMessages(chatId: chatId)
            }
            .compactMap { $0 }
            .map { messages in messages.last }
            .compactMap { $0 }
            .removeDuplicates(by: { $0.id == $1.id })
            .eraseToAnyPublisher()
    }
    
    func getOrCreateChat(bookingId: String) async throws -> String {
        // First try to find existing chat
        let existingChats: [ChatData] = try await client
            .from("chats")
            .select("id")
            .eq("booking_id", value: bookingId)
            .execute()
            .value
        
        if let existingChat = existingChats.first {
            return existingChat.id
        }
        
        // Create new chat
        let chatData = ChatInsertData(
            booking_id: bookingId,
            created_at: Date().ISO8601Format()
        )
        
        let response: ChatData = try await client
            .from("chats")
            .insert(chatData)
            .select("id")
            .single()
            .execute()
            .value
        
        return response.id
    }
    
    // MARK: - File Storage Methods
    func uploadFile(data: Data, fileName: String, bucket: String = "dj-media") async throws -> String {
        // Upload the file data using the new API
        try await client.storage
            .from(bucket)
            .upload(fileName, data: data)
        
        // Get the public URL as a string
        let publicURL = try client.storage
            .from(bucket)
            .getPublicURL(path: fileName)
        
        return publicURL.absoluteString
    }
    
    // MARK: - AI Assistant Data Methods
    func getTrendingDJs() async throws -> [[String: Any]] {
        let response: [DJCardData] = try await client
            .from("djs")
            .select()
            .order("rating", ascending: false)
            .order("total_bookings", ascending: false)
            .limit(10)
            .execute()
            .value
        
        return response.map { dj in
            [
                "id": dj.id,
                "stage_name": dj.stage_name,
                "genres": dj.genres,
                "rating": dj.rating,
                "budget_min": dj.budget_min
            ]
        }
    }
    
    func getPopularVenues() async throws -> [[String: Any]] {
        // Mock data for venues since we don't have venues table yet
        return [
            [
                "id": "venue1",
                "name": "Skybar LA",
                "location": "Los Angeles, CA",
                "capacity": 200
            ],
            [
                "id": "venue2", 
                "name": "Rooftop Miami",
                "location": "Miami, FL",
                "capacity": 150
            ],
            [
                "id": "venue3",
                "name": "The Underground",
                "location": "New York, NY", 
                "capacity": 300
            ]
        ]
    }
    
    func getUpcomingEvents() async throws -> [[String: Any]] {
        // Mock data for events since we don't have events table yet
        return [
            [
                "id": "event1",
                "name": "House Music Night",
                "date": "2024-01-20",
                "venue": "Skybar LA"
            ],
            [
                "id": "event2",
                "name": "Electronic Fridays", 
                "date": "2024-01-21",
                "venue": "Rooftop Miami"
            ]
        ]
    }
    
    func getTotalDJCount() async throws -> Int {
        let response: [DJCardData] = try await client
            .from("djs")
            .select("id")
            .execute()
            .value
        
        return response.count
    }
    
    func getTotalBookings() async throws -> Int {
        // Mock data for now since bookings might be empty
        return 247 // Sample number
    }
    
    // MARK: - Events Methods
    func getTrendingEvents(limit: Int = 10) async throws -> [TrendingEvent] {
        let response: [TrendingEventData] = try await client
            .rpc("get_trending_events", params: ["limit_count": limit])
            .execute()
            .value
        
        return response.map { TrendingEvent(from: $0) }
    }
    
    func getAllPublicEvents() async throws -> [PublicEvent] {
        let response: [PublicEventData] = try await client
            .from("events")
            .select("""
                id, title, description, thumbnail_url, event_date, start_time, end_time,
                location, venue_name, ticket_price, available_tickets, total_capacity,
                status, created_at,
                djs(stage_name)
            """)
            .eq("is_public", value: true)
            .eq("status", value: "active")
            .gte("event_date", value: Date().ISO8601Format())
            .order("event_date", ascending: true)
            .execute()
            .value
        
        return response.map { PublicEvent(from: $0) }
    }
    
    func getEventDetails(eventId: String) async throws -> EventDetail {
        let response: EventDetailData = try await client
            .from("events")
            .select("""
                id, title, description, thumbnail_url, event_date, start_time, end_time,
                location, venue_name, ticket_price, available_tickets, total_capacity,
                status, platform_fee_percentage, created_at,
                djs(stage_name, genres, rating, instagram_handle)
            """)
            .eq("id", value: eventId)
            .single()
            .execute()
            .value
        
        return EventDetail(from: response)
    }
    
    func createTicketPurchase(_ ticket: TicketPurchase) async throws -> String {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let ticketData = TicketInsertData(
            user_id: userId.uuidString,
            event_id: ticket.eventId,
            ticket_quantity: ticket.quantity,
            total_amount: ticket.totalAmount,
            platform_fee: ticket.platformFee,
            host_payout: ticket.hostPayout,
            stripe_payment_intent_id: ticket.stripePaymentIntentId,
            stripe_checkout_session_id: ticket.stripeCheckoutSessionId,
            payment_status: "pending"
        )
        
        let response: TicketResponseData = try await client
            .from("user_tickets")
            .insert(ticketData)
            .select("id")
            .single()
            .execute()
            .value
        
        return response.id
    }
    
    func updateTicketPaymentStatus(ticketId: String, status: String, paymentIntentId: String) async throws {
        try await client
            .from("user_tickets")
            .update(["payment_status": status, "stripe_payment_intent_id": paymentIntentId])
            .eq("id", value: ticketId)
            .execute()
    }
    
    func getUserTickets() async throws -> [UserTicket] {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let response: [UserTicketData] = try await client
            .from("user_tickets")
            .select("""
                id, ticket_quantity, total_amount, payment_status, ticket_code,
                checked_in, created_at,
                events(title, event_date, start_time, location, venue_name, thumbnail_url)
            """)
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response.map { UserTicket(from: $0) }
    }
    
    // MARK: - PRO Subscription Methods
    func updateDJPROStatus(
        djId: String,
        isPro: Bool,
        subscriptionId: String? = nil,
        subscriptionStatus: String = "inactive",
        periodEnd: Date? = nil
    ) async throws {
        var updateData: [String: AnyEncodable] = [
            "is_pro": AnyEncodable(isPro),
            "subscription_status": AnyEncodable(subscriptionStatus)
        ]
        
        if let subscriptionId = subscriptionId {
            updateData["stripe_subscription_id"] = AnyEncodable(subscriptionId)
        }
        
        if let periodEnd = periodEnd {
            updateData["subscription_period_end"] = AnyEncodable(periodEnd.ISO8601Format())
        }
        
        // Enable all PRO features when upgrading
        if isPro {
            updateData["pro_features_enabled"] = AnyEncodable([
                "verified_badge": true,
                "auto_chat_replies": true,
                "booking_analytics": true,
                "scheduled_boosts": true,
                "priority_search": true
            ])
            updateData["boost_credits"] = AnyEncodable(5) // Give 5 boost credits on upgrade
        } else {
            // Disable all PRO features when downgrading
            updateData["pro_features_enabled"] = AnyEncodable([
                "verified_badge": false,
                "auto_chat_replies": false,
                "booking_analytics": false,
                "scheduled_boosts": false,
                "priority_search": false
            ])
            updateData["boost_credits"] = AnyEncodable(0)
        }
        
        try await client
            .from("djs")
            .update(updateData)
            .eq("id", value: djId)
            .execute()
    }
    
    func getDJPROStatus(djId: String) async throws -> DJPROStatus {
        let response: DJPROStatusData = try await client
            .from("djs")
            .select("is_pro, stripe_subscription_id, subscription_status, subscription_period_end, pro_features_enabled, boost_credits")
            .eq("id", value: djId)
            .single()
            .execute()
            .value
        
        return DJPROStatus(from: response)
    }
    
    func getCurrentUserDJProfile() async throws -> DJProfileDetail? {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let response: [DJProfileDetailData] = try await client
            .from("djs")
            .select("*, is_pro")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        return response.first.map { DJProfileDetail(from: $0) }
    }
    
    func useDJBoostCredit(djId: String) async throws {
        // Get current boost credits
        let response: DJBoostData = try await client
            .from("djs")
            .select("boost_credits")
            .eq("id", value: djId)
            .single()
            .execute()
            .value
        
        guard response.boost_credits > 0 else {
            throw NSError(domain: "PRO", code: 400, userInfo: [NSLocalizedDescriptionKey: "No boost credits available"])
        }
        
        // Use one credit and update last boost date
        try await client
            .from("djs")
            .update([
                "boost_credits": AnyEncodable(response.boost_credits - 1),
                "last_boost_date": AnyEncodable(Date().ISO8601Format())
            ])
            .eq("id", value: djId)
            .execute()
    }
    
    // MARK: - Session Management
    
    func refreshSession() async throws {
        do {
            _ = try await client.auth.refreshSession()
            print("✅ Session refreshed successfully")
        } catch {
            print("❌ Failed to refresh session: \(error)")
            throw error
        }
    }
}

// MARK: - DJ Profile Model
struct DJProfile: Codable {
    let id: String?
    let userId: String
    let stageName: String
    let city: String
    let genres: [String]
    let budgetMin: Double
    let budgetMax: Double
    let equipment: [String]
    let availability: [String: [String]]
    let instagramHandle: String?
    let soundcloudUrl: String?
    let stripeAccountId: String?
    let audioPromoUrl: String?
    let videoPromoUrl: String?
    let bio: String?
    let profileImageUrl: String?
    let rating: Double
    let isPro: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", stageName = "stage_name", city, genres
        case budgetMin = "budget_min", budgetMax = "budget_max", equipment
        case availability, instagramHandle = "instagram_handle", soundcloudUrl = "soundcloud_url"
        case stripeAccountId = "stripe_account_id"
        case audioPromoUrl = "audio_promo_url", videoPromoUrl = "video_promo_url"
        case bio, profileImageUrl = "profile_image_url", rating, isPro = "is_pro"
    }
}

struct DJSearchFilters {
    var city: String = ""
    var minBudget: Double?
    var maxBudget: Double?
    var genres: [String] = []
    var guestCount: Int?
    var eventDate: Date?
    var availableNow: Bool = false
}

struct DJCard: Identifiable {
    let id: String
    let stageName: String
    let city: String
    let genres: [String]
    let rating: Double
    let pricePerHour: Double
    let thumbnailURL: String?
    let isAvailable: Bool
    let isPro: Bool
    
    init(from data: DJCardData) {
        self.id = data.id
        self.stageName = data.stage_name
        self.city = data.city
        self.genres = data.genres
        self.rating = data.rating
        self.pricePerHour = data.budget_min
        self.thumbnailURL = data.promo_media_urls.first
        self.isAvailable = data.is_available
        self.isPro = data.is_pro
    }
}

struct DJProfileDetail: Identifiable {
    let id: String
    let stageName: String
    let city: String
    let genres: [String]
    let cultures: [String]
    let equipment: [String]
    let rating: Double
    let totalBookings: Int
    let priceRange: String
    let promoMediaURLs: [String]
    let instagramHandle: String
    let soundcloudURL: String
    let availability: [String: [String]]
    let isPro: Bool
    
    init(from data: DJProfileDetailData) {
        self.id = data.id
        self.stageName = data.stage_name
        self.city = data.city
        self.genres = data.genres
        self.cultures = data.cultures
        self.equipment = data.equipment
        self.rating = data.rating
        self.totalBookings = data.total_bookings
        self.priceRange = "$\(Int(data.budget_min)) - $\(Int(data.budget_max))"
        self.promoMediaURLs = data.promo_media_urls
        self.instagramHandle = data.instagram_handle
        self.soundcloudURL = data.soundcloud_url
        self.availability = data.availability
        self.isPro = data.is_pro
    }
}



struct ChatMessage: Identifiable {
    let id: String
    let chatId: String
    let senderId: String
    let text: String
    let createdAt: Date
    var isFromCurrentUser: Bool
    
    init(from data: ChatMessageData, currentUserId: String? = nil) {
        self.id = data.id
        self.chatId = data.chat_id
        self.senderId = data.sender_id
        self.text = data.text
        self.createdAt = ISO8601DateFormatter().date(from: data.created_at) ?? Date()
        self.isFromCurrentUser = currentUserId != nil && data.sender_id == currentUserId
    }
}

// MARK: - Codable Data Structures
struct DJCardData: Codable {
    let id: String
    let stage_name: String
    let city: String
    let genres: [String]
    let rating: Double
    let budget_min: Double
    let promo_media_urls: [String]
    let is_available: Bool
    let is_pro: Bool
}

struct DJProfileDetailData: Codable {
    let id: String
    let stage_name: String
    let city: String
    let genres: [String]
    let cultures: [String]
    let equipment: [String]
    let rating: Double
    let total_bookings: Int
    let budget_min: Double
    let budget_max: Double
    let promo_media_urls: [String]
    let instagram_handle: String
    let soundcloud_url: String
    let availability: [String: [String]]
    let is_pro: Bool
}

struct BookingResponseData: Codable {
    let id: String
}

struct ChatMessageData: Codable {
    let id: String
    let chat_id: String
    let sender_id: String
    let text: String
    let created_at: String
}

struct ChatData: Codable {
    let id: String
}

// MARK: - Insert Data Structures
struct BookingInsertData: Codable {
    let host_id: String
    let dj_id: String
    let event_location: String
    let guest_count: Int
    let event_date: String
    let duration_hours: Int
    let total_price: Double
    let status: String
    let special_requests: String
}

struct MessageInsertData: Codable {
    let chat_id: String
    let sender_id: String
    let text: String
    let created_at: String
}

struct ChatInsertData: Codable {
    let booking_id: String
    let created_at: String
}

// MARK: - Event Data Models
struct TrendingEvent: Identifiable {
    let id: String
    let title: String
    let thumbnailURL: String?
    let eventDate: Date
    let startTime: String
    let location: String
    let venueName: String
    let ticketPrice: Double
    let availableTickets: Int
    let djStageName: String?
    let recentSalesCount: Int
    
    init(from data: TrendingEventData) {
        self.id = data.event_id
        self.title = data.title
        self.thumbnailURL = data.thumbnail_url
        self.eventDate = ISO8601DateFormatter().date(from: data.event_date) ?? Date()
        self.startTime = data.start_time
        self.location = data.location
        self.venueName = data.venue_name ?? ""
        self.ticketPrice = data.ticket_price
        self.availableTickets = data.available_tickets
        self.djStageName = data.dj_stage_name
        self.recentSalesCount = data.recent_sales_count
    }
}

struct PublicEvent: Identifiable {
    let id: String
    let title: String
    let description: String
    let thumbnailURL: String?
    let eventDate: Date
    let startTime: String
    let endTime: String?
    let location: String
    let venueName: String
    let ticketPrice: Double
    let availableTickets: Int
    let totalCapacity: Int
    let status: String
    let djStageName: String?
    let createdAt: Date
    
    init(from data: PublicEventData) {
        self.id = data.id
        self.title = data.title
        self.description = data.description ?? ""
        self.thumbnailURL = data.thumbnail_url
        self.eventDate = ISO8601DateFormatter().date(from: data.event_date) ?? Date()
        self.startTime = data.start_time
        self.endTime = data.end_time
        self.location = data.location
        self.venueName = data.venue_name ?? ""
        self.ticketPrice = data.ticket_price
        self.availableTickets = data.available_tickets
        self.totalCapacity = data.total_capacity
        self.status = data.status
        self.djStageName = data.djs?.stage_name
        self.createdAt = ISO8601DateFormatter().date(from: data.created_at) ?? Date()
    }
}

struct EventDetail: Identifiable {
    let id: String
    let title: String
    let description: String
    let thumbnailURL: String?
    let eventDate: Date
    let startTime: String
    let endTime: String?
    let location: String
    let venueName: String
    let ticketPrice: Double
    let availableTickets: Int
    let totalCapacity: Int
    let status: String
    let platformFeePercentage: Double
    let dj: EventDJ?
    let createdAt: Date
    
    init(from data: EventDetailData) {
        self.id = data.id
        self.title = data.title
        self.description = data.description ?? ""
        self.thumbnailURL = data.thumbnail_url
        self.eventDate = ISO8601DateFormatter().date(from: data.event_date) ?? Date()
        self.startTime = data.start_time
        self.endTime = data.end_time
        self.location = data.location
        self.venueName = data.venue_name ?? ""
        self.ticketPrice = data.ticket_price
        self.availableTickets = data.available_tickets
        self.totalCapacity = data.total_capacity
        self.status = data.status
        self.platformFeePercentage = data.platform_fee_percentage
        self.dj = data.djs.map { EventDJ(from: $0) }
        self.createdAt = ISO8601DateFormatter().date(from: data.created_at) ?? Date()
    }
}

struct EventDJ {
    let stageName: String
    let genres: [String]
    let rating: Double
    let instagramHandle: String
    
    init(from data: EventDJData) {
        self.stageName = data.stage_name
        self.genres = data.genres
        self.rating = data.rating
        self.instagramHandle = data.instagram_handle
    }
}

struct TicketPurchase {
    let eventId: String
    let quantity: Int
    let totalAmount: Double
    let platformFee: Double
    let hostPayout: Double
    let stripePaymentIntentId: String
    let stripeCheckoutSessionId: String?
}

struct UserTicket: Identifiable {
    let id: String
    let quantity: Int
    let totalAmount: Double
    let paymentStatus: String
    let ticketCode: String
    let checkedIn: Bool
    let eventTitle: String
    let eventDate: Date
    let eventStartTime: String
    let eventLocation: String
    let eventVenueName: String
    let eventThumbnailURL: String?
    let purchaseDate: Date
    
    init(from data: UserTicketData) {
        self.id = data.id
        self.quantity = data.ticket_quantity
        self.totalAmount = data.total_amount
        self.paymentStatus = data.payment_status
        self.ticketCode = data.ticket_code
        self.checkedIn = data.checked_in
        self.eventTitle = data.events.title
        self.eventDate = ISO8601DateFormatter().date(from: data.events.event_date) ?? Date()
        self.eventStartTime = data.events.start_time
        self.eventLocation = data.events.location
        self.eventVenueName = data.events.venue_name ?? ""
        self.eventThumbnailURL = data.events.thumbnail_url
        self.purchaseDate = ISO8601DateFormatter().date(from: data.created_at) ?? Date()
    }
}

// MARK: - Codable Data Structures for Events
struct TrendingEventData: Codable {
    let event_id: String
    let title: String
    let thumbnail_url: String?
    let event_date: String
    let start_time: String
    let location: String
    let venue_name: String?
    let ticket_price: Double
    let available_tickets: Int
    let dj_stage_name: String?
    let recent_sales_count: Int
}

struct PublicEventData: Codable {
    let id: String
    let title: String
    let description: String?
    let thumbnail_url: String?
    let event_date: String
    let start_time: String
    let end_time: String?
    let location: String
    let venue_name: String?
    let ticket_price: Double
    let available_tickets: Int
    let total_capacity: Int
    let status: String
    let created_at: String
    let djs: DJBasicData?
}

struct EventDetailData: Codable {
    let id: String
    let title: String
    let description: String?
    let thumbnail_url: String?
    let event_date: String
    let start_time: String
    let end_time: String?
    let location: String
    let venue_name: String?
    let ticket_price: Double
    let available_tickets: Int
    let total_capacity: Int
    let status: String
    let platform_fee_percentage: Double
    let created_at: String
    let djs: EventDJData?
}

struct DJBasicData: Codable {
    let stage_name: String
}

struct EventDJData: Codable {
    let stage_name: String
    let genres: [String]
    let rating: Double
    let instagram_handle: String
}

struct TicketInsertData: Codable {
    let user_id: String
    let event_id: String
    let ticket_quantity: Int
    let total_amount: Double
    let platform_fee: Double
    let host_payout: Double
    let stripe_payment_intent_id: String
    let stripe_checkout_session_id: String?
    let payment_status: String
}

struct TicketResponseData: Codable {
    let id: String
}

struct UserTicketData: Codable {
    let id: String
    let ticket_quantity: Int
    let total_amount: Double
    let payment_status: String
    let ticket_code: String
    let checked_in: Bool
    let created_at: String
    let events: UserTicketEventData
}

struct UserTicketEventData: Codable {
    let title: String
    let event_date: String
    let start_time: String
    let location: String
    let venue_name: String?
    let thumbnail_url: String?
}

// MARK: - PRO Subscription Models
struct DJPROStatus {
    let isPro: Bool
    let subscriptionId: String
    let subscriptionStatus: String
    let subscriptionPeriodEnd: Date?
    let features: PROFeatures
    let boostCredits: Int
    
    init(from data: DJPROStatusData) {
        self.isPro = data.is_pro
        self.subscriptionId = data.stripe_subscription_id
        self.subscriptionStatus = data.subscription_status
        
        if let periodEndString = data.subscription_period_end {
            self.subscriptionPeriodEnd = ISO8601DateFormatter().date(from: periodEndString)
        } else {
            self.subscriptionPeriodEnd = nil
        }
        
        self.features = PROFeatures(from: data.pro_features_enabled)
        self.boostCredits = data.boost_credits
    }
    
    var isActive: Bool {
        return isPro && subscriptionStatus == "active"
    }
    
    var formattedPeriodEnd: String {
        guard let periodEnd = subscriptionPeriodEnd else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: periodEnd)
    }
}

struct DJPROStatusData: Codable {
    let is_pro: Bool
    let stripe_subscription_id: String
    let subscription_status: String
    let subscription_period_end: String?
    let pro_features_enabled: [String: Bool]
    let boost_credits: Int
}

struct DJBoostData: Codable {
    let boost_credits: Int
}

// MARK: - Data Models

// DJ Profile Models
struct DJProfileExistsData: Codable {
    let id: String
}

struct HostProfileExistsData: Codable {
    let id: String
}

struct GuestProfileExistsData: Codable {
    let id: String
}

struct DJProfileSummary {
    let id: String
    let stageName: String
    let city: String
    let rating: Double
    let isPro: Bool
    let isProfileComplete: Bool
    
    init(from data: DJProfileSummaryData) {
        self.id = data.id
        self.stageName = data.stage_name
        self.city = data.city
        self.rating = data.rating
        self.isPro = data.is_pro
        
        // Calculate profile completion based on available data
        let hasEquipment = !data.equipment.isEmpty
        let hasSocialLinks = data.instagram_handle != nil || data.soundcloud_url != nil
        let hasStripeAccount = data.stripe_account_id != nil && !data.stripe_account_id!.isEmpty
        
        self.isProfileComplete = hasEquipment && hasSocialLinks && hasStripeAccount
    }
}

struct DJProfileSummaryData: Codable {
    let id: String
    let stage_name: String
    let city: String
    let rating: Double
    let is_pro: Bool
    let equipment: [String]
    let instagram_handle: String?
    let soundcloud_url: String?
    let stripe_account_id: String?
}

struct DJSocialLinks: Codable {
    let instagram: String?
    let soundcloud: String?
    let website: String?
}
