import SwiftUI

struct GuestRegistrationView: View {
    @StateObject private var viewModel = GuestRegistrationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                QROWDTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: QROWDTheme.sectionSpacing) {
                        // Header
                        headerView
                        
                        // Form Content
                        profileFormView
                        
                        // Skip Option
                        skipOptionView
                        
                        Spacer(minLength: 120) // Space for buttons
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                }
                
                // Bottom Buttons
                VStack {
                    Spacer()
                    bottomButtons
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(QROWDTheme.primaryText)
                }
            }
        }
        .alert("Registration Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "person.circle")
                .font(.system(size: 60))
                .foregroundColor(QROWDTheme.accentColor)
            
            // Title
            Text("Welcome to QROWD")
                .font(QROWDTheme.titleFont)
                .foregroundColor(QROWDTheme.primaryText)
                .multilineTextAlignment(.center)
            
            Text("Set up your profile to get personalized event recommendations, or skip to start browsing immediately")
                .font(QROWDTheme.bodyFont)
                .foregroundColor(QROWDTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
    
    // MARK: - Profile Form
    private var profileFormView: some View {
        VStack(spacing: 20) {
            // Name Fields
            HStack(spacing: 12) {
                QROWDTextField(
                    text: $viewModel.registrationData.firstName,
                    placeholder: "First Name (Optional)",
                    icon: "person"
                )
                
                QROWDTextField(
                    text: $viewModel.registrationData.lastName,
                    placeholder: "Last Name (Optional)",
                    icon: "person.fill"
                )
            }
            
            // City
            QROWDTextField(
                text: $viewModel.registrationData.city,
                placeholder: "City (Optional)",
                icon: "location"
            )
            
            // Instagram
            QROWDTextField(
                text: $viewModel.registrationData.instagramHandle,
                placeholder: "Instagram handle (Optional)",
                icon: "camera"
            )
            .textContentType(.none)
            .autocapitalization(.none)
            
            // Music Preferences
            if !viewModel.registrationData.preferredGenres.isEmpty || !viewModel.registrationData.firstName.isEmpty {
                genrePreferencesView
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Genre Preferences
    private var genrePreferencesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Music Preferences")
                    .font(QROWDTheme.headlineFont)
                    .foregroundColor(QROWDTheme.primaryText)
                
                Spacer()
                
                Text("(Optional)")
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(viewModel.availableGenres.prefix(10), id: \.self) { genre in
                    SelectableTag(
                        text: genre,
                        isSelected: viewModel.isGenreSelected(genre)
                    ) {
                        viewModel.toggleGenre(genre)
                    }
                }
            }
            
            if viewModel.registrationData.preferredGenres.count > 0 {
                Button("Show More Genres") {
                    // Could expand to show all genres
                }
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.accentColor)
            }
        }
    }
    
    // MARK: - Skip Option
    private var skipOptionView: some View {
        VStack(spacing: 16) {
            // Divider
            HStack {
                Rectangle()
                    .fill(QROWDTheme.borderColor)
                    .frame(height: 1)
                
                Text("OR")
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(QROWDTheme.borderColor)
                    .frame(height: 1)
            }
            
            // Skip Info
            VStack(spacing: 8) {
                Text("Want to browse events right away?")
                    .font(QROWDTheme.bodyFont)
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text("You can always add your profile information later in settings")
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Bottom Buttons
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // Create Profile Button (if has data)
            if viewModel.hasAnyData {
                QROWDButton(
                    title: "Create Profile",
                    isLoading: viewModel.isLoading,
                    isEnabled: !viewModel.isLoading
                ) {
                    Task {
                        await viewModel.createGuestProfile()
                        if !viewModel.showingError {
                            onComplete()
                        }
                    }
                }
            }
            
            // Skip Button
            QROWDSecondaryButton(
                title: viewModel.hasAnyData ? "Skip for Now" : "Start Browsing",
                isEnabled: !viewModel.isLoading
            ) {
                Task {
                    await viewModel.skipProfileCreation()
                    if !viewModel.showingError {
                        onComplete()
                    }
                }
            }
        }
        .padding(.horizontal, QROWDTheme.cardPadding)
        .padding(.bottom, 40)
    }
}

// MARK: - Preview
struct GuestRegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        GuestRegistrationView {
            print("Guest registration completed")
        }
        .preferredColorScheme(.dark)
    }
} 