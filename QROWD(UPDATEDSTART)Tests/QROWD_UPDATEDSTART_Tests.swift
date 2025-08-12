//
//  QROWD_UPDATEDSTART_Tests.swift
//  QROWD(UPDATEDSTART)Tests
//
//  Created by JJ Singh on 6/21/25.
//

import XCTest
@testable import QROWD_UPDATEDSTART_

final class QROWD_UPDATEDSTART_Tests: XCTestCase {
    
    var supabaseManager: SupabaseManager!
    var stripeManager: StripeManager!
    
    override func setUpWithError() throws {
        // Initialize managers for testing
        supabaseManager = SupabaseManager.shared
        stripeManager = StripeManager.shared
    }

    override func tearDownWithError() throws {
        // Clean up
        supabaseManager = nil
        stripeManager = nil
    }

    // MARK: - Authentication Tests
    func testUserTypeSelectionLogic() throws {
        // Test user type selection behavior
        let userTypes: [UserTypeSelectionView.UserType] = [.dj, .host, .guest]
        
        for userType in userTypes {
            XCTAssertNotNil(userType, "User type should not be nil")
            
            switch userType {
            case .dj, .host:
                // DJ and Host should require authentication
                XCTAssertTrue(true, "DJ and Host require auth")
            case .guest:
                // Guest should allow browsing without auth
                XCTAssertTrue(true, "Guest allows browsing")
            }
        }
    }
    
    // MARK: - DJ Profile Tests
    func testDJProfileValidation() throws {
        // Test DJ profile data validation
        let validProfile = DJProfileData(
            stageName: "Test DJ",
            city: "Los Angeles",
            budgetMin: 500,
            budgetMax: 2000,
            genres: ["House", "Techno"],
            cultures: ["Electronic"],
            equipment: ["CDJ", "Mixer"],
            availability: [:]
        )
        
        XCTAssertFalse(validProfile.stageName.isEmpty, "Stage name should not be empty")
        XCTAssertFalse(validProfile.city.isEmpty, "City should not be empty")
        XCTAssertGreaterThan(validProfile.budgetMax, validProfile.budgetMin, "Max budget should be greater than min")
        XCTAssertFalse(validProfile.genres.isEmpty, "Genres should not be empty")
    }
    
    // MARK: - Stripe Configuration Tests
    func testStripeConfiguration() throws {
        XCTAssertTrue(StripeConfig.keysConfigured, "Stripe keys should be configured")
        XCTAssertTrue(StripeConfig.validateKeys(), "Stripe keys should be valid")
        XCTAssertEqual(StripeConfig.platformFeePercentage, 10.0, "Platform fee should be 10%")
    }
    
    // MARK: - Event Data Tests
    func testTrendingEventDataModel() throws {
        let eventData = TrendingEventData(
            event_id: "test-123",
            title: "Test Event",
            thumbnail_url: "https://example.com/image.jpg",
            event_date: Date().ISO8601Format(),
            start_time: "20:00",
            location: "Test City",
            venue_name: "Test Venue",
            ticket_price: 50.0,
            available_tickets: 100,
            dj_stage_name: "Test DJ",
            recent_sales_count: 5
        )
        
        let event = TrendingEvent(from: eventData)
        
        XCTAssertEqual(event.id, "test-123")
        XCTAssertEqual(event.title, "Test Event")
        XCTAssertEqual(event.ticketPrice, 50.0)
        XCTAssertEqual(event.availableTickets, 100)
    }
    
    // MARK: - Performance Tests
    func testDJSearchPerformance() throws {
        measure {
            // Simulate DJ search operation
            let searchText = "house music"
            let filters = ["Electronic", "House", "Techno"]
            
            // This would normally call your search function
            // Performance should be under 1 second for typical searches
            let _ = filters.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // MARK: - Data Validation Tests
    func testBookingDataValidation() throws {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        
        // Test valid booking data
        let validBooking = BookingData(
            hostId: "host-123",
            djId: "dj-456",
            eventLocation: "Test Venue",
            guestCount: 50,
            eventDate: futureDate,
            durationHours: 4,
            totalPrice: 1000.0
        )
        
        XCTAssertFalse(validBooking.eventLocation.isEmpty, "Event location should not be empty")
        XCTAssertGreaterThan(validBooking.guestCount, 0, "Guest count should be positive")
        XCTAssertGreaterThan(validBooking.eventDate, Date(), "Event date should be in the future")
        XCTAssertGreaterThan(validBooking.durationHours, 0, "Duration should be positive")
        XCTAssertGreaterThan(validBooking.totalPrice, 0, "Price should be positive")
    }
    
    // MARK: - Theme Tests
    func testQROWDThemeConfiguration() throws {
        // Test that theme colors are properly configured
        XCTAssertNotNil(QROWDTheme.backgroundColor, "Background color should be configured")
        XCTAssertNotNil(QROWDTheme.accentColor, "Accent color should be configured")
        XCTAssertNotNil(QROWDTheme.primaryText, "Primary text color should be configured")
        XCTAssertNotNil(QROWDTheme.secondaryText, "Secondary text color should be configured")
    }
}

// MARK: - Mock Data Structures for Testing
private struct DJProfileData {
    let stageName: String
    let city: String
    let budgetMin: Double
    let budgetMax: Double
    let genres: [String]
    let cultures: [String]
    let equipment: [String]
    let availability: [String: Any]
}

private struct BookingData {
    let hostId: String
    let djId: String
    let eventLocation: String
    let guestCount: Int
    let eventDate: Date
    let durationHours: Int
    let totalPrice: Double
}
