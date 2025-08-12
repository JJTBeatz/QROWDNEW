import SwiftUI

struct BookingRequestView: View {
    let djProfile: DJProfileDetail
    @StateObject private var viewModel = BookingRequestViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                QROWDTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: QROWDTheme.sectionSpacing) {
                        
                        // DJ Summary Card
                        VStack(spacing: 12) {
                            HStack {
                                AsyncImage(url: URL(string: djProfile.promoMediaURLs.first ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(QROWDTheme.cardGradient)
                                        .overlay(
                                            Image(systemName: "music.note")
                                                .foregroundColor(QROWDTheme.secondaryText)
                                        )
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(djProfile.stageName)
                                        .font(QROWDTheme.headlineFont)
                                        .foregroundColor(QROWDTheme.primaryText)
                                    
                                    Text(djProfile.city)
                                        .font(QROWDTheme.captionFont)
                                        .foregroundColor(QROWDTheme.secondaryText)
                                    
                                    Text(djProfile.priceRange)
                                        .font(QROWDTheme.captionFont.weight(.semibold))
                                        .foregroundColor(QROWDTheme.accentColor)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(QROWDTheme.cardPadding)
                        .background(
                            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                                .fill(QROWDTheme.cardGradient)
                                .overlay(
                                    RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                                        .stroke(QROWDTheme.borderColor, lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        // Event Details Form
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Event Details")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            // Event Location
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Event Location")
                                    .font(QROWDTheme.bodyFont.weight(.semibold))
                                    .foregroundColor(QROWDTheme.primaryText)
                                
                                QROWDTextField(
                                    text: $viewModel.eventLocation,
                                    placeholder: "Enter venue or address",
                                    icon: "location"
                                )
                            }
                            
                            // Guest Count
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Expected Guests")
                                    .font(QROWDTheme.bodyFont.weight(.semibold))
                                    .foregroundColor(QROWDTheme.primaryText)
                                
                                HStack(spacing: 12) {
                                    ForEach(guestCountOptions, id: \.value) { option in
                                        GuestCountButton(
                                            title: option.title,
                                            count: option.value,
                                            isSelected: viewModel.guestCount == option.value
                                        ) {
                                            viewModel.guestCount = option.value
                                            viewModel.calculateTotal()
                                        }
                                    }
                                }
                            }
                            
                            // Date & Time
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Event Date & Time")
                                    .font(QROWDTheme.bodyFont.weight(.semibold))
                                    .foregroundColor(QROWDTheme.primaryText)
                                
                                DatePicker(
                                    "Event Date",
                                    selection: $viewModel.eventDate,
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(CompactDatePickerStyle())
                                .colorScheme(.dark)
                                .accentColor(QROWDTheme.accentColor)
                                .onChange(of: viewModel.eventDate) {
                                    viewModel.calculateTotal()
                                }
                            }
                            
                            // Duration
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Duration")
                                    .font(QROWDTheme.bodyFont.weight(.semibold))
                                    .foregroundColor(QROWDTheme.primaryText)
                                
                                HStack(spacing: 12) {
                                    ForEach(durationOptions, id: \.self) { duration in
                                        DurationButton(
                                            hours: duration,
                                            isSelected: viewModel.durationHours == duration
                                        ) {
                                            viewModel.durationHours = duration
                                            viewModel.calculateTotal()
                                        }
                                    }
                                }
                            }
                            
                            // Special Requests
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Special Requests (Optional)")
                                    .font(QROWDTheme.bodyFont.weight(.semibold))
                                    .foregroundColor(QROWDTheme.primaryText)
                                
                                ZStack(alignment: .topLeading) {
                                    if viewModel.specialRequests.isEmpty {
                                        Text("Any specific music requests, equipment needs, or other details...")
                                            .font(QROWDTheme.bodyFont)
                                            .foregroundColor(QROWDTheme.placeholderText)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                    }
                                    
                                    TextEditor(text: $viewModel.specialRequests)
                                        .font(QROWDTheme.bodyFont)
                                        .foregroundColor(QROWDTheme.primaryText)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                }
                                .frame(minHeight: 80)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                                        .fill(QROWDTheme.cardGradient)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                                                .stroke(QROWDTheme.borderColor, lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        // Price Summary
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Price Summary")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Duration")
                                        .font(QROWDTheme.bodyFont)
                                        .foregroundColor(QROWDTheme.secondaryText)
                                    
                                    Spacer()
                                    
                                    Text("\(viewModel.durationHours) hours")
                                        .font(QROWDTheme.bodyFont)
                                        .foregroundColor(QROWDTheme.primaryText)
                                }
                                
                                HStack {
                                    Text("Rate")
                                        .font(QROWDTheme.bodyFont)
                                        .foregroundColor(QROWDTheme.secondaryText)
                                    
                                    Spacer()
                                    
                                    Text("$\(Int(viewModel.hourlyRate))/hour")
                                        .font(QROWDTheme.bodyFont)
                                        .foregroundColor(QROWDTheme.primaryText)
                                }
                                
                                Divider()
                                    .background(QROWDTheme.borderColor)
                                
                                HStack {
                                    Text("Total")
                                        .font(QROWDTheme.headlineFont)
                                        .foregroundColor(QROWDTheme.primaryText)
                                    
                                    Spacer()
                                    
                                    Text("$\(Int(viewModel.totalPrice))")
                                        .font(QROWDTheme.headlineFont)
                                        .foregroundColor(QROWDTheme.accentColor)
                                }
                            }
                        }
                        .padding(QROWDTheme.cardPadding)
                        .background(
                            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                                .fill(QROWDTheme.cardGradient)
                                .overlay(
                                    RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                                        .stroke(QROWDTheme.borderColor, lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        // Submit Button
                        QROWDButton(
                            title: "Send Booking Request",
                            isLoading: viewModel.isSubmitting,
                            isEnabled: viewModel.isFormValid
                        ) {
                            Task {
                                await viewModel.submitBookingRequest(djId: djProfile.id)
                            }
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Book DJ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(QROWDTheme.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel Policy") {
                        // Show cancellation policy
                    }
                    .foregroundColor(QROWDTheme.accentColor)
                    .font(.caption)
                }
            }
        }
        .alert("Booking Sent!", isPresented: $viewModel.showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your booking request has been sent to \(djProfile.stageName). They will respond within 24 hours.")
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            viewModel.setupForDJ(djProfile)
        }
    }
    
    private let guestCountOptions = [
        (title: "25", value: 25),
        (title: "50", value: 50),
        (title: "100", value: 100),
        (title: "200+", value: 200)
    ]
    
    private let durationOptions = [2, 3, 4, 5, 6, 8]
}

// MARK: - Guest Count Button
struct GuestCountButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(QROWDTheme.captionFont.weight(.semibold))
                .foregroundColor(isSelected ? .white : QROWDTheme.primaryText)
                .frame(minWidth: 50)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? QROWDTheme.buttonGradient : QROWDTheme.cardGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.clear : QROWDTheme.borderColor, lineWidth: 1)
                        )
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Duration Button
struct DurationButton: View {
    let hours: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(hours)h")
                .font(QROWDTheme.captionFont.weight(.semibold))
                .foregroundColor(isSelected ? .white : QROWDTheme.primaryText)
                .frame(minWidth: 40)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? QROWDTheme.buttonGradient : QROWDTheme.cardGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.clear : QROWDTheme.borderColor, lineWidth: 1)
                        )
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - ViewModel
@MainActor
class BookingRequestViewModel: ObservableObject {
    @Published var eventLocation = ""
    @Published var guestCount = 50
    @Published var eventDate = Date().addingTimeInterval(24 * 60 * 60) // Tomorrow
    @Published var durationHours = 4
    @Published var specialRequests = ""
    
