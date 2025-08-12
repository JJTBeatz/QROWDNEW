import SwiftUI

struct CancellationPolicyView: View {
    let booking: BookingDetail
    @State private var cancellationResult: CancellationResult?
    @State private var showingCancellationAlert = false
    @State private var showingEmergencyOptions = false
    @State private var selectedEmergencyReason: EmergencyReason?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                QROWDTheme.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            
                            Text("Cancel Booking")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                        }
                        .padding(.top, 20)
                        
                        // Booking Summary
                        BookingSummaryCard(booking: booking)
                        
                        // Cancellation Impact
                        if let result = cancellationResult {
                            CancellationImpactCard(result: result)
                        }
                        
                        // Policy Timeline
                        CancellationTimelineView()
                        
                        // Emergency Options
                        EmergencyOptionsCard {
                            showingEmergencyOptions = true
                        }
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            // Standard Cancellation
                            QROWDButton(
                                title: "Cancel Booking",
                                isLoading: false,
                                isEnabled: true
                            ) {
                                showingCancellationAlert = true
                            }
                            
                            // Keep Booking
                            QROWDButton(
                                title: "Keep Booking",
                                isLoading: false,
                                isEnabled: true
                            ) {
                                dismiss()
                            }
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Cancellation Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(QROWDTheme.primaryText)
                }
            }
        }
        .alert("Confirm Cancellation", isPresented: $showingCancellationAlert) {
            Button("Cancel Booking", role: .destructive) {
                processCancellation()
            }
            Button("Keep Booking", role: .cancel) { }
        } message: {
            if let result = cancellationResult {
                Text("You will receive a \(Int(result.refundPercentage * 100))% refund (\(formatCurrency(result.refundPercentage * booking.totalPrice)))")
            }
        }
        .sheet(isPresented: $showingEmergencyOptions) {
            EmergencyReasonSheet { reason in
                selectedEmergencyReason = reason
                processEmergencyCancellation(reason: reason)
            }
        }
        .onAppear {
            calculateCancellationImpact()
        }
    }
    
    private func calculateCancellationImpact() {
        cancellationResult = CancellationPolicyManager.shared.calculateCancellationPolicy(
            for: booking,
            cancelledBy: .host
        )
    }
    
    private func processCancellation() {
        // Process standard cancellation
        Task {
            // Call API to cancel booking
            dismiss()
        }
    }
    
    private func processEmergencyCancellation(reason: EmergencyReason) {
        let emergencyResult = CancellationPolicyManager.shared.handleEmergencyCancellation(
            booking: booking,
            reason: reason
        )
        
        // Process emergency cancellation
        Task {
            // Call API with emergency reason
            dismiss()
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.0f", amount)
    }
}

// MARK: - Supporting Views

struct BookingSummaryCard: View {
    let booking: BookingDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Booking Details")
                .font(QROWDTheme.bodyFont.weight(.semibold))
                .foregroundColor(QROWDTheme.primaryText)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Event Date:")
                    Spacer()
                    Text(formatDate(booking.eventDate))
                }
                
                HStack {
                    Text("Total Amount:")
                    Spacer()
                    Text("$\(Int(booking.totalPrice))")
                        .foregroundColor(QROWDTheme.accentColor)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Time Until Event:")
                    Spacer()
                    Text(timeUntilEvent(booking.eventDate))
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }
            }
            .font(QROWDTheme.bodyFont)
            .foregroundColor(QROWDTheme.primaryText)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func timeUntilEvent(_ date: Date) -> String {
        let timeInterval = date.timeIntervalSince(Date())
        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 24 {
            let days = hours / 24
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}

struct CancellationImpactCard: View {
    let result: CancellationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: severityIcon(result.severity))
                    .foregroundColor(severityColor(result.severity))
                    .font(.title2)
                
                Text("Cancellation Impact")
                    .font(QROWDTheme.bodyFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ImpactRow(
                    title: "Refund Amount",
                    value: "\(Int(result.refundPercentage * 100))%",
                    color: result.refundPercentage > 0.5 ? .green : .orange
                )
                
                if result.penalty > 0 {
                    ImpactRow(
                        title: "Penalty Fee",
                        value: "$\(Int(result.penalty))",
                        color: .red
                    )
                }
                
                if result.djCompensation > 0 {
                    ImpactRow(
                        title: "DJ Compensation",
                        value: "$\(Int(result.djCompensation))",
                        color: .blue
                    )
                }
            }
            
            Text(result.reason)
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.secondaryText)
                .padding(.top, 8)
        }
        .padding(QROWDTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                .fill(QROWDTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                        .stroke(severityColor(result.severity).opacity(0.3), lineWidth: 2)
                )
        )
        .padding(.horizontal, QROWDTheme.cardPadding)
    }
    
    private func severityIcon(_ severity: CancellationSeverity) -> String {
        switch severity {
        case .none: return "checkmark.circle.fill"
        case .low: return "exclamationmark.circle.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .high: return "xmark.circle.fill"
        case .severe: return "xmark.octagon.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
    
    private func severityColor(_ severity: CancellationSeverity) -> Color {
        switch severity {
        case .none: return .green
        case .low: return .yellow
        case .moderate: return .orange
        case .high: return .red
        case .severe: return Color(.systemRed)
        case .critical: return .purple
        }
    }
}

struct ImpactRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(QROWDTheme.bodyFont)
                .foregroundColor(QROWDTheme.primaryText)
            
            Spacer()
            
            Text(value)
                .font(QROWDTheme.bodyFont.weight(.semibold))
                .foregroundColor(color)
        }
    }
}

