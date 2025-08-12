import SwiftUI

struct HostRegistrationWizardView: View {
    @StateObject private var viewModel = HostRegistrationViewModel()
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated Background
                AnimatedGradientBackground()
                
                VStack(spacing: 0) {
                    // Enhanced Progress Bar
                    VStack(spacing: 12) {
                        HStack {
                            Text("Step \(viewModel.currentStep) of 4")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                                .bounceOnAppear()
                            
                            Spacer()
                            
                            Text("\(Int(viewModel.progressPercentage * 100))%")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.accentColor)
                                .fadeInUp(delay: 0.2)
                        }
                        
                        ProgressBarView(
                            currentStep: viewModel.currentStep,
                            totalSteps: 4,
                            progress: viewModel.progressPercentage
                        )
                        .slideInFromLeft(delay: 0.1)
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    .padding(.top, 20)
                    
                    // Step Content
                    TabView(selection: $viewModel.currentStep) {
                        // Step 1: Basic Info
                        HostBasicInfoView(viewModel: viewModel)
                            .tag(1)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                        // Step 2: Event Preferences
                        HostEventPreferencesView(viewModel: viewModel)
                            .tag(2)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                        // Step 3: Budget & Event Types
                        HostBudgetEventTypesView(viewModel: viewModel)
                            .tag(3)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                        // Step 4: Social & Contact
                        HostSocialContactView(viewModel: viewModel)
                            .tag(4)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(QROWDAnimations.smooth, value: viewModel.currentStep)
                    
                    // Navigation Buttons
                    HStack(spacing: 16) {
                        // Back Button
                        if viewModel.currentStep > 1 {
                            QROWDSecondaryButton(
                                title: "Back", 
                                isEnabled: !viewModel.isLoading
                            ) {
                                viewModel.previousStep()
                            }
                            .slideInFromLeft(delay: 0.1)
                        }
                        
                        Spacer()
                        
                        // Next/Complete Button
                        QROWDButton(
                            title: viewModel.currentStep == 4 ? "🎉 Complete Setup" : "Next Step",
                            isLoading: viewModel.isLoading,
                            isEnabled: viewModel.canProceedToNextStep
                        ) {
                            Task {
                                if viewModel.currentStep == 4 {
                                    await viewModel.createHostProfile()
                                    onComplete()
                                    dismiss()
                                } else {
                                    viewModel.nextStep()
                                }
                            }
                        }
                        .slideInFromRight(delay: 0.1)
                    }
                    .padding(QROWDTheme.cardPadding)
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
                
                ToolbarItem(placement: .principal) {
                    Text("Host Profile Setup")
                        .font(QROWDTheme.headlineFont)
                        .foregroundColor(QROWDTheme.primaryText)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Step 1: Basic Info
struct HostBasicInfoView: View {
    @ObservedObject var viewModel: HostRegistrationViewModel
    
    var body: some View {
        ZStack {
            QROWDTheme.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: QROWDTheme.sectionSpacing) {
                    
                    // Header
                    VStack(spacing: 12) {
                        Text("Tell us about yourself!")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Help DJs understand who they'll be working with")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        HStack(spacing: 12) {
                            QROWDTextField(
                                text: $viewModel.registrationData.firstName,
                                placeholder: "First Name",
                                icon: "person"
                            )
                            
                            QROWDTextField(
                                text: $viewModel.registrationData.lastName,
                                placeholder: "Last Name",
                                icon: "person.fill"
                            )
                        }
                        
                        QROWDTextField(
                            text: $viewModel.registrationData.companyName,
                            placeholder: "Company/Organization (Optional)",
                            icon: "building.2"
                        )
                        
                        QROWDTextField(
                            text: $viewModel.registrationData.city,
                            placeholder: "City",
                            icon: "location"
                        )
                        
                        QROWDTextField(
                            text: $viewModel.registrationData.phoneNumber,
                            placeholder: "Phone Number (Optional)",
                            icon: "phone"
                        )
                        .keyboardType(.phonePad)
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    Spacer(minLength: 40)
                }
            }
        }
    }
}

// MARK: - Step 2: Event Preferences
struct HostEventPreferencesView: View {
    @ObservedObject var viewModel: HostRegistrationViewModel
    
    var body: some View {
        ZStack {
            QROWDTheme.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: QROWDTheme.sectionSpacing) {
                    
                    // Header
                    VStack(spacing: 12) {
                        Text("What's your vibe?")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Select your preferred music genres")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Genre Selection
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(viewModel.availableGenres, id: \.self) { genre in
                            GenreSelectionButton(
                                genre: genre,
                                isSelected: viewModel.isGenreSelected(genre)
                            ) {
                                viewModel.toggleGenre(genre)
                            }
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    Spacer(minLength: 40)
                }
            }
        }
    }
}

// MARK: - Step 3: Budget & Event Types
struct HostBudgetEventTypesView: View {
    @ObservedObject var viewModel: HostRegistrationViewModel
    
    var body: some View {
        ZStack {
            QROWDTheme.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: QROWDTheme.sectionSpacing) {
                    
                    // Header
                    VStack(spacing: 12) {
                        Text("Event Planning")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Tell us about your typical events")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Budget Range
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Typical Budget Range")
                            .font(QROWDTheme.headlineFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        ForEach(RegistrationOptions.budgetRanges, id: \.self) { budget in
                            BudgetSelectionButton(
                                budget: budget,
                                isSelected: viewModel.registrationData.typicalBudgetRange == budget
                            ) {
                                viewModel.registrationData.typicalBudgetRange = budget
                            }
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Event Types
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Event Types You Host")
                            .font(QROWDTheme.headlineFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(RegistrationOptions.eventTypes, id: \.self) { eventType in
                                EventTypeSelectionButton(
                                    eventType: eventType,
                                    isSelected: viewModel.isEventTypeSelected(eventType)
                                ) {
                                    viewModel.toggleEventType(eventType)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    Spacer(minLength: 40)
                }
            }
        }
    }
}

// MARK: - Step 4: Social & Contact
struct HostSocialContactView: View {
    @ObservedObject var viewModel: HostRegistrationViewModel
    
    var body: some View {
        ZStack {
            QROWDTheme.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: QROWDTheme.sectionSpacing) {
                    
                    // Header
                    VStack(spacing: 12) {
                        Text("Connect & Showcase")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Add your social links (optional)")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Social Links
                    VStack(spacing: 20) {
                        QROWDTextField(
                            text: $viewModel.registrationData.instagramHandle,
                            placeholder: "Instagram Handle",
                            icon: "camera"
                        )
                        
                        QROWDTextField(
                            text: $viewModel.registrationData.websiteUrl,
                            placeholder: "Website URL",
                            icon: "globe"
                        )
                        .keyboardType(.URL)
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    Spacer(minLength: 40)
                }
            }
        }
    }
}

// MARK: - Helper Components
struct GenreSelectionButton: View {
    let genre: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(genre)
                .font(QROWDTheme.bodyFont)
                .foregroundColor(isSelected ? .white : QROWDTheme.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                        .fill(isSelected ? QROWDTheme.buttonGradient : QROWDTheme.cardGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                                .stroke(isSelected ? QROWDTheme.accentColor : QROWDTheme.borderColor, lineWidth: 1)
                        )
                )
        }
    }
}

struct BudgetSelectionButton: View {
    let budget: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(budget)
                    .font(QROWDTheme.bodyFont)
                    .foregroundColor(QROWDTheme.primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(QROWDTheme.accentColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(QROWDTheme.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                            .stroke(isSelected ? QROWDTheme.accentColor : QROWDTheme.borderColor, lineWidth: 1)
                    )
            )
        }
    }
}

struct EventTypeSelectionButton: View {
    let eventType: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(eventType)
                .font(QROWDTheme.captionFont)
                .foregroundColor(isSelected ? .white : QROWDTheme.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? QROWDTheme.buttonGradient : QROWDTheme.cardGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? QROWDTheme.accentColor : QROWDTheme.borderColor, lineWidth: 1)
                        )
                )
        }
    }
}

#Preview {
    HostRegistrationWizardView(onComplete: {})
} 