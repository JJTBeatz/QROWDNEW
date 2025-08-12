import Foundation
import SwiftUI
import StripePaymentSheet

@MainActor
class TrendingEventsViewModel: ObservableObject {
    @Published var trendingEvents: [TrendingEvent] = []
    @Published var allPublicEvents: [PublicEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedEvent: TrendingEvent?
    
    private let supabaseManager = SupabaseManager.shared
    
    // MARK: - Load Trending Events
    func loadTrendingEvents(limit: Int = 10) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let events = try await supabaseManager.getTrendingEvents(limit: limit)
            trendingEvents = events
        } catch {
            errorMessage = "Failed to load trending events: \(error.localizedDescription)"
            print("Error loading trending events: \(error)")
            
            // Load mock data for demo purposes
            trendingEvents = createMockTrendingEvents()
        }
        
        isLoading = false
    }
    
    // MARK: - Load All Public Events
    func loadAllPublicEvents() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let events = try await supabaseManager.getAllPublicEvents()
            allPublicEvents = events
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
            print("Error loading public events: \(error)")
            
            // Load mock data for demo purposes
            allPublicEvents = createMockPublicEvents()
        }
        
        isLoading = false
    }
    
    // MARK: - Mock Data for Demo
    private func createMockTrendingEvents() -> [TrendingEvent] {
        return [
            TrendingEvent(from: TrendingEventData(
                event_id: "1",
                title: "Midnight Vibes",
                thumbnail_url: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500",
                event_date: Calendar.current.date(byAdding: .day, value: 1, to: Date())?.ISO8601Format() ?? "",
                start_time: "23:00",
                location: "Los Angeles, CA",
                venue_name: "Skybar Rooftop",
                ticket_price: 45.0,
                available_tickets: 23,
                dj_stage_name: "DJ Nebula",
                recent_sales_count: 15
            )),
            TrendingEvent(from: TrendingEventData(
                event_id: "2",
                title: "House Music Revival",
                thumbnail_url: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500",
                event_date: Calendar.current.date(byAdding: .day, value: 2, to: Date())?.ISO8601Format() ?? "",
                start_time: "22:30",
                location: "Miami, FL",
                venue_name: "Electric Paradise",
                ticket_price: 65.0,
                available_tickets: 8,
                dj_stage_name: "DJ Phoenix",
                recent_sales_count: 22
            )),
            TrendingEvent(from: TrendingEventData(
                event_id: "3",
                title: "Latin Nights",
                thumbnail_url: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=500",
                event_date: Calendar.current.date(byAdding: .day, value: 3, to: Date())?.ISO8601Format() ?? "",
                start_time: "21:00",
                location: "Austin, TX",
                venue_name: "Salsa Club Downtown",
                ticket_price: 35.0,
                available_tickets: 45,
                dj_stage_name: "DJ Fuego",
                recent_sales_count: 8
            )),
            TrendingEvent(from: TrendingEventData(
                event_id: "4",
                title: "Underground Bass",
                thumbnail_url: "https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?w=500",
                event_date: Calendar.current.date(byAdding: .hour, value: 6, to: Date())?.ISO8601Format() ?? "",
                start_time: "23:30",
                location: "Brooklyn, NY",
                venue_name: "The Warehouse",
                ticket_price: 55.0,
                available_tickets: 12,
                dj_stage_name: "DJ Storm",
                recent_sales_count: 18
            )),
            TrendingEvent(from: TrendingEventData(
                event_id: "5",
                title: "Retro Dance Party",
                thumbnail_url: "https://images.unsplash.com/photo-1556908114-f6e7ad7d3136?w=500",
                event_date: Calendar.current.date(byAdding: .day, value: 4, to: Date())?.ISO8601Format() ?? "",
                start_time: "20:00",
                location: "San Francisco, CA",
                venue_name: "Disco Palace",
                ticket_price: 40.0,
                available_tickets: 67,
                dj_stage_name: "DJ Retro",
                recent_sales_count: 12
            ))
        ]
    }
    
    private func createMockPublicEvents() -> [PublicEvent] {
        return [
            PublicEvent(from: PublicEventData(
                id: "1",
                title: "Midnight Vibes",
                description: "An electrifying night of deep house and techno music",
                thumbnail_url: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500",
                event_date: Calendar.current.date(byAdding: .day, value: 1, to: Date())?.ISO8601Format() ?? "",
                start_time: "23:00",
                end_time: "03:00",
                location: "Los Angeles, CA",
                venue_name: "Skybar Rooftop",
                ticket_price: 45.0,
                available_tickets: 23,
                total_capacity: 150,
                status: "active",
                created_at: Date().ISO8601Format(),
                djs: DJBasicData(stage_name: "DJ Nebula")
            )),
            PublicEvent(from: PublicEventData(
                id: "2",
                title: "House Music Revival",
                description: "Classic house beats with modern twists",
                thumbnail_url: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500",
                event_date: Calendar.current.date(byAdding: .day, value: 2, to: Date())?.ISO8601Format() ?? "",
                start_time: "22:30",
                end_time: "04:00",
                location: "Miami, FL",
                venue_name: "Electric Paradise",
                ticket_price: 65.0,
                available_tickets: 8,
                total_capacity: 200,
                status: "active",
                created_at: Date().ISO8601Format(),
                djs: DJBasicData(stage_name: "DJ Phoenix")
            ))
        ]
    }
}

