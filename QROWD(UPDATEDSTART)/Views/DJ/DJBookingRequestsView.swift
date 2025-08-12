import SwiftUI

// Type aliases to resolve ambiguity
typealias DJIncomingBookingRequest = BookingRequest
typealias DJBookingRequestStatus = BookingRequestStatus

struct DJBookingRequestsView: View {
    @StateObject private var viewModel = DJBookingRequestsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                QROWDTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            Text("🎵 Booking Requests")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            Spacer()
                            
                            if viewModel.pendingRequests.count > 0 {
                                Text("\(viewModel.pendingRequests.count) pending")
                                    .font(QROWDTheme.captionFont)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.orange.opacity(0.1))
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    // Requests List
                    if viewModel.isLoading {
                        LoadingView()
                    } else if viewModel.allRequests.isEmpty {
                        EmptyRequestsView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Pending Requests (Priority)
                                if !viewModel.pendingRequests.isEmpty {
                                    DJRequestSectionHeader(title: "Pending Requests", color: .orange)
                                    
                                    ForEach(viewModel.pendingRequests, id: \.id) { request in
                                        BookingRequestCard(
                                            request: request,
                                            onAccept: { request in
                                                viewModel.acceptRequest(request)
                                            },
                                            onDecline: { request in
                                                viewModel.declineRequest(request)
                                            }
                                        )
                                    }
                                }
                                
                                // Recent Requests
                                if !viewModel.recentRequests.isEmpty {
                                    DJRequestSectionHeader(title: "Recent", color: .gray)
                                    
                                    ForEach(viewModel.recentRequests, id: \.id) { request in
                                        BookingRequestCard(
                                            request: request,
                                            onAccept: nil,
                                            onDecline: nil
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadRequests()
        }
    }
}

// MARK: - Supporting Views

struct DJRequestSectionHeader: View {
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(QROWDTheme.bodyFont.weight(.semibold))
                .foregroundColor(color)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct BookingRequestCard: View {
    let request: DJIncomingBookingRequest
    let onAccept: ((DJIncomingBookingRequest) -> Void)?
    let onDecline: ((DJIncomingBookingRequest) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Booking Request")
                        .font(QROWDTheme.bodyFont.weight(.semibold))
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text(formatRequestTime(request.createdAt))
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
                
                Spacer()
                
                StatusBadge(status: request.status)
            }
            
            // Event Details
            VStack(spacing: 12) {
                RequestDetailRow(
                    icon: "location.fill",
                    title: "Location",
                    value: request.details.location
                )
                
                RequestDetailRow(
                    icon: "clock.fill",
                    title: "Date & Time",
                    value: formatEventDateTime(request.details.startTime)
                )
                
                RequestDetailRow(
                    icon: "timer",
                    title: "Duration",
                    value: formatDuration(request.details.duration)
                )
                
                RequestDetailRow(
                    icon: "dollarsign.circle.fill",
                    title: "Payment",
                    value: formatPayment(request.estimatedCost, request.surgeMultiplier)
                )
            }
            
            // Message
            if let message = request.message {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message from Host:")
                        .font(QROWDTheme.captionFont.weight(.medium))
                        .foregroundColor(QROWDTheme.secondaryText)
                    
                    Text(message)
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.primaryText)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(QROWDTheme.accentColor.opacity(0.1))
                        )
                }
            }
            
            // Actions
            if request.status == .pending {
                HStack(spacing: 12) {
                    QROWDButton(
                        title: "Decline",
                        isLoading: false,
                        isEnabled: true
                    ) {
                        onDecline?(request)
                    }
                    
                    QROWDButton(
                        title: "Accept",
                        isLoading: false,
                        isEnabled: true
                    ) {
                        onAccept?(request)
                    }
                }
                
                // Response Deadline
                if Date() < request.responseDeadline {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text("Respond by \(formatTime(request.responseDeadline))")
                            .font(QROWDTheme.captionFont)
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(QROWDTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(statusBorderColor(request.status), lineWidth: 1)
                )
        )
    }
    
    private func formatRequestTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatEventDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        return "\(hours) hour\(hours == 1 ? "" : "s")"
    }
    
    private func formatPayment(_ cost: Double, _ surgeMultiplier: Double) -> String {
        if surgeMultiplier > 1.0 {
            return "$\(Int(cost)) (\(String(format: "%.1f", surgeMultiplier))x surge)"
        } else {
            return "$\(Int(cost))"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func statusBorderColor(_ status: DJBookingRequestStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .accepted: return .green
        case .declined: return .red
        case .expired: return .gray
        case .cancelled: return .gray
        }
    }
}

