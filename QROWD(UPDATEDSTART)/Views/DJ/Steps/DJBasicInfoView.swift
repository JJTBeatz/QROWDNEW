import SwiftUI

struct DJBasicInfoView: View {
    @ObservedObject var viewModel: DJRegistrationViewModel
    @State private var showingCitySuggestions = false
    
    var body: some View {
        ZStack {
            // Background
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: QROWDTheme.sectionSpacing) {
                    
                    // Header
                    VStack(spacing: 12) {
                        Text("Let's get started!")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Tell us about yourself as a DJ")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        
                        // DJ/Stage Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DJ/Stage Name")
                                .font(QROWDTheme.bodyFont.weight(.semibold))
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            QROWDTextField(
                                text: $viewModel.stageName,
                                placeholder: "e.g., DJ Phoenix, MC Storm",
                                icon: "music.note"
                            )
                            
                            Text("This is how you'll appear to potential clients")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                        }
                        
                        // City Input with Suggestions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("City")
                                .font(QROWDTheme.bodyFont.weight(.semibold))
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            ZStack {
                                QROWDTextField(
                                    text: $viewModel.city,
                                    placeholder: "Start typing your city...",
                                    icon: "location"
                                )
                                .onChange(of: viewModel.city) {
                                    showingCitySuggestions = !viewModel.city.isEmpty && !viewModel.suggestedCities.isEmpty
                                }
                                
                                // City Suggestions Dropdown
                                if showingCitySuggestions {
                                    VStack(spacing: 0) {
                                        Spacer()
                                        
                                        VStack(spacing: 0) {
                                            ForEach(viewModel.suggestedCities.prefix(5), id: \.self) { city in
                                                Button {
                                                    viewModel.city = city
                                                    showingCitySuggestions = false
                                                } label: {
                                                    HStack {
                                                        Image(systemName: "location.fill")
                                                            .foregroundColor(QROWDTheme.accentColor)
                                                            .font(.caption)
                                                        
                                                        Text(city)
                                                            .font(QROWDTheme.bodyFont)
                                                            .foregroundColor(QROWDTheme.primaryText)
                                                        
                                                        Spacer()
                                                    }
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(QROWDTheme.cardGradient)
                                                }
                                                
                                                if city != viewModel.suggestedCities.prefix(5).last {
                                                    Divider()
                                                        .background(QROWDTheme.borderColor)
                                                }
                                            }
                                        }
                                        .background(
                                            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                                                .fill(QROWDTheme.cardGradient)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                                                        .stroke(QROWDTheme.borderColor, lineWidth: 1)
                                                )
                                        )
                                        .padding(.top, 8)
                                    }
                                }
                            }
                            
                            Text("We'll help you find gigs in your area")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Tips Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(QROWDTheme.accentColor)
                            
                            Text("Pro Tips")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(text: "Use a memorable stage name that reflects your style")
                            TipRow(text: "Include your real city for accurate local bookings")
                            TipRow(text: "You can always update these details later")
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
        .onTapGesture {
            showingCitySuggestions = false
        }
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(QROWDTheme.accentColor)
                .font(.caption)
                .padding(.top, 2)
            
            Text(text)
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

#Preview {
    DJBasicInfoView(viewModel: DJRegistrationViewModel())
} 