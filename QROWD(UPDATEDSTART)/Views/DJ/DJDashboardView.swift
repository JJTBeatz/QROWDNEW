import SwiftUI

struct DJDashboardView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @State private var djProfile: DJProfileDetail?
    @State private var isLoading = true
    @State private var upcomingBookings: [BookingRequest] = []
    @State private var recentActivity: [DJActivity] = []
    @State private var earnings: DJEarnings = DJEarnings()
    
    var body: some View {
        ZStack {
            // Background
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: QROWDTheme.sectionSpacing) {
                    // Header with Logo
                    VStack(spacing: 16) {
                        HStack {
                            // QROWD Logo
                            QROWDLogo(size: 36, showGlow: true, showShadow: false, animated: true)
                            
                            Spacer()
                            
                            // DJ Dashboard Title
                            Text("DJ Dashboard")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            Spacer()
                            
                            // Profile Avatar
                            AsyncImage(url: URL(string: djProfile?.promoMediaURLs.first ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(QROWDTheme.cardBackground)
                                    .overlay(
                                        Image(systemName: "person.circle")
                                            .foregroundColor(QROWDTheme.secondaryText)
                                    )
                            }
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                        .padding(.top, 8)
                    }
                    
                    if isLoading {
                        VStack(spacing: 20) {
                            QROWDLogo.loading
                            
                            Text("Loading your dashboard...")
                                .font(QROWDTheme.bodyFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                        }
                        .padding(.top, 60)
                    } else {
                        VStack(spacing: 24) {
                            // Welcome Section
                            WelcomeSection(djProfile: djProfile)
                            
                            // Stats Overview
                            StatsOverviewSection(earnings: earnings)
                            
                            // Upcoming Bookings
                            UpcomingBookingsSection(bookings: upcomingBookings)
                            
                            // Recent Activity
                            RecentActivitySection(activities: recentActivity)
                            
                            // Quick Actions
                            QuickActionsSection()
                            
                            // Bottom padding
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                    }
                }
            }
        }
        .task {
            await loadDashboardData()
        }
        .refreshable {
            await loadDashboardData()
        }
    }
    
    private func loadDashboardData() async {
        isLoading = true
        
        do {
            // Load DJ profile
            djProfile = try await supabase.getCurrentUserDJProfile()
            
            // Load dashboard data
            async let bookingsTask = loadUpcomingBookings()
            async let activityTask = loadRecentActivity()
            async let earningsTask = loadEarnings()
            
            await bookingsTask
            await activityTask
            await earningsTask
            
        } catch {
            print("Error loading dashboard: \(error)")
        }
        
        isLoading = false
    }
    
    private func loadUpcomingBookings() async {
        // Mock data for now
        upcomingBookings = [
            BookingRequest(
                id: "1",
                djId: "current_dj_id",
                hostId: "host_1",
                details: InstantBookingDetails(
                    location: "Downtown LA",
                    startTime: Date().addingTimeInterval(86400),
                    duration: 4 * 3600, // 4 hours
                    estimatedCost: 350.0
                ),
                estimatedCost: 350.0,
                surgeMultiplier: 1.0,
                message: "Rooftop Party",
                status: .accepted
            ),
            BookingRequest(
                id: "2",
                djId: "current_dj_id",
                hostId: "host_2",
                details: InstantBookingDetails(
                    location: "Beverly Hills",
                    startTime: Date().addingTimeInterval(172800),
                    duration: 4 * 3600, // 4 hours
                    estimatedCost: 275.0
                ),
                estimatedCost: 275.0,
                surgeMultiplier: 1.0,
                message: "Birthday Celebration",
                status: .pending
            )
        ]
    }
    
    private func loadRecentActivity() async {
        // Mock data for now
        recentActivity = [
            DJActivity(
                id: "1",
                type: .newBooking,
                title: "New booking request",
                description: "Sarah M. wants to book you for a wedding",
                timestamp: Date().addingTimeInterval(-3600),
                icon: "calendar.badge.plus"
            ),
            DJActivity(
                id: "2",
                type: .payment,
                title: "Payment received",
                description: "$350 from last weekend's event",
                timestamp: Date().addingTimeInterval(-7200),
                icon: "dollarsign.circle.fill"
            ),
            DJActivity(
                id: "3",
                type: .review,
                title: "New review",
                description: "Mike R. left you a 5-star review",
                timestamp: Date().addingTimeInterval(-14400),
                icon: "star.fill"
            )
        ]
    }
    
    private func loadEarnings() async {
        // Mock data for now
        earnings = DJEarnings(
            thisMonth: 1250.0,
            lastMonth: 980.0,
            totalEarnings: 15600.0,
            pendingPayments: 425.0
        )
    }
}

// MARK: - Welcome Section
struct WelcomeSection: View {
    let djProfile: DJProfileDetail?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back, \(djProfile?.stageName ?? "DJ")!")
                        .font(QROWDTheme.titleFont)
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text("Ready to make some music?")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
                
                Spacer()
                
                // Status indicator
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        
                        Text("Available")
                            .font(QROWDTheme.captionFont)
                            .foregroundColor(.green)
                    }
                    
                    Text("Online")
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
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
    }
}

// MARK: - Stats Overview Section
struct StatsOverviewSection: View {
    let earnings: DJEarnings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Month")
                .font(QROWDTheme.headlineFont)
                .foregroundColor(QROWDTheme.primaryText)
            