    @Published var hourlyRate: Double = 100
    @Published var totalPrice: Double = 400
    
    @Published var isSubmitting = false
    @Published var showingSuccess = false
    @Published var showingError = false
    @Published var errorMessage = ""
    
    private let supabase = SupabaseManager.shared
    
    var isFormValid: Bool {
        !eventLocation.isEmpty
    }
    
    func setupForDJ(_ djProfile: DJProfileDetail) {
        // Extract price from range (simplified)
        let priceComponents = djProfile.priceRange.components(separatedBy: " - ")
        if let firstPrice = priceComponents.first?.replacingOccurrences(of: "$", with: ""),
           let price = Double(firstPrice) {
            hourlyRate = price
        }
        calculateTotal()
    }
    
    func calculateTotal() {
        totalPrice = hourlyRate * Double(durationHours)
    }
    
    func submitBookingRequest(djId: String) async {
        isSubmitting = true
        
        do {
            let bookingDetails = InstantBookingDetails(
                location: eventLocation,
                startTime: eventDate,
                duration: TimeInterval(durationHours * 3600),
                estimatedCost: totalPrice
            )
            
            let bookingRequest = BookingRequest(
                id: UUID().uuidString,
                djId: djId,
                hostId: "current_host_id", // TODO: Get from authenticated user
                details: bookingDetails,
                estimatedCost: totalPrice,
                surgeMultiplier: 1.0,
                message: specialRequests.isEmpty ? nil : specialRequests
            )
            
            _ = try await supabase.createBooking(bookingRequest)
            showingSuccess = true
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isSubmitting = false
    }
}

#Preview {
    let sampleData = DJProfileDetailData(
        id: "1",
        stage_name: "DJ Phoenix",
        city: "Miami",
        genres: ["House", "Latin"],
        cultures: ["Latino"],
        equipment: ["DJ Controller"],
        rating: 4.8,
        total_bookings: 45,
        budget_min: 150,
        budget_max: 300,
        promo_media_urls: [],
        instagram_handle: "djphoenix",
        soundcloud_url: "",
        availability: [:],
        is_pro: true
    )
    
    return BookingRequestView(djProfile: DJProfileDetail(from: sampleData))
} 