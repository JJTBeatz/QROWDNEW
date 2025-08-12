import SwiftUI

struct AILaunchView: View {
    @State private var showingAIChat = false
    @StateObject private var aiManager = QROWDAIManager.shared
    @State private var totalDJs = 0
    @State private var totalBookings = 0
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: QROWDTheme.sectionSpacing) {
                    // Hero Section
                    VStack(spacing: 24) {
                        // QROWD Logo
                        QROWDLogo(size: 60, showGlow: true, showShadow: true, animated: true)
                            .padding(.bottom, 8)
                        
                        // AI Avatar with Animation
                        ZStack {
                            Circle()
                                .fill(QROWDTheme.buttonGradient)
                                .frame(width: 120, height: 120)
                                .shadow(
                                    color: QROWDTheme.buttonGlow,
                                    radius: 30,
                                    x: 0,
                                    y: 8
                                )
                                .scaleEffect(aiManager.isProcessing ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(), value: aiManager.isProcessing)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 12) {
                            Text("QROWD AI Assistant")
                                .font(QROWDTheme.titleFont)
                                .foregroundColor(QROWDTheme.primaryText)
                                .multilineTextAlignment(.center)
                            
                            Text("Your intelligent guide to the perfect DJ, venue, and nightlife experience")
                                .font(QROWDTheme.bodyFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                        }
                        
                        // Launch Button
                        QROWDButton(
                            title: "Start Chatting",
                            isLoading: false,
                            isEnabled: true
                        ) {
                            showingAIChat = true
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                    }
                    .padding(.top, 40)
                    
                    // Stats Section
                    if !isLoading {
                        VStack(spacing: 16) {
                            Text("Platform Stats")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            HStack(spacing: 16) {
                                                VStack {
                    Text("DJs Available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalDJs)")
                        .font(.title)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                VStack {
                    Text("Bookings Made")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalBookings)")
                        .font(.title)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                    }
                    
                    // Features Section
                    VStack(spacing: 20) {
                        Text("What I Can Help With")
                            .font(QROWDTheme.headlineFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        VStack(spacing: 12) {
                            FeatureRow(
                                icon: "magnifyingglass",
                                title: "Find DJs",
                                description: "Search for DJs by genre, location, budget, and availability"
                            )
                            
                            FeatureRow(
                                icon: "building.2",
                                title: "Discover Venues",
                                description: "Get recommendations for the perfect event space"
                            )
                            
                            FeatureRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Trending Insights",
                                description: "See what's popular and trending in nightlife"
                            )
                            
                            FeatureRow(
                                icon: "questionmark.circle",
                                title: "Expert Advice",
                                description: "Get tips and answers about event planning and booking"
                            )
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Quick Actions
                    VStack(spacing: 16) {
                        Text("Quick Questions")
                            .font(QROWDTheme.headlineFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        VStack(spacing: 8) {
                            AIQuickActionButton(text: "Find me a DJ for a rooftop party in LA under $300") {
                                showingAIChat = true
                            }
                            
                            AIQuickActionButton(text: "What's trending this weekend?") {
                                showingAIChat = true
                            }
                            
                            AIQuickActionButton(text: "Show me House DJs with high ratings") {
                                showingAIChat = true
                            }
                            
                            AIQuickActionButton(text: "Recommend venues for 100+ people") {
                                showingAIChat = true
                            }
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationTitle("QROWD AI")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadStats()
        }
        .sheet(isPresented: $showingAIChat) {
            QROWDAIAssistantView()
        }
    }
    
    private func loadStats() async {
        isLoading = true
        
        do {
            let supabase = SupabaseManager.shared
            async let djCount = supabase.getTotalDJCount()
            async let bookingCount = supabase.getTotalBookings()
            
            totalDJs = try await djCount
            totalBookings = try await bookingCount
        } catch {
            print("Error loading stats: \(error)")
        }
        
        isLoading = false
    }
}



// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(QROWDTheme.cardGradient)
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(QROWDTheme.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(QROWDTheme.bodyFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text(description)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                    .lineLimit(nil)
            }
            
            Spacer()
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
}

// MARK: - Quick Action Button
struct AIQuickActionButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(QROWDTheme.bodyFont)
                    .foregroundColor(QROWDTheme.primaryText)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(QROWDTheme.accentColor)
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
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Views with AI Buttons
struct HostSearchViewWithAI: View {
    @State private var showingAIAssistant = false
    
    var body: some View {
        ZStack {
            // Original HostSearchView content
            HostSearchView()
            
            // Floating AI Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingAIAssistant = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(QROWDTheme.buttonGradient)
                                .frame(width: 56, height: 56)
                                .shadow(
                                    color: QROWDTheme.buttonGlow,
                                    radius: 12,
                                    x: 0,
                                    y: 4
                                )
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showingAIAssistant) {
            QROWDAIAssistantView()
        }
    }
}

struct DJDashboardViewWithAI: View {
    @State private var showingAIAssistant = false
    
    var body: some View {
        ZStack {
            // Original DJDashboardView content
            DJDashboardView()
            
            // Floating AI Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingAIAssistant = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(QROWDTheme.buttonGradient)
                                .frame(width: 56, height: 56)
                                .shadow(
                                    color: QROWDTheme.buttonGlow,
                                    radius: 12,
                                    x: 0,
                                    y: 4
                                )
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showingAIAssistant) {
            QROWDAIAssistantView()
        }
    }
}

#Preview {
            AILaunchView()
} 