            HStack(spacing: 16) {
                DJStatCard(
                    title: "Earnings",
                    value: "$\(Int(earnings.thisMonth))",
                    change: "+\(Int(((earnings.thisMonth - earnings.lastMonth) / earnings.lastMonth) * 100))%",
                    isPositive: earnings.thisMonth > earnings.lastMonth,
                    icon: "dollarsign.circle.fill"
                )
                
                DJStatCard(
                    title: "Bookings",
                    value: "8",
                    change: "+25%",
                    isPositive: true,
                    icon: "calendar.badge.checkmark"
                )
            }
            
            HStack(spacing: 16) {
                DJStatCard(
                    title: "Rating",
                    value: "4.9",
                    change: "+0.1",
                    isPositive: true,
                    icon: "star.fill"
                )
                
                DJStatCard(
                    title: "Pending",
                    value: "$\(Int(earnings.pendingPayments))",
                    change: "3 payments",
                    isPositive: nil,
                    icon: "clock.fill"
                )
            }
        }
    }
}

// MARK: - Upcoming Bookings Section
struct UpcomingBookingsSection: View {
    let bookings: [BookingRequest]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming Bookings")
                    .font(QROWDTheme.headlineFont)
                    .foregroundColor(QROWDTheme.primaryText)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to bookings view
                }
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.accentColor)
            }
            
            if bookings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(QROWDTheme.secondaryText)
                    
                    Text("No upcoming bookings")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(bookings.prefix(3)) { booking in
                        BookingCard(booking: booking)
                    }
                }
            }
        }
    }
}

// MARK: - Recent Activity Section
struct RecentActivitySection: View {
    let activities: [DJActivity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(QROWDTheme.headlineFont)
                .foregroundColor(QROWDTheme.primaryText)
            
            VStack(spacing: 8) {
                ForEach(activities.prefix(4)) { activity in
                    ActivityCard(activity: activity)
                }
            }
        }
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(QROWDTheme.headlineFont)
                .foregroundColor(QROWDTheme.primaryText)
            
            HStack(spacing: 16) {
                QuickActionButton(
                    title: "Update Profile",
                    icon: "person.circle",
                    action: { /* TODO */ }
                )
                
                QuickActionButton(
                    title: "View Analytics",
                    icon: "chart.bar",
                    action: { /* TODO */ }
                )
            }
            
            HStack(spacing: 16) {
                QuickActionButton(
                    title: "Manage Availability",
                    icon: "calendar",
                    action: { /* TODO */ }
                )
                
                QuickActionButton(
                    title: "Payment Settings",
                    icon: "creditcard",
                    action: { /* TODO */ }
                )
            }
        }
    }
}

// MARK: - Supporting Views
struct DJStatCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool?
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(QROWDTheme.accentColor)
                    .font(.title3)
                
                Spacer()
                
                if let isPositive = isPositive {
                    Text(change)
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(isPositive ? .green : .red)
                } else {
                    Text(change)
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(QROWDTheme.titleFont)
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text(title)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
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

struct BookingCard: View {
    let booking: BookingRequest
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Event Booking")
                    .font(QROWDTheme.bodyFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text(booking.details.location)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                
                HStack(spacing: 8) {
                    Text(formatDate(booking.details.startTime))
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                    
                    Text("•")
                        .foregroundColor(QROWDTheme.secondaryText)
                    
                    Text(formatTime(booking.details.startTime))
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(booking.estimatedCost))")
                    .font(QROWDTheme.bodyFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text(booking.status.rawValue.capitalized)
                    .font(QROWDTheme.captionFont)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(statusColor(booking.status).opacity(0.2))
                    )
                    .foregroundColor(statusColor(booking.status))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                .fill(QROWDTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                        .stroke(QROWDTheme.borderColor, lineWidth: 1)
                )
        )
    }
    
    private func statusColor(_ status: BookingRequestStatus) -> Color {
        switch status {
        case .accepted: return .green
        case .pending: return .orange
        case .cancelled, .declined: return .red
        case .expired: return .gray
        }
    }
}

struct ActivityCard: View {
    let activity: DJActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(QROWDTheme.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(QROWDTheme.bodyFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text(activity.description)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            
            Spacer()
            
            Text(formatTime(activity.timestamp))
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.secondaryText)
        }
        .padding(12)
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

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(QROWDTheme.accentColor)
                
                Text(title)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.primaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(QROWDTheme.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                            .stroke(QROWDTheme.borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Models
struct DJEarnings {
    let thisMonth: Double
    let lastMonth: Double
    let totalEarnings: Double
    let pendingPayments: Double
    
    init(thisMonth: Double = 0, lastMonth: Double = 0, totalEarnings: Double = 0, pendingPayments: Double = 0) {
        self.thisMonth = thisMonth
        self.lastMonth = lastMonth
        self.totalEarnings = totalEarnings
        self.pendingPayments = pendingPayments
    }
}

struct DJActivity: Identifiable {
    let id: String
    let type: ActivityType
    let title: String
    let description: String
    let timestamp: Date
    let icon: String
    
    enum ActivityType {
        case newBooking
        case payment
        case review
        case profileUpdate
    }
}



// MARK: - Helper Functions
private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
}

private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

#Preview {
    DJDashboardView()
} 