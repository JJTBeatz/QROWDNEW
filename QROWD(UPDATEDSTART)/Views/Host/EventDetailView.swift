import SwiftUI
import StripePaymentSheet

struct EventDetailView: View {
    let event: TrendingEvent
    @StateObject private var viewModel = EventDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingPaymentSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                QROWDTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Image
                        AsyncImage(url: URL(string: event.thumbnailURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(QROWDTheme.cardGradient)
                                .overlay(
                                    Image(systemName: "music.mic")
                                        .font(.system(size: 50))
                                        .foregroundColor(QROWDTheme.secondaryText)
                                )
                        }
                        .frame(height: 250)
                        .clipped()
                        
                        // Event Details
                        VStack(alignment: .leading, spacing: 20) {
                            // Title and Basic Info
                            VStack(alignment: .leading, spacing: 12) {
                                Text(event.title)
                                    .font(QROWDTheme.titleFont)
                                    .foregroundColor(QROWDTheme.primaryText)
                                    .lineLimit(2)
                                
                                // Date and Time
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .font(.title3)
                                        .foregroundColor(QROWDTheme.accentColor)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(formatEventDate(event.eventDate))
                                            .font(QROWDTheme.headlineFont)
                                            .foregroundColor(QROWDTheme.primaryText)
                                        
                                        Text(formatEventTime(event.startTime))
                                            .font(QROWDTheme.bodyFont)
                                            .foregroundColor(QROWDTheme.secondaryText)
                                    }
                                }
                                
                                // Location
                                HStack(spacing: 8) {
                                    Image(systemName: "location")
                                        .font(.title3)
                                        .foregroundColor(QROWDTheme.accentColor)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        if !event.venueName.isEmpty {
                                            Text(event.venueName)
                                                .font(QROWDTheme.headlineFont)
                                                .foregroundColor(QROWDTheme.primaryText)
                                        }
                                        
                                        Text(event.location)
                                            .font(QROWDTheme.bodyFont)
                                            .foregroundColor(QROWDTheme.secondaryText)
                                    }
                                }
                                
                                // DJ Info
                                if let djName = event.djStageName {
                                    HStack(spacing: 8) {
                                        Image(systemName: "headphones")
                                            .font(.title3)
                                            .foregroundColor(QROWDTheme.accentColor)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Featuring")
                                                .font(QROWDTheme.captionFont)
                                                .foregroundColor(QROWDTheme.secondaryText)
                                            
                                            Text(djName)
                                                .font(QROWDTheme.headlineFont)
                                                .foregroundColor(QROWDTheme.accentColor)
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                                .background(QROWDTheme.secondaryText.opacity(0.3))
                            
                            // Ticket Info
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Ticket Information")
                                    .font(QROWDTheme.headlineFont)
                                    .foregroundColor(QROWDTheme.primaryText)
                                
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Price per ticket")
                                            .font(QROWDTheme.bodyFont)
                                            .foregroundColor(QROWDTheme.secondaryText)
                                        
                                        Spacer()
                                        
                                        Text("$\(String(format: "%.0f", event.ticketPrice))")
                                            .font(QROWDTheme.headlineFont)
                                            .foregroundColor(QROWDTheme.accentColor)
                                    }
                                    
                                    HStack {
                                        Text("Available tickets")
                                            .font(QROWDTheme.bodyFont)
                                            .foregroundColor(QROWDTheme.secondaryText)
                                        
                                        Spacer()
                                        
                                        Text("\(event.availableTickets)")
                                            .font(QROWDTheme.headlineFont)
                                            .foregroundColor(event.availableTickets < 10 ? .orange : QROWDTheme.primaryText)
                                    }
                                    
                                    if event.availableTickets < 20 {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.orange)
                                            
                                            Text("Limited tickets remaining!")
                                                .font(QROWDTheme.captionFont)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                                .padding()
                                .background(QROWDTheme.cardBackground)
                                .cornerRadius(12)
                            }
                            
                            // Quantity Selector
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Quantity")
                                    .font(QROWDTheme.headlineFont)
                                    .foregroundColor(QROWDTheme.primaryText)
                                