// MARK: - Event Detail View Model
@MainActor
class EventDetailViewModel: ObservableObject {
    @Published var eventDetail: EventDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isBookingTicket = false
    @Published var showingPaymentSheet = false
    @Published var ticketQuantity = 1
    
    private let supabaseManager = SupabaseManager.shared
    private let stripeManager = StripeManager.shared
    
    var ticketCalculation: TicketPurchaseCalculation? {
        guard let event = eventDetail else { return nil }
        return TicketPurchaseCalculation(
            ticketPrice: event.ticketPrice,
            quantity: ticketQuantity,
            platformFeePercentage: event.platformFeePercentage
        )
    }
    
    // MARK: - Load Event Details
    func loadEventDetails(eventId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let detail = try await supabaseManager.getEventDetails(eventId: eventId)
            eventDetail = detail
        } catch {
            errorMessage = "Failed to load event details: \(error.localizedDescription)"
            print("Error loading event details: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Book Ticket
    func bookTicket() async {
        guard let event = eventDetail,
              let calculation = ticketCalculation else {
            errorMessage = "Unable to process ticket booking"
            return
        }
        
        isBookingTicket = true
        
        do {
            // Create payment intent with Stripe
            let (clientSecret, paymentIntentId) = try await stripeManager.createPaymentIntent(
                for: event,
                quantity: ticketQuantity,
                connectedAccountId: nil // You'll need to implement host account linking
            )
            
            // Configure payment sheet
            stripeManager.configurePaymentSheet(paymentIntentClientSecret: clientSecret)
            
            // Create pending ticket record
            let ticketPurchase = TicketPurchase(
                eventId: event.id,
                quantity: ticketQuantity,
                totalAmount: calculation.total,
                platformFee: calculation.platformFee,
                hostPayout: calculation.hostPayout,
                stripePaymentIntentId: paymentIntentId,
                stripeCheckoutSessionId: nil
            )
            
            let _ = try await supabaseManager.createTicketPurchase(ticketPurchase)
            
            // Show payment sheet
            showingPaymentSheet = true
            
        } catch {
            errorMessage = "Failed to initialize payment: \(error.localizedDescription)"
        }
        
        isBookingTicket = false
    }
    
    // MARK: - Handle Payment Result
    func handlePaymentResult(_ result: PaymentSheetResult, ticketId: String) async {
        switch result {
        case .completed:
            // Update ticket status to paid
            do {
                try await supabaseManager.updateTicketPaymentStatus(
                    ticketId: ticketId,
                    status: "paid",
                    paymentIntentId: ""
                )
                // Ticket booking successful - could show success screen
                print("Ticket booked successfully!")
            } catch {
                errorMessage = "Payment completed but failed to update ticket status"
            }
            
        case .canceled:
            // User canceled payment
            break
            
        case .failed(let error):
            errorMessage = "Payment failed: \(error.localizedDescription)"
        }
    }
} 