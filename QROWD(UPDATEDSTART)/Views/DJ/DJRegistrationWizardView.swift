import SwiftUI

struct DJRegistrationWizardView: View {
    @StateObject private var viewModel = DJRegistrationViewModel()
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated Background
                AnimatedGradientBackground()
                
                VStack(spacing: 0) {
                    // Enhanced Progress Bar with animation
                    VStack(spacing: 12) {
                        HStack {
                            Text("Step \(viewModel.currentStep) of 8")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                                .bounceOnAppear()
                            
                            Spacer()
                            
                            Text("\(Int((Double(viewModel.currentStep) / 8.0) * 100))%")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.accentColor)
                                .fadeInUp(delay: 0.2)
                        }
                        
                        ProgressBarView(
                            currentStep: viewModel.currentStep,
                            totalSteps: 8,
                            progress: Double(viewModel.currentStep) / 8.0
                        )
                        .slideInFromLeft(delay: 0.1)
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    .padding(.top, 20)
                    
                    // Enhanced Step Content with slide transitions
                    TabView(selection: $viewModel.currentStep) {
                        // Step 1: DJ/Stage Name + City
                        DJBasicInfoView(viewModel: viewModel)
                            .tag(1)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                        // Step 2: Budget Range
                        DJBudgetView(viewModel: viewModel)
                            .tag(2)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                        // Step 3: Genre + Culture
                        DJGenreView(viewModel: viewModel)
                            .tag(3)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                        // Step 4: Equipment
                        DJEquipmentView(viewModel: viewModel)
                            .tag(4)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                        // Step 5: Promo Upload
                        DJPromoView(viewModel: viewModel)
                            .tag(5)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                        // Step 6: Availability
                        DJAvailabilityView(viewModel: viewModel)
                            .tag(6)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                        // Step 7: Social Links
                        DJSocialLinksView(viewModel: viewModel)
                            .tag(7)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                        // Step 8: Stripe Connect
                        DJStripeView(viewModel: viewModel)
                            .tag(8)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(QROWDAnimations.smooth, value: viewModel.currentStep)
                    
                    // Enhanced Navigation Buttons
                    HStack(spacing: 16) {
                        // Animated Back Button
                        if viewModel.currentStep > 1 {
                            QROWDSecondaryButton(
                                title: "Back", 
                                isEnabled: !viewModel.isLoading
                            ) {
                                withAnimation(QROWDAnimations.smooth) {
                                    viewModel.currentStep -= 1
                                }
                            }
                            .slideInFromLeft(delay: 0.1)
                        }
                        
                        Spacer()
                        
                        // Enhanced Next/Complete Button
                        QROWDButton(
                            title: viewModel.currentStep == 8 ? "🎉 Complete Setup" : "Next Step",
                            isLoading: viewModel.isLoading,
                            isEnabled: viewModel.isCurrentStepValid
                        ) {
                            Task {
                                await viewModel.handleNextStep()
                                if viewModel.isComplete {
                                    onComplete()
                                    dismiss()
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
                    Text("DJ Profile Setup")
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

// Components are now in QROWDComponents.swift

#Preview {
    DJRegistrationWizardView(onComplete: {})
} 