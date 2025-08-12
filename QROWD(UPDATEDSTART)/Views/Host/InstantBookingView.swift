import SwiftUI

struct InstantBookingView: View {
    @StateObject private var viewModel = InstantBookingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                QROWDTheme.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        InstantBookingHeader()
                        
                        // Quick Setup
                        QuickSetupCard(viewModel: viewModel)
                        
                        // Available DJs
                        if viewModel.isLoading {
                            InstantBookingLoadingView()
                        } else {
                            AvailableDJsSection(
                                djs: viewModel.availableDJs,
                                onDJSelected: { dj in
                                    viewModel.selectedDJ = dj
                                    viewModel.showingBookingConfirmation = true
                                }
                            )
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Instant Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(QROWDTheme.primaryText)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingBookingConfirmation) {
            if let dj = viewModel.selectedDJ {
                InstantBookingConfirmationView(
                    dj: dj,
                    details: viewModel.bookingDetails
                ) { result in
                    handleBookingResult(result)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingBookingStatus) {
            if let bookingResult = viewModel.bookingResult {
                BookingRequestStatusView(bookingResult: bookingResult)
            }
        }
        .onAppear {
            viewModel.loadAvailableDJs()
        }
    }
    
    private func handleBookingResult(_ result: InstantBookingResult) {
        viewModel.bookingResult = result
        viewModel.showingBookingStatus = true
    }
}

// MARK: - Supporting Views

struct InstantBookingHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("⚡ Instant Booking")
                        .font(QROWDTheme.headlineFont)
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text("Get a DJ in 2-4 hours")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
                
                Spacer()
                
                SurgeIndicator(multiplier: 1.5)
            }
            
            // Urgency indicator
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                
                Text("High demand in your area")
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(.orange)
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, QROWDTheme.cardPadding)
    }
}

struct QuickSetupCard: View {
    @ObservedObject var viewModel: InstantBookingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Event Details")
                .font(QROWDTheme.bodyFont.weight(.semibold))
                .foregroundColor(QROWDTheme.primaryText)
            
            VStack(spacing: 12) {
                // Location
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(QROWDTheme.accentColor)
                        .frame(width: 24)
                    
                    TextField("Event location", text: $viewModel.bookingDetails.location)
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.primaryText)
                }
                
                Divider()
                
                // Time
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(QROWDTheme.accentColor)
                        .frame(width: 24)
                    
                    DatePicker(
                        "Start time",
                        selection: $viewModel.bookingDetails.startTime,
                        in: Date()...Calendar.current.date(byAdding: .hour, value: 4, to: Date())!,
                        displayedComponents: [.hourAndMinute]
                    )
                    .colorScheme(.dark)
                }
                
                Divider()
                
                // Duration
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(QROWDTheme.accentColor)
                        .frame(width: 24)
                    
                    Text("Duration:")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Spacer()
                    
                    Picker("Duration", selection: $viewModel.bookingDetails.duration) {
                        Text("2 hours").tag(TimeInterval(7200))
                        Text("3 hours").tag(TimeInterval(10800))
                        Text("4 hours").tag(TimeInterval(14400))
                        Text("5 hours").tag(TimeInterval(18000))
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            // Search button
            QROWDButton(
                title: "Find Available DJs",
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.canSearch
            ) {
                viewModel.loadAvailableDJs()
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
    }
}

struct AvailableDJsSection: View {
    let djs: [InstantDJ]
    let onDJSelected: (InstantDJ) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Available Now")
                    .font(QROWDTheme.bodyFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Spacer()
                
                Text("\(djs.count) DJs")
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            .padding(.horizontal, QROWDTheme.cardPadding)
            
            LazyVStack(spacing: 12) {
                ForEach(djs, id: \.id) { dj in
                    InstantDJCard(dj: dj) {
                        onDJSelected(dj)
                    }
                }
            }
            .padding(.horizontal, QROWDTheme.cardPadding)
        }
    }
}