                                HStack {
                                    Button {
                                        if viewModel.ticketQuantity > 1 {
                                            viewModel.ticketQuantity -= 1
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(viewModel.ticketQuantity > 1 ? QROWDTheme.accentColor : QROWDTheme.secondaryText)
                                    }
                                    .disabled(viewModel.ticketQuantity <= 1)
                                    
                                    Text("\(viewModel.ticketQuantity)")
                                        .font(QROWDTheme.titleFont)
                                        .foregroundColor(QROWDTheme.primaryText)
                                        .frame(minWidth: 40)
                                    
                                    Button {
                                        if viewModel.ticketQuantity < min(8, event.availableTickets) {
                                            viewModel.ticketQuantity += 1
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(viewModel.ticketQuantity < min(8, event.availableTickets) ? QROWDTheme.accentColor : QROWDTheme.secondaryText)
                                    }
                                    .disabled(viewModel.ticketQuantity >= min(8, event.availableTickets))
                                    
                                    Spacer()
                                }
                            }
                            
                            // Price Breakdown
                            if let calculation = viewModel.ticketCalculation {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Price Breakdown")
                                        .font(QROWDTheme.headlineFont)
                                        .foregroundColor(QROWDTheme.primaryText)
                                    
                                    VStack(spacing: 8) {
                                        HStack {
                                            Text("Tickets (\(viewModel.ticketQuantity))")
                                                .font(QROWDTheme.bodyFont)
                                                .foregroundColor(QROWDTheme.secondaryText)
                                            
                                            Spacer()
                                            
                                            Text(calculation.formattedSubtotal)
                                                .font(QROWDTheme.bodyFont)
                                                .foregroundColor(QROWDTheme.primaryText)
                                        }
                                        
                                        HStack {
                                            Text("Service fee")
                                                .font(QROWDTheme.bodyFont)
                                                .foregroundColor(QROWDTheme.secondaryText)
                                            
                                            Spacer()
                                            
                                            Text(calculation.formattedPlatformFee)
                                                .font(QROWDTheme.bodyFont)
                                                .foregroundColor(QROWDTheme.primaryText)
                                        }
                                        
                                        Divider()
                                            .background(QROWDTheme.secondaryText.opacity(0.3))
                                        
                                        HStack {
                                            Text("Total")
                                                .font(QROWDTheme.headlineFont)
                                                .foregroundColor(QROWDTheme.primaryText)
                                            
                                            Spacer()
                                            
                                            Text(calculation.formattedTotal)
                                                .font(QROWDTheme.titleFont)
                                                .foregroundColor(QROWDTheme.accentColor)
                                        }
                                    }
                                    .padding()
                                    .background(QROWDTheme.cardBackground)
                                    .cornerRadius(12)
                                }
                            }
                            
                            // Error Message
                            if let errorMessage = viewModel.errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    
                                    Text(errorMessage)
                                        .font(QROWDTheme.captionFont)
                                        .foregroundColor(.red)
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Spacer(minLength: 100) // Space for floating button
                        }
                        .padding(QROWDTheme.cardPadding)
                    }
                }
                
                // Floating Book Ticket Button
                VStack {
                    Spacer()
                    
                    QROWDButton(
                        title: viewModel.isBookingTicket ? "Processing..." : "Book Tickets",
                        isLoading: viewModel.isBookingTicket,
                        isEnabled: !viewModel.isBookingTicket && event.availableTickets > 0
                    ) {
                        Task {
                            await viewModel.bookTicket()
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(QROWDTheme.accentColor)
                }
            }
        }
        .paymentSheet(
            isPresented: $showingPaymentSheet,
            paymentSheet: StripeManager.shared.paymentSheet ?? PaymentSheet(paymentIntentClientSecret: "", configuration: PaymentSheet.Configuration())
        ) { result in
            Task {
                await viewModel.handlePaymentResult(result, ticketId: "temp_id")
            }
        }
        .onChange(of: viewModel.showingPaymentSheet) { shouldShow in
            showingPaymentSheet = shouldShow
        }
        .task {
            await viewModel.loadEventDetails(eventId: event.id)
            
            // Mock the event detail loading since we might not have full data
            viewModel.eventDetail = EventDetail(from: EventDetailData(
                id: event.id,
                title: event.title,
                description: "An amazing night of incredible music and unforgettable experiences. Join us for an evening you won't forget!",
                thumbnail_url: event.thumbnailURL,
                event_date: event.eventDate.ISO8601Format(),
                start_time: event.startTime,
                end_time: nil,
                location: event.location,
                venue_name: event.venueName,
                ticket_price: event.ticketPrice,
                available_tickets: event.availableTickets,
                total_capacity: 200,
                status: "active",
                platform_fee_percentage: 10.0,
                created_at: Date().ISO8601Format(),
                djs: event.djStageName.map { EventDJData(stage_name: $0, genres: ["House", "Electronic"], rating: 4.8, instagram_handle: "@\($0.lowercased().replacingOccurrences(of: " ", with: ""))") }
            ))
        }
    }
    
    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func formatEventTime(_ time: String) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        if let timeDate = timeFormatter.date(from: time) {
            timeFormatter.dateFormat = "h:mm a"
            return timeFormatter.string(from: timeDate)
        }
        return time
    }
}

#Preview {
    EventDetailView(event: TrendingEvent(from: TrendingEventData(
        event_id: "1",
        title: "Midnight Vibes",
        thumbnail_url: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500",
        event_date: Date().ISO8601Format(),
        start_time: "23:00",
        location: "Los Angeles, CA",
        venue_name: "Skybar Rooftop",
        ticket_price: 45.0,
        available_tickets: 23,
        dj_stage_name: "DJ Nebula",
        recent_sales_count: 15
    )))
} 