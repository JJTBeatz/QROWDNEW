import SwiftUI

struct DJAvailabilityView: View {
    @ObservedObject var viewModel: DJRegistrationViewModel
    
    var body: some View {
        ZStack {
            // Background
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: QROWDTheme.sectionSpacing) {
                    
                    // Header
                    VStack(spacing: 12) {
                        Text("Your Availability")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("When are you typically available for gigs?")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, QROWDTheme.cardPadding)
                    }
                    .padding(.top, 40)
                    
                    // Availability Grid
                    VStack(spacing: 16) {
                        ForEach(viewModel.weekdays, id: \.self) { weekday in
                            AvailabilityRow(
                                weekday: weekday,
                                timeSlots: viewModel.timeSlots,
                                selectedSlots: viewModel.availability[weekday] ?? [],
                                onToggle: { timeSlot in
                                    viewModel.toggleAvailability(day: weekday, timeSlot: timeSlot)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Quick Select
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Select")
                            .font(QROWDTheme.headlineFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        VStack(spacing: 12) {
                            QuickAvailabilityButton(
                                title: "Weekends Only",
                                description: "Friday, Saturday, Sunday evenings"
                            ) {
                                ["Friday", "Saturday", "Sunday"].forEach { day in
                                    viewModel.availability[day] = ["10PM-2AM", "2AM-6AM"]
                                }
                            }
                            
                            QuickAvailabilityButton(
                                title: "All Evenings",
                                description: "Every day 6PM onwards"
                            ) {
                                viewModel.weekdays.forEach { day in
                                    viewModel.availability[day] = ["6PM-10PM", "10PM-2AM", "2AM-6AM"]
                                }
                            }
                            
                            QuickAvailabilityButton(
                                title: "Always Available",
                                description: "All days, all times"
                            ) {
                                viewModel.weekdays.forEach { day in
                                    viewModel.availability[day] = viewModel.timeSlots
                                }
                            }
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    Spacer(minLength: 100)
                }
            }
        }
    }
}

struct AvailabilityRow: View {
    let weekday: String
    let timeSlots: [String]
    let selectedSlots: [String]
    let onToggle: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(weekday)
                    .font(QROWDTheme.bodyFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Spacer()
                
                Text("\(selectedSlots.count)/\(timeSlots.count)")
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(QROWDTheme.accentColor.opacity(0.2))
                    )
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(timeSlots, id: \.self) { timeSlot in
                    TimeSlotButton(
                        timeSlot: timeSlot,
                        isSelected: selectedSlots.contains(timeSlot)
                    ) {
                        onToggle(timeSlot)
                    }
                }
            }
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

struct TimeSlotButton: View {
    let timeSlot: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(timeSlot)
                .font(QROWDTheme.captionFont.weight(.medium))
                .foregroundColor(isSelected ? .white : QROWDTheme.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? QROWDTheme.buttonGradient : QROWDTheme.cardGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.clear : QROWDTheme.borderColor, lineWidth: 1)
                        )
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct QuickAvailabilityButton: View {
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(QROWDTheme.bodyFont.weight(.semibold))
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text(description)
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(QROWDTheme.accentColor)
                    .font(.title3)
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
}

#Preview {
    DJAvailabilityView(viewModel: DJRegistrationViewModel())
} 