struct InstantDJCard: View {
    let dj: InstantDJ
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // DJ Avatar
                AsyncImage(url: URL(string: "https://example.com/avatar.jpg")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(QROWDTheme.accentColor.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(QROWDTheme.accentColor)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(dj.stageName)
                            .font(QROWDTheme.bodyFont.weight(.semibold))
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        if dj.isOnline {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text("\(dj.rating, specifier: "%.1f")")
                            .font(QROWDTheme.captionFont)
                        
                        Text("•")
                            .foregroundColor(QROWDTheme.secondaryText)
                        
                        Text(dj.specialties.prefix(2).joined(separator: ", "))
                            .font(QROWDTheme.captionFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                    }
                    
                    HStack {
                        Text("Responds in ~\(Int(dj.responseTime/60)) min")
                            .font(QROWDTheme.captionFont)
                            .foregroundColor(.green)
                        
                        Text("•")
                            .foregroundColor(QROWDTheme.secondaryText)
                        
                        Text("\(dj.distance, specifier: "%.1f") mi away")
                            .font(QROWDTheme.captionFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(Int(dj.pricePerHour))/hr")
                        .font(QROWDTheme.bodyFont.weight(.semibold))
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text("+ surge")
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(.orange)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(QROWDTheme.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(QROWDTheme.borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SurgeIndicator: View {
    let multiplier: Double
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: surgeIcon)
                .foregroundColor(surgeColor)
                .font(.caption)
            
            Text("\(multiplier, specifier: "%.1f")x")
                .font(QROWDTheme.captionFont.weight(.semibold))
                .foregroundColor(surgeColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(surgeColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(surgeColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var surgeColor: Color {
        if multiplier >= 2.0 { return .red }
        else if multiplier >= 1.5 { return .orange }
        else { return .green }
    }
    
    private var surgeIcon: String {
        if multiplier >= 2.0 { return "exclamationmark.triangle.fill" }
        else if multiplier >= 1.5 { return "exclamationmark.circle.fill" }
        else { return "checkmark.circle.fill" }
    }
}

struct InstantBookingLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Finding available DJs...")
                .font(QROWDTheme.bodyFont)
                .foregroundColor(QROWDTheme.secondaryText)
        }
        .frame(height: 200)
    }
}

// MARK: - Confirmation View

struct InstantBookingConfirmationView: View {
    let dj: InstantDJ
    let details: InstantBookingDetails
    let onConfirm: (InstantBookingResult) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // DJ Summary
                VStack(spacing: 16) {
                    AsyncImage(url: URL(string: "https://example.com/avatar.jpg")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(QROWDTheme.accentColor.opacity(0.3))
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(QROWDTheme.accentColor)
                                    .font(.title)
                            )
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    
                    Text(dj.stageName)
                        .font(QROWDTheme.headlineFont)
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text("Response time: ~\(Int(dj.responseTime/60)) minutes")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(.orange)
                }
                
                // Booking Details
                VStack(spacing: 16) {
                    ConfirmationRow(
                        title: "Location",
                        value: details.location,
                        icon: "location.fill"
                    )
                    
                    ConfirmationRow(
                        title: "Start Time",
                        value: formatTime(details.startTime),
                        icon: "clock.fill"
                    )
                    
                    ConfirmationRow(
                        title: "Duration",
                        value: formatDuration(details.duration),
                        icon: "timer"
                    )
                    
                    ConfirmationRow(
                        title: "Total Cost",
                        value: "$\(Int(details.estimatedCost))",
                        icon: "dollarsign.circle.fill"
                    )
                }
                
                Spacer()
                
                // Confirm Button
                QROWDButton(
                    title: "Send Booking Request",
                    isLoading: isProcessing,
                    isEnabled: !isProcessing
                ) {
                    confirmBooking()
                }
                .padding(.horizontal, 20)
            }
            .padding(20)
            .navigationTitle("Confirm Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func confirmBooking() {
        isProcessing = true
        
        Task {
            do {
                // Create booking request instead of auto-confirming
                let result = try await InstantBookingManager.shared.createBookingRequest(
                    djId: dj.id,
                    hostId: "current_host_id", // In real app, get from auth
                    details: details,
                    message: nil
                )
                
                await MainActor.run {
                    onConfirm(result)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    // Handle error - show alert
                    print("Booking request failed: \(error)")
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        return "\(hours) hour\(hours == 1 ? "" : "s")"
    }
}

struct ConfirmationRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(QROWDTheme.accentColor)
                .frame(width: 24)
            
            Text(title)
                .font(QROWDTheme.bodyFont)
                .foregroundColor(QROWDTheme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(QROWDTheme.bodyFont.weight(.medium))
                .foregroundColor(QROWDTheme.primaryText)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(QROWDTheme.cardGradient)
        )
    }
}

// MARK: - ViewModel

@MainActor
class InstantBookingViewModel: ObservableObject {
    @Published var bookingDetails = InstantBookingDetails(
        location: "",
        startTime: Date().addingTimeInterval(7200), // 2 hours from now
        duration: TimeInterval(14400), // 4 hours
        estimatedCost: 0
    )
    
    @Published var availableDJs: [InstantDJ] = []
    @Published var selectedDJ: InstantDJ?
    @Published var isLoading = false
    @Published var showingBookingConfirmation = false
    @Published var showingBookingStatus = false
    @Published var bookingResult: InstantBookingResult?
    
    var canSearch: Bool {
        !bookingDetails.location.isEmpty
    }
    
    func loadAvailableDJs() {
        isLoading = true
        
        Task {
            let djs = await InstantBookingManager.shared.findInstantAvailableDJs(
                location: bookingDetails.location,
                dateTime: bookingDetails.startTime,
                duration: bookingDetails.duration,
                budget: 100...500
            )
            
            await MainActor.run {
                self.availableDJs = djs
                self.isLoading = false
            }
        }
    }
}

#Preview {
    InstantBookingView()
} 