struct CancellationTimelineView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cancellation Timeline")
                .font(QROWDTheme.bodyFont.weight(.semibold))
                .foregroundColor(QROWDTheme.primaryText)
            
            VStack(spacing: 12) {
                TimelineItem(
                    time: "48+ hours",
                    refund: "100%",
                    penalty: "None",
                    color: .green
                )
                
                TimelineItem(
                    time: "24-48 hours",
                    refund: "75%",
                    penalty: "25%",
                    color: .yellow
                )
                
                TimelineItem(
                    time: "6-24 hours",
                    refund: "50%",
                    penalty: "50%",
                    color: .orange
                )
                
                TimelineItem(
                    time: "2-6 hours",
                    refund: "25%",
                    penalty: "75%",
                    color: .red
                )
                
                TimelineItem(
                    time: "< 2 hours",
                    refund: "0%",
                    penalty: "100%",
                    color: .purple
                )
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

struct TimelineItem: View {
    let time: String
    let refund: String
    let penalty: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(time)
                    .font(QROWDTheme.captionFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text("Refund: \(refund) • Penalty: \(penalty)")
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            
            Spacer()
        }
    }
}

struct EmergencyOptionsCard: View {
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Situations")
                .font(QROWDTheme.bodyFont.weight(.semibold))
                .foregroundColor(QROWDTheme.primaryText)
            
            Text("If you need to cancel due to an emergency, you may be eligible for full refund protection.")
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.secondaryText)
            
            Button(action: action) {
                HStack {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(.blue)
                    
                    Text("Report Emergency Cancellation")
                        .font(QROWDTheme.bodyFont.weight(.medium))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
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

struct EmergencyReasonSheet: View {
    let onSelection: (EmergencyReason) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    ForEach([
                        EmergencyReason.weatherEvent,
                        EmergencyReason.venueEmergency,
                        EmergencyReason.medicalEmergency,
                        EmergencyReason.equipmentFailure,
                        EmergencyReason.governmentRestrictions
                    ], id: \.self) { reason in
                        Button {
                            onSelection(reason)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: iconFor(reason))
                                    .foregroundColor(QROWDTheme.accentColor)
                                    .frame(width: 24)
                                
                                Text(reason.description)
                                    .foregroundColor(QROWDTheme.primaryText)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Emergency Reason")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func iconFor(_ reason: EmergencyReason) -> String {
        switch reason {
        case .weatherEvent: return "cloud.rain.fill"
        case .venueEmergency: return "building.2.crop.circle.fill"
        case .medicalEmergency: return "cross.case.fill"
        case .equipmentFailure: return "wrench.and.screwdriver.fill"
        case .governmentRestrictions: return "building.columns.fill"
        }
    }
}

#Preview {
    CancellationPolicyView(
        booking: BookingDetail(
            id: "test",
            totalPrice: 500,
            eventDate: Date().addingTimeInterval(86400 * 2), // 2 days from now
            djId: "dj1",
            hostId: "host1",
            status: .confirmed
        )
    )
} 