import SwiftUI
import AVKit

struct DJProfileView: View {
    let djId: String
    @StateObject private var viewModel = DJProfileViewModel()
    @State private var showingBooking = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                QROWDTheme.backgroundColor
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    VStack(spacing: 24) {
                        QROWDLogo.loading
                        
                        Text("Loading Profile...")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                    }
                } else if let profile = viewModel.djProfile {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Banner Image
                            AsyncImage(url: URL(string: profile.promoMediaURLs.first ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(QROWDTheme.primaryGradient)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "music.note.house")
                                                .font(.system(size: 60))
                                                .foregroundColor(.white.opacity(0.8))
                                            
                                            Text(profile.stageName)
                                                .font(QROWDTheme.titleFont)
                                                .foregroundColor(.white)
                                        }
                                    )
                            }
                            .frame(height: 250)
                            .clipped()
                            
                            // Profile Content
                            VStack(spacing: QROWDTheme.sectionSpacing) {
                                
                                // Header Info
                                VStack(spacing: 16) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(spacing: 12) {
                                                Text(profile.stageName)
                                                    .font(QROWDTheme.titleFont)
                                                    .foregroundColor(QROWDTheme.primaryText)
                                                
                                                if profile.isPro {
                                PROBadgeView(size: .medium)
                            }
                                            }
                                            
                                            HStack(spacing: 8) {
                                                Image(systemName: "location.fill")
                                                    .foregroundColor(QROWDTheme.accentColor)
                                                
                                                Text(profile.city)
                                                    .font(QROWDTheme.bodyFont)
                                                    .foregroundColor(QROWDTheme.secondaryText)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 8) {
                                            HStack(spacing: 6) {
                                                ForEach(0..<5) { star in
                                                    Image(systemName: star < Int(profile.rating) ? "star.fill" : "star")
                                                        .foregroundColor(.yellow)
                                                        .font(.caption)
                                                }
                                                
                                                Text(String(format: "%.1f", profile.rating))
                                                    .font(QROWDTheme.captionFont.weight(.semibold))
                                                    .foregroundColor(QROWDTheme.primaryText)
                                            }
                                            
                                            Text("\(profile.totalBookings) bookings")
                                                .font(QROWDTheme.captionFont)
                                                .foregroundColor(QROWDTheme.secondaryText)
                                        }
                                    }
                                    
                                    // Price Range
                                    HStack {
                                        Text("Price Range:")
                                            .font(QROWDTheme.bodyFont)
                                            .foregroundColor(QROWDTheme.secondaryText)
                                        
                                        Spacer()
                                        
                                        Text(profile.priceRange)
                                            .font(QROWDTheme.headlineFont)
                                            .foregroundColor(QROWDTheme.accentColor)
                                    }
                                }
                                .padding(.horizontal, QROWDTheme.cardPadding)
                                
                                // Request Booking Button (moved up)
                                QROWDButton(
                                    title: "Request Booking",
                                    isLoading: false,
                                    isEnabled: true
                                ) {
                                    showingBooking = true
                                }
                                .padding(.horizontal, QROWDTheme.cardPadding)
                                
                                // Genres & Cultures
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Music Styles")
                                        .font(QROWDTheme.headlineFont)
                                        .foregroundColor(QROWDTheme.primaryText)
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        if !profile.genres.isEmpty {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Genres")
                                                    .font(QROWDTheme.bodyFont.weight(.semibold))
                                                    .foregroundColor(QROWDTheme.primaryText)
                                                
                                                LazyVGrid(columns: [
                                                    GridItem(.adaptive(minimum: 80), spacing: 8)
                                                ], spacing: 8) {
                                                    ForEach(profile.genres, id: \.self) { genre in
                                                        StyleTag(text: genre, color: QROWDTheme.accentColor)
                                                    }
                                                }
                                            }
                                        }
                                        
                                        if !profile.cultures.isEmpty {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Cultural Specialties")
                                                    .font(QROWDTheme.bodyFont.weight(.semibold))
                                                    .foregroundColor(QROWDTheme.primaryText)
                                                
                                                LazyVGrid(columns: [
                                                    GridItem(.adaptive(minimum: 80), spacing: 8)
                                                ], spacing: 8) {
                                                    ForEach(profile.cultures, id: \.self) { culture in
                                                        StyleTag(text: culture, color: .orange)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, QROWDTheme.cardPadding)
                                
                                // Equipment
                                if !profile.equipment.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Equipment")
                                            .font(QROWDTheme.headlineFont)
                                            .foregroundColor(QROWDTheme.primaryText)
                                        
                                        LazyVGrid(columns: [
                                            GridItem(.flexible()),
                                            GridItem(.flexible())
                                        ], spacing: 12) {
                                            ForEach(profile.equipment, id: \.self) { equipment in
                                                EquipmentBadge(name: equipment)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, QROWDTheme.cardPadding)
                                }
                                
                                // Social Links
                                if !profile.instagramHandle.isEmpty || !profile.soundcloudURL.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Social Profiles")
                                            .font(QROWDTheme.headlineFont)
                                            .foregroundColor(QROWDTheme.primaryText)
                                        
                                        VStack(spacing: 12) {
                                            if !profile.instagramHandle.isEmpty {
                                                SocialLinkCard(
                                                    platform: "Instagram",
                                                    handle: "@\(profile.instagramHandle)",
                                                    icon: "camera.fill",
                                                    color: .pink
                                                )
                                            }
                                            
                                            if !profile.soundcloudURL.isEmpty {
                                                SocialLinkCard(
                                                    platform: "SoundCloud", 
                                                    handle: profile.soundcloudURL,
                                                    icon: "waveform",
                                                    color: .orange
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, QROWDTheme.cardPadding)
                                }
                                
                                Spacer(minLength: 40)
                            }
                            .padding(.top, QROWDTheme.cardPadding)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(QROWDTheme.primaryText)
                }
            }
        }
        .sheet(isPresented: $showingBooking) {
            if let profile = viewModel.djProfile {
                BookingRequestView(djProfile: profile)
            }
        }
        .task {
            await viewModel.loadProfile(djId: djId)
        }
    }
}

// MARK: - Supporting Views
struct StyleTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(QROWDTheme.captionFont)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.8))
            )
    }
}

struct EquipmentBadge: View {
    let name: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            
            Text(name)
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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

struct SocialLinkCard: View {
    let platform: String
    let handle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(platform)
                    .font(QROWDTheme.captionFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text(handle)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "arrow.up.right")
                .foregroundColor(QROWDTheme.secondaryText)
                .font(.caption)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                .fill(QROWDTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - ViewModel
@MainActor
class DJProfileViewModel: ObservableObject {
    @Published var djProfile: DJProfileDetail?
    @Published var isLoading = false
    
    private let supabase = SupabaseManager.shared
    
    func loadProfile(djId: String) async {
        isLoading = true
        
        do {
            djProfile = try await supabase.getDJProfile(djId: djId)
        } catch {
            print("Error loading DJ profile: \(error)")
        }
        
        isLoading = false
    }
}

#Preview {
    DJProfileView(djId: "sample-dj-id")
} 