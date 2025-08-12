import SwiftUI
import CoreLocation
import Foundation

struct HostSearchView: View {
    @StateObject private var viewModel = HostSearchViewModel()
    @StateObject private var eventsViewModel = TrendingEventsViewModel()
    @State private var showingFilters = false
    
    @State private var showingInstantBooking = false
    @State private var showingTracking = false  
    @State private var showingCancellation = false
    @State private var currentBooking: BookingDetail?
    
    var body: some View {
        ZStack {
            // Animated background
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Enhanced Header with Logo and Filters
                VStack(spacing: 16) {
                    HStack {
                        // QROWD Logo
                        QROWDLogo(size: 40, showGlow: true, showShadow: false, animated: true)
                            .bounceOnAppear()
                        
                        Spacer()
                        
                        // Title
                        Text("Find DJs & Events")
                            .font(QROWDTheme.headlineFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .fadeInUp(delay: 0.1)
                        
                        Spacer()
                        
                        // Animated filter button
                        Button {
                            showingFilters = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title2)
                                .foregroundColor(QROWDTheme.accentColor)
                                .scaleEffect(1.0)
                                .pressAnimation()
                        }
                        .floatingAnimation()
                    }
                    
                    // Enhanced Search Bar
                    QROWDTextField(
                        text: $viewModel.searchText,
                        placeholder: "Search by city...",
                        icon: "magnifyingglass"
                    )
                    .slideInFromRight(delay: 0.2)
                    .onChange(of: viewModel.searchText) {
                        viewModel.filters.city = viewModel.searchText
                        Task {
                            await viewModel.searchDJs()
                        }
                    }
                }
                .padding(.horizontal, QROWDTheme.cardPadding)
                .padding(.top, 20)
                
                // Main Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Enhanced Trending Tonight Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("🪩 Trending Tonight")
                                        .font(QROWDTheme.headlineFont)
                                        .foregroundColor(QROWDTheme.primaryText)
                                        .bounceOnAppear(delay: 0.3)
                                    
                                    Text("Popular events happening now")
                                        .font(QROWDTheme.captionFont)
                                        .foregroundColor(QROWDTheme.secondaryText)
                                        .fadeInUp(delay: 0.4)
                                }
                                
                                Spacer()
                                
                                NavigationLink(destination: AllEventsView()) {
                                    Text("See All")
                                        .font(QROWDTheme.captionFont)
                                        .foregroundColor(QROWDTheme.accentColor)
                                }
                                .pressAnimation()
                                .fadeInUp(delay: 0.5)
                            }
                            
