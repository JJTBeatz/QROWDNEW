import SwiftUI
import PhotosUI

struct DJProfileTabView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @State private var djProfile: DJProfileDetail?
    @State private var isLoading = true
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingPROUpgrade = false
    
    var body: some View {
        ZStack {
            // Clean background
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            if isLoading {
                LoadingProfileView()
            } else if let profileDetail = djProfile {
                let profile = convertToProfile(profileDetail)
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        DJProfileHeader(profile: profile)
                        
                        // Quick Stats
                        DJQuickStats(profile: profile)
                        
                        // Main Content Sections
                        VStack(spacing: 20) {
                            DJBioSection(profile: profile)
                            DJGenresSection(profile: profile)
                            DJEquipmentSection(profile: profile)
                            DJAvailabilitySection(profile: profile)
                            DJSocialLinksSection(profile: profile)
                        }
                        
                        // Action Buttons
                        DJProfileActions(
                            onEditProfile: { showingEditProfile = true },
                            onPROUpgrade: { showingPROUpgrade = true },
                            onSettings: { showingSettings = true }
                        )
                        
                        // Bottom padding
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            } else {
                EmptyProfileView()
            }
        }
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(QROWDTheme.primaryText)
                        .imageScale(.medium)
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            if let profileDetail = djProfile {
                EditDJProfileView(profile: convertToProfile(profileDetail))
            }
        }
        .sheet(isPresented: $showingPROUpgrade) {
            DJPROUpgradeView()
        }
        .sheet(isPresented: $showingSettings) {
            if let profileDetail = djProfile {
                DJSettingsView(profile: convertToProfile(profileDetail))
            } else {
                // Show loading or error state
                VStack {
                    ProgressView()
                    Text("Loading profile...")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
                .padding()
            }
        }
        .task {
            await loadDJProfile()
        }
        .refreshable {
            await loadDJProfile()
        }
    }
    
    private func loadDJProfile() async {
        guard supabase.currentUser?.id.uuidString != nil else { return }
        
        isLoading = true
        
        do {
            djProfile = try await supabase.getCurrentUserDJProfile()
        } catch {
            print("Failed to load DJ profile: \(error)")
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    private func convertToProfile(_ detail: DJProfileDetail) -> DJProfile {
        return DJProfile(
            id: detail.id,
            userId: supabase.currentUser?.id.uuidString ?? "",
            stageName: detail.stageName,
            city: detail.city,
            genres: detail.genres,
            budgetMin: extractBudgetMin(from: detail.priceRange),
            budgetMax: extractBudgetMax(from: detail.priceRange),
            equipment: detail.equipment,
            availability: detail.availability,
            instagramHandle: detail.instagramHandle.isEmpty ? nil : detail.instagramHandle,
            soundcloudUrl: detail.soundcloudURL.isEmpty ? nil : detail.soundcloudURL,
            stripeAccountId: nil,
            audioPromoUrl: detail.promoMediaURLs.first,
            videoPromoUrl: nil,
            bio: nil,
            profileImageUrl: nil,
            rating: detail.rating,
            isPro: detail.isPro
        )
    }
    
    private func extractBudgetMin(from priceRange: String) -> Double {
        let components = priceRange.components(separatedBy: " - ")
        if let firstComponent = components.first,
           let minValue = Double(firstComponent.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) {
            return minValue
        }
        return 100.0
    }
    
    private func extractBudgetMax(from priceRange: String) -> Double {
        let components = priceRange.components(separatedBy: " - ")
        if components.count > 1,
           let maxValue = Double(components[1].replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) {
            return maxValue
        }
        return 500.0
    }
}

// MARK: - Profile Header
struct DJProfileHeader: View {
    let profile: DJProfile
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Image & Basic Info
            HStack(spacing: 20) {
                // Profile Picture
                ProfileImageView(imageUrl: profile.profileImageUrl, stageName: profile.stageName)
                
                // Basic Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(profile.stageName)
                            .font(.title2.bold())
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        if profile.isPro {
                            PROBadge()
                        }
                    }
                    
                    Text(profile.city)
                        .font(.subheadline)
                        .foregroundColor(QROWDTheme.secondaryText)
                    
                    RatingView(rating: profile.rating)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(QROWDTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(QROWDTheme.borderColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Profile Image
struct ProfileImageView: View {
    let imageUrl: String?
    let stageName: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(QROWDTheme.buttonGradient)
                .frame(width: 80, height: 80)
            
            if let imageUrl = imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Text(stageName.prefix(2).uppercased())
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            } else {
                Text(stageName.prefix(2).uppercased())
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
        }
        .overlay(
            Circle()
                .stroke(QROWDTheme.accentColor.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - PRO Badge
struct PROBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.caption2)
            Text("PRO")
                .font(.caption.bold())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}

// MARK: - Rating View
struct RatingView: View {
    let rating: Double
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                    .foregroundColor(star <= Int(rating) ? .yellow : QROWDTheme.secondaryText)
                    .font(.caption)
            }
            
            Text(String(format: "%.1f", rating))
                .font(.caption)
                .foregroundColor(QROWDTheme.secondaryText)
        }
    }
}

// MARK: - Quick Stats
struct DJQuickStats: View {
    let profile: DJProfile
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(title: "Budget Range", value: "$\(Int(profile.budgetMin))-\(Int(profile.budgetMax))")
            
            Divider()
                .frame(height: 30)
            
            StatItem(title: "Equipment", value: "\(profile.equipment.count) items")
            
            Divider()
                .frame(height: 30)
            
            StatItem(title: "Genres", value: "\(profile.genres.count)")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(QROWDTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(QROWDTheme.borderColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.bold())
                .foregroundColor(QROWDTheme.accentColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(QROWDTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Bio Section
struct DJBioSection: View {
    let profile: DJProfile
    
    var body: some View {
        if let bio = profile.bio, !bio.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                ProfileSectionHeader(title: "About", icon: "person.text.rectangle")
                
                Text(bio)
                    .font(.body)
                    .foregroundColor(QROWDTheme.primaryText)
                    .lineLimit(nil)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(QROWDTheme.cardGradient.opacity(0.5))
                    )
            }
        }
    }
}

// MARK: - Genres Section
struct DJGenresSection: View {
    let profile: DJProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                            ProfileSectionHeader(title: "Genres", icon: "music.note")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(profile.genres, id: \.self) { genre in
                    GenreTag(genre: genre)
                }
            }
        }
    }
}

