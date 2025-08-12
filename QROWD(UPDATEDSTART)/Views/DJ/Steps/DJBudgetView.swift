import SwiftUI

struct DJBudgetView: View {
    @ObservedObject var viewModel: DJRegistrationViewModel
    
    let minBudget: Double = 50
    let maxBudget: Double = 5000
    
    var body: some View {
        ZStack {
            // Background
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: QROWDTheme.sectionSpacing) {
                    
                    // Header
                    VStack(spacing: 12) {
                        Text("Set Your Rates")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("What's your price range for events?")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Budget Display
                    VStack(spacing: 16) {
                        HStack {
                            VStack(spacing: 4) {
                                Text("Minimum")
                                    .font(QROWDTheme.captionFont)
                                    .foregroundColor(QROWDTheme.secondaryText)
                                
                                Text("$\(Int(viewModel.budgetMin))")
                                    .font(QROWDTheme.titleFont)
                                    .foregroundColor(QROWDTheme.accentColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                                    .fill(QROWDTheme.cardGradient)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                                            .stroke(QROWDTheme.borderColor, lineWidth: 1)
                                    )
                                )
                                
                            Text("to")
                                .font(QROWDTheme.bodyFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 4) {
                                Text("Maximum")
                                    .font(QROWDTheme.captionFont)
                                    .foregroundColor(QROWDTheme.secondaryText)
                                
                                Text("$\(Int(viewModel.budgetMax))")
                                    .font(QROWDTheme.titleFont)
                                    .foregroundColor(QROWDTheme.accentColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(20)
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
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Sliders
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Minimum Rate")
                                    .font(QROWDTheme.bodyFont.weight(.semibold))
                                    .foregroundColor(QROWDTheme.primaryText)
                                
                                Spacer()
                                
                                Text("$\(Int(viewModel.budgetMin))")
                                    .font(QROWDTheme.bodyFont.weight(.semibold))
                                    .foregroundColor(QROWDTheme.accentColor)
                            }
                            
                            Slider(
                                value: $viewModel.budgetMin,
                                in: minBudget...min(viewModel.budgetMax - 50, maxBudget - 100),
                                step: 25
                            ) { _ in
                                // Ensure min is always less than max
                                if viewModel.budgetMin >= viewModel.budgetMax {
                                    viewModel.budgetMax = viewModel.budgetMin + 50
                                }
                            }
                            .accentColor(QROWDTheme.accentColor)
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Maximum Rate")
                                    .font(QROWDTheme.bodyFont.weight(.semibold))
                                    .foregroundColor(QROWDTheme.primaryText)
                                
                                Spacer()
                                
                                Text("$\(Int(viewModel.budgetMax))")
                                    .font(QROWDTheme.bodyFont.weight(.semibold))
                                    .foregroundColor(QROWDTheme.accentColor)
                            }
                            
                            Slider(
                                value: $viewModel.budgetMax,
                                in: max(viewModel.budgetMin + 50, minBudget + 100)...maxBudget,
                                step: 25
                            ) { _ in
                                // Ensure max is always greater than min
                                if viewModel.budgetMax <= viewModel.budgetMin {
                                    viewModel.budgetMin = viewModel.budgetMax - 50
                                }
                            }
                            .accentColor(QROWDTheme.accentColor)
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Quick Select Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Select")
                            .font(QROWDTheme.headlineFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            QuickSelectButton(
                                title: "Beginner",
                                range: "$50 - $200",
                                isSelected: viewModel.budgetMin == 50 && viewModel.budgetMax == 200
                            ) {
                                withAnimation {
                                    viewModel.budgetMin = 50
                                    viewModel.budgetMax = 200
                                }
                            }
                            
                            QuickSelectButton(
                                title: "Intermediate",
                                range: "$200 - $500",
                                isSelected: viewModel.budgetMin == 200 && viewModel.budgetMax == 500
                            ) {
                                withAnimation {
                                    viewModel.budgetMin = 200
                                    viewModel.budgetMax = 500
                                }
                            }
                            
                            QuickSelectButton(
                                title: "Professional",
                                range: "$500 - $1500",
                                isSelected: viewModel.budgetMin == 500 && viewModel.budgetMax == 1500
                            ) {
                                withAnimation {
                                    viewModel.budgetMin = 500
                                    viewModel.budgetMax = 1500
                                }
                            }
                            
                            QuickSelectButton(
                                title: "Premium",
                                range: "$1500+",
                                isSelected: viewModel.budgetMin == 1500 && viewModel.budgetMax == 5000
                            ) {
                                withAnimation {
                                    viewModel.budgetMin = 1500
                                    viewModel.budgetMax = 5000
                                }
                            }
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Info Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(QROWDTheme.accentColor)
                            
                            Text("Pricing Tips")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(text: "Consider your experience level and local market rates")
                            TipRow(text: "You can adjust rates based on event type and duration")
                            TipRow(text: "Higher rates often attract more serious clients")
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
                    
                    Spacer(minLength: 100)
                }
            }
        }
    }
}

struct QuickSelectButton: View {
    let title: String
    let range: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(QROWDTheme.bodyFont.weight(.semibold))
                    .foregroundColor(isSelected ? .white : QROWDTheme.primaryText)
                
                Text(range)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : QROWDTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(isSelected ? QROWDTheme.buttonGradient : QROWDTheme.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                            .stroke(isSelected ? Color.clear : QROWDTheme.borderColor, lineWidth: 1)
                    )
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    DJBudgetView(viewModel: DJRegistrationViewModel())
} 