import Foundation

// MARK: - User Profile Models

struct UserProfile: Codable {
    let id: String?
    let userId: String
    let userType: String
    let profileSetupComplete: Bool
    let lastActiveAt: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", userType = "user_type"
        case profileSetupComplete = "profile_setup_complete"
        case lastActiveAt = "last_active_at", createdAt = "created_at", updatedAt = "updated_at"
    }
}

struct NotificationPreferences: Codable {
    let bookingUpdates: Bool
    let messages: Bool
    let promotions: Bool
    let events: Bool
    
    private enum CodingKeys: String, CodingKey {
        case bookingUpdates = "booking_updates"
        case messages
        case promotions
        case events
    }
}

struct PrivacySettings: Codable {
    let profileVisible: Bool
    let contactInfoVisible: Bool
    let activityVisible: Bool
    
    private enum CodingKeys: String, CodingKey {
        case profileVisible = "profile_visible"
        case contactInfoVisible = "contact_info_visible"
        case activityVisible = "activity_visible"
    }
}

// MARK: - Host Models

struct HostProfile: Codable {
    let id: String?
    let userId: String
    let firstName: String
    let lastName: String
    let companyName: String?
    let phoneNumber: String?
    let city: String
    let preferredGenres: [String]
    let typicalEventTypes: [String]
    let typicalBudgetRange: String
    let instagramHandle: String?
    let websiteUrl: String?
    let profileImageUrl: String?
    let bio: String?
    let verified: Bool
    let totalBookings: Int
    let rating: Double
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", firstName = "first_name", lastName = "last_name"
        case companyName = "company_name", phoneNumber = "phone_number", city
        case preferredGenres = "preferred_genres", typicalEventTypes = "typical_event_types"
        case typicalBudgetRange = "typical_budget_range", instagramHandle = "instagram_handle"
        case websiteUrl = "website_url", profileImageUrl = "profile_image_url", bio
        case verified, totalBookings = "total_bookings", rating
        case createdAt = "created_at"
    }
    
    init(userId: String, firstName: String, lastName: String, companyName: String? = nil,
         phoneNumber: String? = nil, city: String, preferredGenres: [String] = [],
         typicalEventTypes: [String] = [], typicalBudgetRange: String,
         instagramHandle: String? = nil, websiteUrl: String? = nil) {
        self.id = nil
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.companyName = companyName
        self.phoneNumber = phoneNumber
        self.city = city
        self.preferredGenres = preferredGenres
        self.typicalEventTypes = typicalEventTypes
        self.typicalBudgetRange = typicalBudgetRange
        self.instagramHandle = instagramHandle
        self.websiteUrl = websiteUrl
        self.profileImageUrl = nil
        self.bio = nil
        self.verified = false
        self.totalBookings = 0
        self.rating = 0.0
        self.createdAt = Date().ISO8601Format()
    }
}

struct HostProfileSummary: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let companyName: String?
    let city: String
    let rating: Double
    let totalBookings: Int
    let isVerified: Bool
    
    var displayName: String {
        if let companyName = companyName, !companyName.isEmpty {
            return companyName
        }
        return "\(firstName) \(lastName)"
    }
}

// MARK: - Guest Models

struct GuestProfile: Codable {
    let id: String?
    let userId: String
    let firstName: String?
    let lastName: String?
    let city: String?
    let preferredGenres: [String]
    let instagramHandle: String?
    let profileImageUrl: String?
    let notificationsEnabled: Bool
    let eventsAttended: Int
    let favoriteVenues: [String]
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", firstName = "first_name", lastName = "last_name"
        case city, preferredGenres = "preferred_genres", instagramHandle = "instagram_handle"
        case profileImageUrl = "profile_image_url", notificationsEnabled = "notifications_enabled"
        case eventsAttended = "events_attended", favoriteVenues = "favorite_venues"
        case createdAt = "created_at"
    }
    
    init(userId: String, firstName: String? = nil, lastName: String? = nil,
         city: String? = nil, preferredGenres: [String] = [], instagramHandle: String? = nil) {
        self.id = nil
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.city = city
        self.preferredGenres = preferredGenres
        self.instagramHandle = instagramHandle
        self.profileImageUrl = nil
        self.notificationsEnabled = true
        self.eventsAttended = 0
        self.favoriteVenues = []
        self.createdAt = Date().ISO8601Format()
    }
}

// MARK: - Event Types and Budget Ranges

enum EventType: String, CaseIterable, Codable {
    case corporate = "Corporate"
    case wedding = "Wedding"
    case birthday = "Birthday"
    case club = "Nightclub"
    case festival = "Festival"
    case privateParty = "Private Party"
    case graduation = "Graduation"
    case anniversary = "Anniversary"
    case lastMinute = "Last Minute"
    
    var displayName: String {
        return self.rawValue
    }
    
    static let allTypes: [EventType] = EventType.allCases
}

struct BudgetRange {
    static let budget1 = "$100-500"
    static let budget2 = "$500-1000"
    static let budget3 = "$1000-2500"
    static let budget4 = "$2500+"
    
    static let allRanges = [budget1, budget2, budget3, budget4]
}

// MARK: - Registration Data Models
struct HostRegistrationData {
    var firstName: String = ""
    var lastName: String = ""
    var companyName: String = ""
    var phoneNumber: String = ""
    var city: String = ""
    var preferredGenres: [String] = []
    var typicalEventTypes: [String] = []
    var typicalBudgetRange: String = ""
    var instagramHandle: String = ""
    var websiteUrl: String = ""
    
    var isValid: Bool {
        return !firstName.isEmpty &&
               !lastName.isEmpty &&
               !city.isEmpty &&
               !preferredGenres.isEmpty &&
               !typicalEventTypes.isEmpty &&
               !typicalBudgetRange.isEmpty
    }
}

struct GuestRegistrationData {
    var firstName: String = ""
    var lastName: String = ""
    var city: String = ""
    var preferredGenres: [String] = []
    var instagramHandle: String = ""
}

// MARK: - Registration Options
struct RegistrationOptions {
    static let budgetRanges = [
        "$100 - $300",
        "$300 - $500", 
        "$500 - $1,000",
        "$1,000 - $2,000",
        "$2,000 - $5,000",
        "$5,000+"
    ]
    
    static let eventTypes = [
        EventType.birthday.rawValue,
        EventType.wedding.rawValue,
        EventType.corporate.rawValue,
        EventType.club.rawValue,
        EventType.privateParty.rawValue,
        EventType.festival.rawValue,
        EventType.anniversary.rawValue,
        EventType.graduation.rawValue,
        EventType.lastMinute.rawValue
    ]
} 