                            // Horizontal scrolling events with staggered animation
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    if eventsViewModel.isLoading {
                                        ForEach(0..<3, id: \.self) { index in
                                            EventCardSkeletonView()
                                                .shimmer()
                                                .staggeredAnimation(index: index, total: 3)
                                        }
                                    } else {
                                        ForEach(Array(eventsViewModel.trendingEvents.enumerated()), id: \.element.id) { index, event in
                                            InteractiveCard(onTap: {
                                                eventsViewModel.selectedEvent = event
                                            }) {
                                                TrendingEventCard(event: event) {
                                                    eventsViewModel.selectedEvent = event
                                                }
                                            }
                                            .staggeredAnimation(index: index, total: eventsViewModel.trendingEvents.count)
                                        }
                                    }
                                }
                                .padding(.horizontal, QROWDTheme.cardPadding)
                            }
                        }
                        
                        // Enhanced DJ Search Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("🎧 Find DJs")
                                        .font(QROWDTheme.headlineFont)
                                        .foregroundColor(QROWDTheme.primaryText)
                                        .bounceOnAppear(delay: 0.6)
                                    
                                    Text("Book DJs for private events")
                                        .font(QROWDTheme.captionFont)
                                        .foregroundColor(QROWDTheme.secondaryText)
                                        .fadeInUp(delay: 0.7)
                                }
                                
                                Spacer()
                            }
                            
                            // Enhanced Quick Filters with animations
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // Instant Booking Button
                                    HostSearchActionButton(
                                        title: "⚡ Instant",
                                        subtitle: "Book in 2-4hrs",
                                        color: .orange,
                                        isSelected: false
                                    ) {
                                        showingInstantBooking = true
                                    }
                                    .staggeredAnimation(index: 0, total: 6)
                                    
                                    QuickFilterButton(
                                        title: "Available Now",
                                        icon: "clock.fill",
                                        isSelected: viewModel.filters.availableNow
                                    ) {
                                        viewModel.filters.availableNow.toggle()
                                        Task {
                                            await viewModel.searchDJs()
                                        }
                                    }
                                    .staggeredAnimation(index: 1, total: 6)
                                    
                                    ForEach(Array(["House", "Hip-Hop", "Latin", "Rock"].enumerated()), id: \.element) { index, genre in
                                        QuickFilterButton(
                                            title: genre,
                                            icon: "music.note",
                                            isSelected: viewModel.filters.genres.contains(genre)
                                        ) {
                                            if viewModel.filters.genres.contains(genre) {
                                                viewModel.filters.genres.removeAll { $0 == genre }
                                            } else {
                                                viewModel.filters.genres.append(genre)
                                            }
                                            Task {
                                                await viewModel.searchDJs()
                                            }
                                        }
                                        .staggeredAnimation(index: index + 2, total: 6) // Adjusted index for new buttons
                                    }
                                }
                                .padding(.horizontal, QROWDTheme.cardPadding)
                            }
                            
                            // Enhanced DJ Results with animations
                            if viewModel.isLoading {
                                VStack(spacing: 16) {
                                    ForEach(0..<3, id: \.self) { index in
                                        DJCardSkeletonView()
                                            .shimmer()
                                            .staggeredAnimation(index: index, total: 3)
                                    }
                                }
                                .padding(.horizontal, QROWDTheme.cardPadding)
                            } else if viewModel.djCards.isEmpty {
                                AnimatedCard {
                                    VStack(spacing: 16) {
                                        QROWDLogo(size: 60, showGlow: true, showShadow: false, animated: true)
                                        
                                        Image(systemName: "music.note.house")
                                            .font(.system(size: 40))
                                            .foregroundColor(QROWDTheme.secondaryText)
                                            .floatingAnimation()
                                        
                                        Text("No DJs Found")
                                            .font(QROWDTheme.headlineFont)
                                            .foregroundColor(QROWDTheme.primaryText)
                                        
                                        Text("Try adjusting your filters or search area")
                                            .font(QROWDTheme.bodyFont)
                                            .foregroundColor(QROWDTheme.secondaryText)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.vertical, 20)
                                }
                                .padding(.horizontal, QROWDTheme.cardPadding)
                                .bounceOnAppear(delay: 0.3)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(Array(viewModel.djCards.enumerated()), id: \.element.id) { index, djCard in
                                        InteractiveCard(onTap: {
                                            viewModel.selectedDJ = djCard
                                        }) {
                                            DJCardView(djCard: djCard, onTap: {
                                                viewModel.selectedDJ = djCard
                                            }, onTrackTap: {
                                                showingTracking = true
                                            })
                                        }
                                        .staggeredAnimation(index: index, total: viewModel.djCards.count)
                                    }
                                }
                                .padding(.horizontal, QROWDTheme.cardPadding)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            HostFiltersView(filters: $viewModel.filters) {
                Task {
                    await viewModel.searchDJs()
                }
            }
        }
        .sheet(item: $viewModel.selectedDJ) { djCard in
            DJProfileView(djId: djCard.id)
        }
        .sheet(item: $eventsViewModel.selectedEvent) { event in
            EventDetailView(event: event)
        }
        .sheet(isPresented: $showingInstantBooking) {
            InstantBookingView()
        }
        .sheet(isPresented: $showingTracking) {
            RealTimeTrackingView(bookingId: "current_booking_id")
        }
        .sheet(isPresented: $showingCancellation) {
            if let booking = currentBooking {
                CancellationPolicyView(booking: booking)
            }
        }
        .task {
            await viewModel.searchDJs()
            await eventsViewModel.loadTrendingEvents()
        }
        .refreshable {
            await eventsViewModel.loadTrendingEvents()
            await viewModel.searchDJs()
        }
    }
}

// MARK: - DJ Card View
struct DJCardView: View {
    let djCard: DJCard
    let onTap: () -> Void
    let onTrackTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Thumbnail Image
                AsyncImage(url: URL(string: djCard.thumbnailURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(QROWDTheme.cardGradient)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 40))
                                .foregroundColor(QROWDTheme.secondaryText)
                        )
                }
                .frame(height: 120)
                .clipped()
                
                // Card Content
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(djCard.stageName)
                                    .font(QROWDTheme.headlineFont)
                                    .foregroundColor(QROWDTheme.primaryText)
                                
                                if djCard.isPro {
                                PROBadgeView(size: .small)
                            }
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundColor(QROWDTheme.secondaryText)
                                
                                Text(djCard.city)
                                    .font(QROWDTheme.captionFont)
                                    .foregroundColor(QROWDTheme.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                
                                Text(String(format: "%.1f", djCard.rating))
                                    .font(QROWDTheme.captionFont.weight(.semibold))
                                    .foregroundColor(QROWDTheme.primaryText)
                            }
                            
                            Text("$\(Int(djCard.pricePerHour))/hr")
                                .font(QROWDTheme.bodyFont.weight(.semibold))
                                .foregroundColor(QROWDTheme.accentColor)
                        }
                    }
                    
                    // Genre Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(djCard.genres.prefix(4), id: \.self) { genre in
                                Text(genre)
                                    .font(QROWDTheme.captionFont)
                                    .foregroundColor(QROWDTheme.primaryText)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(QROWDTheme.accentColor.opacity(0.2))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(QROWDTheme.accentColor.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                    
                    // Status and Action
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(djCard.isAvailable ? .green : .orange)
                                .frame(width: 8, height: 8)
                            
                            Text(djCard.isAvailable ? "Available" : "Busy")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(djCard.isAvailable ? .green : .orange)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button("Track") {
                                onTrackTap()
                            }
                            .font(QROWDTheme.captionFont.weight(.semibold))
                            .foregroundColor(.blue)
                            
                            Button("Profile") {
                                onTap()
                            }
                            .font(QROWDTheme.captionFont.weight(.semibold))
                            .foregroundColor(QROWDTheme.accentColor)
                        }
                    }
                }
                .padding(QROWDTheme.cardPadding)
            }
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(QROWDTheme.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                            .stroke(QROWDTheme.borderColor, lineWidth: 1)
                    )
                    .shadow(
                        color: QROWDTheme.cardShadow,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(CardButtonStyle())
    }
}