struct GenreTag: View {
    let genre: String
    
    var body: some View {
        Text(genre)
            .font(.caption.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(QROWDTheme.buttonGradient)
            )
    }
}

// MARK: - Equipment Section
struct DJEquipmentSection: View {
    let profile: DJProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                            ProfileSectionHeader(title: "Equipment", icon: "hifispeaker.2")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(profile.equipment, id: \.self) { equipment in
                    EquipmentItem(equipment: equipment)
                }
            }
        }
    }
}

struct EquipmentItem: View {
    let equipment: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            
            Text(equipment)
                .font(.caption)
                .foregroundColor(QROWDTheme.primaryText)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(QROWDTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(QROWDTheme.borderColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Availability Section
struct DJAvailabilitySection: View {
    let profile: DJProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                            ProfileSectionHeader(title: "Availability", icon: "calendar")
            
            if !profile.availability.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(profile.availability.keys).sorted(), id: \.self) { day in
                        if let timeSlots = profile.availability[day], !timeSlots.isEmpty {
                            ProfileAvailabilityRow(day: day, timeSlots: timeSlots)
                        }
                    }
                }
            } else {
                Text("No availability set")
                    .font(.body)
                    .foregroundColor(QROWDTheme.secondaryText)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(QROWDTheme.cardGradient.opacity(0.3))
                    )
            }
        }
    }
}

struct ProfileAvailabilityRow: View {
    let day: String
    let timeSlots: [String]
    
    var body: some View {
        HStack {
            Text(day)
                .font(.subheadline.weight(.medium))
                .foregroundColor(QROWDTheme.primaryText)
                .frame(width: 80, alignment: .leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(timeSlots, id: \.self) { slot in
                        Text(slot)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(QROWDTheme.accentColor)
                            )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(QROWDTheme.cardGradient)
        )
    }
}

// MARK: - Social Links Section
struct DJSocialLinksSection: View {
    let profile: DJProfile
    
    var body: some View {
        if hasAnySocialLinks {
            VStack(alignment: .leading, spacing: 12) {
                ProfileSectionHeader(title: "Social Links", icon: "link")
                
                VStack(spacing: 8) {
                    if let instagram = profile.instagramHandle, !instagram.isEmpty {
                        SocialLinkItem(platform: "Instagram", handle: "@\(instagram)", icon: "camera", color: .pink)
                    }
                    
                    if let soundcloud = profile.soundcloudUrl, !soundcloud.isEmpty {
                        SocialLinkItem(platform: "SoundCloud", handle: soundcloud, icon: "music.note", color: .orange)
                    }
                }
            }
        }
    }
    
    private var hasAnySocialLinks: Bool {
        (profile.instagramHandle != nil && !profile.instagramHandle!.isEmpty) ||
        (profile.soundcloudUrl != nil && !profile.soundcloudUrl!.isEmpty)
    }
}

struct SocialLinkItem: View {
    let platform: String
    let handle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(platform)
                    .font(.caption.weight(.medium))
                    .foregroundColor(QROWDTheme.secondaryText)
                
                Text(handle)
                    .font(.subheadline)
                    .foregroundColor(QROWDTheme.primaryText)
            }
            
            Spacer()
            
            Image(systemName: "arrow.up.right")
                .foregroundColor(QROWDTheme.secondaryText)
                .font(.caption)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(QROWDTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Section Header
struct ProfileSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(QROWDTheme.accentColor)
                .font(.headline)
            
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(QROWDTheme.primaryText)
            
            Spacer()
        }
    }
}

// MARK: - Profile Actions
struct DJProfileActions: View {
    let onEditProfile: () -> Void
    let onPROUpgrade: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ActionButton(title: "Edit Profile", icon: "pencil", color: QROWDTheme.accentColor, action: onEditProfile)
                ActionButton(title: "Upgrade PRO", icon: "crown.fill", color: .orange, action: onPROUpgrade)
            }
            
            ActionButton(title: "Settings", icon: "gearshape", color: QROWDTheme.secondaryText, action: onSettings)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                
                Text(title)
                    .font(.headline.weight(.medium))
            }
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
    }
}

// MARK: - Loading & Empty States
struct LoadingProfileView: View {
    var body: some View {
        VStack(spacing: 20) {
            QROWDLogo.loading
            Text("Loading your profile...")
                .font(.subheadline)
                .foregroundColor(QROWDTheme.secondaryText)
        }
    }
}

struct EmptyProfileView: View {
    var body: some View {
        VStack(spacing: 20) {
            QROWDLogo.medium
            
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(QROWDTheme.secondaryText)
            
            Text("Profile not found")
                .font(.headline)
                .foregroundColor(QROWDTheme.primaryText)
            
            Text("Please complete your DJ registration")
                .font(.subheadline)
                .foregroundColor(QROWDTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Edit Profile Placeholder
struct EditDJProfileView: View {
    let profile: DJProfile?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Edit DJ Profile")
                    .font(.title)
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text("Profile editing coming soon!")
                    .font(.subheadline)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        DJProfileTabView()
    }
} 