struct RequestDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(QROWDTheme.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                
                Text(value)
                    .font(QROWDTheme.bodyFont)
                    .foregroundColor(QROWDTheme.primaryText)
            }
            
            Spacer()
        }
    }
}

struct StatusBadge: View {
    let status: DJBookingRequestStatus
    
    var body: some View {
        Text(status.description)
            .font(QROWDTheme.captionFont.weight(.medium))
            .foregroundColor(badgeTextColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(badgeBackgroundColor)
            )
    }
    
    private var badgeTextColor: Color {
        switch status {
        case .pending: return .orange
        case .accepted: return .green
        case .declined: return .red
        case .expired: return .gray
        case .cancelled: return .gray
        }
    }
    
    private var badgeBackgroundColor: Color {
        switch status {
        case .pending: return .orange.opacity(0.1)
        case .accepted: return .green.opacity(0.1)
        case .declined: return .red.opacity(0.1)
        case .expired: return .gray.opacity(0.1)
        case .cancelled: return .gray.opacity(0.1)
        }
    }
}

struct EmptyRequestsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(QROWDTheme.secondaryText)
            
            Text("No Booking Requests")
                .font(QROWDTheme.headlineFont)
                .foregroundColor(QROWDTheme.primaryText)
            
            Text("When hosts send you booking requests, they'll appear here.")
                .font(QROWDTheme.bodyFont)
                .foregroundColor(QROWDTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(QROWDTheme.backgroundColor)
    }
}

// MARK: - ViewModel

@MainActor
class DJBookingRequestsViewModel: ObservableObject {
    @Published var allRequests: [DJIncomingBookingRequest] = []
    @Published var isLoading = false
    
    var pendingRequests: [DJIncomingBookingRequest] {
        allRequests.filter { $0.status == .pending }
    }
    
    var recentRequests: [DJIncomingBookingRequest] {
        allRequests.filter { $0.status != .pending }
    }
    
    func loadRequests() {
        isLoading = true
        
        Task {
            // Simulate loading requests
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            let mockRequests = [
                BookingRequest(
                    id: "req1",
                    djId: "current_dj_id",
                    hostId: "host1",
                    details: InstantBookingDetails(
                        location: "Downtown LA",
                        startTime: Date().addingTimeInterval(7200),
                        duration: 14400,
                        estimatedCost: 400
                    ),
                    estimatedCost: 600,
                    surgeMultiplier: 1.5,
                    message: "Looking for a DJ for my birthday party! House music preferred."
                ),
                BookingRequest(
                    id: "req2",
                    djId: "current_dj_id",
                    hostId: "host2",
                    details: InstantBookingDetails(
                        location: "Beverly Hills",
                        startTime: Date().addingTimeInterval(10800),
                        duration: 10800,
                        estimatedCost: 500
                    ),
                    estimatedCost: 1000,
                    surgeMultiplier: 2.0,
                    message: "Corporate event needs professional DJ. High-energy music for young crowd."
                )
            ]
            
            await MainActor.run {
                self.allRequests = mockRequests
                self.isLoading = false
            }
        }
    }
    
    func acceptRequest(_ request: DJIncomingBookingRequest) {
        Task {
            do {
                _ = try await InstantBookingManager.shared.respondToBookingRequest(
                    requestId: request.id,
                    djId: request.djId,
                    response: .accepted(estimatedArrival: Date().addingTimeInterval(3600))
                )
                
                await MainActor.run {
                    // Update local state
                    if let index = allRequests.firstIndex(where: { $0.id == request.id }) {
                        allRequests[index] = BookingRequest(
                            id: request.id,
                            djId: request.djId,
                            hostId: request.hostId,
                            details: request.details,
                            estimatedCost: request.estimatedCost,
                            surgeMultiplier: request.surgeMultiplier,
                            message: request.message
                        )
                    }
                }
            } catch {
                print("Error accepting request: \(error)")
            }
        }
    }
    
    func declineRequest(_ request: DJIncomingBookingRequest) {
        Task {
            do {
                _ = try await InstantBookingManager.shared.respondToBookingRequest(
                    requestId: request.id,
                    djId: request.djId,
                    response: .declined(reason: "Schedule conflict")
                )
                
                await MainActor.run {
                    // Update local state
                    if let index = allRequests.firstIndex(where: { $0.id == request.id }) {
                        allRequests[index] = BookingRequest(
                            id: request.id,
                            djId: request.djId,
                            hostId: request.hostId,
                            details: request.details,
                            estimatedCost: request.estimatedCost,
                            surgeMultiplier: request.surgeMultiplier,
                            message: request.message
                        )
                    }
                }
            } catch {
                print("Error declining request: \(error)")
            }
        }
    }
}

#Preview {
    DJBookingRequestsView()
} 