import SwiftUI

struct BookingRequestStatusView: View {
    let bookingResult: InstantBookingResult
    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            ZStack {
                QROWDTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Status Header
                    StatusHeader(status: bookingResult.status)
                    
                    // DJ Info
                    DJInfoSection(djInfo: bookingResult.djInfo)
                    
                    // Booking Details
                    BookingDetailsSection(bookingResult: bookingResult)
                    
                    // Response Timeline
                    ResponseTimelineSection(
                        status: bookingResult.status,
                        timeRemaining: timeRemaining,
                        responseDeadline: bookingResult.responseDeadline
                    )
                    
                    // Actions
                    ActionButtonsSection(
                        status: bookingResult.status,
                        onCancel: {
                            // Cancel booking request
                            dismiss()
                        },
                        onFindAlternatives: {
                            // Find alternative DJs
                            dismiss()
                        }
                    )
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Booking Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(QROWDTheme.primaryText)
                }
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        updateTimeRemaining()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimeRemaining()
        }
    }
    
    private func updateTimeRemaining() {
        timeRemaining = max(0, bookingResult.responseDeadline.timeIntervalSince(Date()))
        
        if timeRemaining <= 0 {
            timer?.invalidate()
        }
    }
}

// MARK: - Supporting Views

struct StatusHeader: View {
    let status: BookingRequestStatus
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: statusIcon)
                .font(.system(size: 60))
                .foregroundColor(statusColor)
            
            Text(status.description)
                .font(QROWDTheme.headlineFont)
                .foregroundColor(QROWDTheme.primaryText)
                .multilineTextAlignment(.center)
            
            Text(statusSubtitle)
                .font(QROWDTheme.bodyFont)
                .foregroundColor(QROWDTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .pending: return "clock.fill"
        case .accepted: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        case .expired: return "timer.square"
        case .cancelled: return "multiply.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending: return .orange
        case .accepted: return .green
        case .declined: return .red
        case .expired: return .gray
        case .cancelled: return .gray
        }
    }
    
    private var statusSubtitle: String {
        switch status {
        case .pending: return "We've sent your request to the DJ. They'll respond soon!"
        case .accepted: return "Great! Your DJ has accepted the booking."
        case .declined: return "The DJ isn't available. We'll help you find alternatives."
        case .expired: return "The request timed out. Let's find another DJ."
        case .cancelled: return "Your booking request has been cancelled."
        }
    }
}

struct DJInfoSection: View {
    let djInfo: DJBasicInfo
    
    var body: some View {
        VStack(spacing: 12) {
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
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            
            Text(djInfo.stageName)
                .font(QROWDTheme.bodyFont.weight(.semibold))
                .foregroundColor(QROWDTheme.primaryText)
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
}

struct BookingDetailsSection: View {
    let bookingResult: InstantBookingResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Booking Details")
                .font(QROWDTheme.bodyFont.weight(.semibold))
                .foregroundColor(QROWDTheme.primaryText)
            
            VStack(spacing: 12) {
                DetailRow(
                    title: "Total Cost",
                    value: "$\(Int(bookingResult.totalCost))",
                    icon: "dollarsign.circle.fill"
                )
                
                DetailRow(
                    title: "Booking ID",
                    value: String(bookingResult.bookingId.prefix(8)),
                    icon: "number.circle.fill"
                )
                
                if let estimatedArrival = bookingResult.estimatedArrival {
                    DetailRow(
                        title: "Estimated Arrival",
                        value: formatTime(estimatedArrival),
                        icon: "clock.fill"
                    )
                }
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
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(QROWDTheme.accentColor)
                .frame(width: 20)
            
            Text(title)
                .font(QROWDTheme.bodyFont)
                .foregroundColor(QROWDTheme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(QROWDTheme.bodyFont.weight(.medium))
                .foregroundColor(QROWDTheme.primaryText)
        }
    }
}

struct ResponseTimelineSection: View {
    let status: BookingRequestStatus
    let timeRemaining: TimeInterval
    let responseDeadline: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Response Timeline")
                .font(QROWDTheme.bodyFont.weight(.semibold))
                .foregroundColor(QROWDTheme.primaryText)
            
            if status == .pending {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.orange)
                        
                        Text("DJ has \(formatTimeRemaining(timeRemaining)) to respond")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        Spacer()
                    }
                    
                    ProgressView(value: getProgressValue())
                        .tint(.orange)
                        .scaleEffect(y: 2)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Response received")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Spacer()
                }
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
    
    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        let remainingSeconds = Int(seconds) % 60
        
        if minutes > 0 {
            return "\(minutes) min \(remainingSeconds) sec"
        } else {
            return "\(remainingSeconds) sec"
        }
    }
    
    private func getProgressValue() -> Double {
        let totalTime: TimeInterval = 900 // 15 minutes
        let elapsed = totalTime - timeRemaining
        return min(max(elapsed / totalTime, 0), 1)
    }
}

struct ActionButtonsSection: View {
    let status: BookingRequestStatus
    let onCancel: () -> Void
    let onFindAlternatives: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            switch status {
            case .pending:
                QROWDButton(
                    title: "Cancel Request",
                    isLoading: false,
                    isEnabled: true
                ) {
                    onCancel()
                }
                
            case .accepted:
                QROWDButton(
                    title: "View Booking Details",
                    isLoading: false,
                    isEnabled: true
                ) {
                    // Navigate to booking details
                }
                
            case .declined, .expired:
                QROWDButton(
                    title: "Find Alternative DJs",
                    isLoading: false,
                    isEnabled: true
                ) {
                    onFindAlternatives()
                }
                
            case .cancelled:
                QROWDButton(
                    title: "Start New Search",
                    isLoading: false,
                    isEnabled: true
                ) {
                    onFindAlternatives()
                }
            }
        }
    }
}

#Preview {
    BookingRequestStatusView(
        bookingResult: InstantBookingResult(
            bookingId: "BR123456",
            djInfo: DJBasicInfo(id: "dj1", stageName: "DJ Phoenix"),
            status: .pending,
            estimatedArrival: nil,
            totalCost: 450.0,
            cancellationDeadline: nil,
            responseDeadline: Date().addingTimeInterval(900)
        )
    )
} 