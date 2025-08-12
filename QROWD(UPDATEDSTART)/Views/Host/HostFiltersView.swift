import SwiftUI

struct HostFiltersView: View {
    @Binding var filters: DJSearchFilters
    let onApply: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var tempFilters: DJSearchFilters
    
    init(filters: Binding<DJSearchFilters>, onApply: @escaping () -> Void) {
        self._filters = filters
        self.onApply = onApply
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                QROWDTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: QROWDTheme.sectionSpacing) {
                        
                        // Budget Range
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Budget Range")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("$\(Int(tempFilters.minBudget ?? 50))")
                                        .font(QROWDTheme.bodyFont.weight(.semibold))
                                        .foregroundColor(QROWDTheme.accentColor)
                                    
                                    Spacer()
                                    
                                    Text("$\(Int(tempFilters.maxBudget ?? 2000))")
                                        .font(QROWDTheme.bodyFont.weight(.semibold))
                                        .foregroundColor(QROWDTheme.accentColor)
                                }
                                
                                // Budget Slider (simplified for demo)
                                VStack(spacing: 8) {
                                    Text("Min: $\(Int(tempFilters.minBudget ?? 50))")
                                        .font(QROWDTheme.captionFont)
                                        .foregroundColor(QROWDTheme.secondaryText)
                                    
                                    Slider(
                                        value: Binding(
                                            get: { tempFilters.minBudget ?? 50 },
                                            set: { tempFilters.minBudget = $0 }
                                        ),
                                        in: 50...2000,
                                        step: 25
                                    )
                                    .accentColor(QROWDTheme.accentColor)
                                    
                                    Text("Max: $\(Int(tempFilters.maxBudget ?? 2000))")
                                        .font(QROWDTheme.captionFont)
                                        .foregroundColor(QROWDTheme.secondaryText)
                                    
                                    Slider(
                                        value: Binding(
                                            get: { tempFilters.maxBudget ?? 2000 },
                                            set: { tempFilters.maxBudget = $0 }
                                        ),
                                        in: 50...2000,
                                        step: 25
                                    )
                                    .accentColor(QROWDTheme.accentColor)
                                }
                            }
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        // Genres
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Music Genres")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 100), spacing: 8)
                            ], spacing: 8) {
                                ForEach(availableGenres, id: \.self) { genre in
                                    FilterTag(
                                        text: genre,
                                        isSelected: tempFilters.genres.contains(genre)
                                    ) {
                                        if tempFilters.genres.contains(genre) {
                                            tempFilters.genres.removeAll { $0 == genre }
                                        } else {
                                            tempFilters.genres.append(genre)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        // Guest Count
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Expected Guest Count")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(guestCountOptions, id: \.range) { option in
                                    GuestCountCard(
                                        title: option.title,
                                        range: option.range,
                                        isSelected: tempFilters.guestCount == option.value
                                    ) {
                                        tempFilters.guestCount = option.value
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        // Date & Time
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Event Date & Time")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            DatePicker(
                                "Event Date",
                                selection: Binding(
                                    get: { tempFilters.eventDate ?? Date() },
                                    set: { tempFilters.eventDate = $0 }
                                ),
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(CompactDatePickerStyle())
                            .colorScheme(.dark)
                            .accentColor(QROWDTheme.accentColor)
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        // Availability Toggle
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Available Now")
                                        .font(QROWDTheme.headlineFont)
                                        .foregroundColor(QROWDTheme.primaryText)
                                    
                                    Text("Show only DJs available for immediate booking")
                                        .font(QROWDTheme.captionFont)
                                        .foregroundColor(QROWDTheme.secondaryText)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $tempFilters.availableNow)
                                    .toggleStyle(SwitchToggleStyle(tint: QROWDTheme.accentColor))
                            }
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        tempFilters = DJSearchFilters()
                    }
                    .foregroundColor(QROWDTheme.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        filters = tempFilters
                        onApply()
                        dismiss()
                    }
                    .foregroundColor(QROWDTheme.accentColor)
                    .font(.headline)
                }
            }
        }
    }
    
    private let availableGenres = [
        "House", "Hip-Hop", "Latin", "Rock", "Pop", "EDM",
        "Reggaeton", "Salsa", "Bachata", "Merengue", "Trap",
        "R&B", "Soul", "Funk", "Jazz", "Blues"
    ]
    
    private let guestCountOptions = [
        (title: "Intimate", range: "10-30", value: 20),
        (title: "Small", range: "30-50", value: 40),
        (title: "Medium", range: "50-100", value: 75),
        (title: "Large", range: "100-200", value: 150),
        (title: "Festival", range: "200+", value: 300),
        (title: "Any Size", range: "No limit", value: nil)
    ]
}

// MARK: - Filter Tag
struct FilterTag: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(QROWDTheme.captionFont.weight(.medium))
                .foregroundColor(isSelected ? .white : QROWDTheme.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? QROWDTheme.buttonGradient : QROWDTheme.cardGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color.clear : QROWDTheme.borderColor, lineWidth: 1)
                        )
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Guest Count Card
struct GuestCountCard: View {
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
    HostFiltersView(filters: .constant(DJSearchFilters())) { }
} 