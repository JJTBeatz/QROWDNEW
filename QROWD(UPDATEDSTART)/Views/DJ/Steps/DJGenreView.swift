import SwiftUI

struct DJGenreView: View {
    @ObservedObject var viewModel: DJRegistrationViewModel
    @State private var searchText = ""
    
    var filteredGenres: [String] {
        if searchText.isEmpty {
            return viewModel.availableGenres
        } else {
            return viewModel.availableGenres.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var filteredCultures: [String] {
        if searchText.isEmpty {
            return viewModel.availableCultures
        } else {
            return viewModel.availableCultures.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: QROWDTheme.sectionSpacing) {
                    
                    // Header
                    VStack(spacing: 12) {
                        Text("Your Music Style")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Select the genres and cultures you specialize in")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, QROWDTheme.cardPadding)
                    }
                    .padding(.top, 40)
                    
                    // Search Bar
                    QROWDTextField(
                        text: $searchText,
                        placeholder: "Search genres or cultures...",
                        icon: "magnifyingglass"
                    )
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Genres Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Genres")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            Spacer()
                            
                            Text("\(viewModel.selectedGenres.count) selected")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.accentColor)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 100), spacing: 8)
                        ], spacing: 8) {
                            ForEach(filteredGenres, id: \.self) { genre in
                                SelectableTag(
                                    text: genre,
                                    isSelected: viewModel.selectedGenres.contains(genre)
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if viewModel.selectedGenres.contains(genre) {
                                            viewModel.selectedGenres.remove(genre)
                                        } else {
                                            viewModel.selectedGenres.insert(genre)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Cultures Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Cultures")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            Spacer()
                            
                            Text("\(viewModel.selectedCultures.count) selected")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.accentColor)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 100), spacing: 8)
                        ], spacing: 8) {
                            ForEach(filteredCultures, id: \.self) { culture in
                                SelectableTag(
                                    text: culture,
                                    isSelected: viewModel.selectedCultures.contains(culture)
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if viewModel.selectedCultures.contains(culture) {
                                            viewModel.selectedCultures.remove(culture)
                                        } else {
                                            viewModel.selectedCultures.insert(culture)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Tips Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(QROWDTheme.accentColor)
                            
                            Text("Selection Tips")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(text: "Select at least 1 genre to continue")
                            TipRow(text: "Choose genres you're most confident playing")
                            TipRow(text: "Cultural specialization helps with targeted bookings")
                            TipRow(text: "You can add more genres later")
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

struct SelectableTag: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(QROWDTheme.bodyFont.weight(.medium))
                .foregroundColor(isSelected ? .white : QROWDTheme.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? QROWDTheme.buttonGradient : QROWDTheme.cardGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color.clear : QROWDTheme.borderColor, lineWidth: 1)
                        )
                        .shadow(
                            color: isSelected ? QROWDTheme.buttonGlow : Color.clear,
                            radius: isSelected ? 8 : 0,
                            x: 0,
                            y: 2
                        )
                )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    DJGenreView(viewModel: DJRegistrationViewModel())
} 