// QuickFilterButton is imported from QROWDComponents.swift

// MARK: - Card Button Style
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// HostSearchViewModel is imported from ViewModels/HostSearchViewModel.swift

// MARK: - Trending Event Card
struct TrendingEventCard: View {
    let event: TrendingEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Event Image
                AsyncImage(url: URL(string: event.thumbnailURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(QROWDTheme.cardGradient)
                        .overlay(
                            Image(systemName: "music.mic")
                                .font(.system(size: 30))
                                .foregroundColor(QROWDTheme.secondaryText)
                        )
                }
                .frame(width: 280, height: 160)
                .clipped()
                
                // Event Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(QROWDTheme.headlineFont)
                        .foregroundColor(QROWDTheme.primaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(QROWDTheme.accentColor)
                        
                        Text(formatEventTime(event.eventDate, startTime: event.startTime))
                            .font(QROWDTheme.captionFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(QROWDTheme.secondaryText)
                        
                        Text(event.venueName.isEmpty ? event.location : event.venueName)
                            .font(QROWDTheme.captionFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .lineLimit(1)
                    }
                    
                    if let djName = event.djStageName {
                        HStack(spacing: 4) {
                            Image(systemName: "headphones")
                                .font(.caption)
                                .foregroundColor(QROWDTheme.accentColor)
                            
                            Text(djName)
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.accentColor)
                                .lineLimit(1)
                        }
                    }
                    
                    HStack {
                        Text("$\(String(format: "%.0f", event.ticketPrice))")
                            .font(QROWDTheme.headlineFont)
                            .foregroundColor(QROWDTheme.accentColor)
                        
                        Spacer()
                        
                        Text("\(event.availableTickets) left")
                            .font(QROWDTheme.captionFont)
                            .foregroundColor(event.availableTickets < 10 ? .orange : QROWDTheme.secondaryText)
                    }
                }
                .padding(12)
                .frame(width: 280, alignment: .leading)
            }
            .background(QROWDTheme.cardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatEventTime(_ date: Date, startTime: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateString = formatter.string(from: date)
        
        // Convert 24-hour time to 12-hour format
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        if let time = timeFormatter.date(from: startTime) {
            timeFormatter.dateFormat = "h:mm a"
            let formattedTime = timeFormatter.string(from: time)
            return "\(dateString) • \(formattedTime)"
        }
        
        return "\(dateString) • \(startTime)"
    }
}

// MARK: - Skeleton Views
struct EventCardSkeletonView: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 280, height: 160)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                    .shimmer()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .shimmer()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .shimmer()
            }
            .padding(12)
            .frame(width: 280, alignment: .leading)
        }
        .background(QROWDTheme.cardBackground)
        .cornerRadius(12)
    }
}

struct DJCardSkeletonView: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 120)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                    .shimmer()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .shimmer()
            }
            .padding(12)
        }
        .background(QROWDTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// Note: Shimmer functionality is now handled by QROWDAnimations.swift

// MARK: - All Events View
struct AllEventsView: View {
    @StateObject private var eventsViewModel = TrendingEventsViewModel()
    
    var body: some View {
        ZStack {
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(eventsViewModel.trendingEvents) { event in
                        TrendingEventCard(event: event) {
                            eventsViewModel.selectedEvent = event
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                    }
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle("All Events")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await eventsViewModel.loadTrendingEvents()
        }
        .sheet(item: $eventsViewModel.selectedEvent) { event in
            EventDetailView(event: event)
        }
    }
}

#Preview {
    HostSearchView()
}

// MARK: - Host Search Action Button Component
struct HostSearchActionButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isSelected ? .white : color)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : color.opacity(0.7))
            }
            .frame(width: 80, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 