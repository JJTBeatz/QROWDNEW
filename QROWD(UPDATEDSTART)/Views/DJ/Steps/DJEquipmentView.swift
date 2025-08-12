import SwiftUI

struct DJEquipmentView: View {
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
                        Text("Your Equipment")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("What equipment do you have or can provide?")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, QROWDTheme.cardPadding)
                    }
                    .padding(.top, 40)
                    
                    // Selected Count
                    HStack {
                        Text("Equipment Selected")
                            .font(QROWDTheme.headlineFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        Spacer()
                        
                        Text("\(viewModel.selectedEquipment.count) items")
                            .font(QROWDTheme.bodyFont.weight(.semibold))
                            .foregroundColor(QROWDTheme.accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(QROWDTheme.accentColor.opacity(0.2))
                            )
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Equipment Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(viewModel.availableEquipment, id: \.self) { equipment in
                            EquipmentCard(
                                equipment: equipment,
                                isSelected: viewModel.selectedEquipment.contains(equipment),
                                icon: getEquipmentIcon(equipment)
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if viewModel.selectedEquipment.contains(equipment) {
                                        viewModel.selectedEquipment.remove(equipment)
                                    } else {
                                        viewModel.selectedEquipment.insert(equipment)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Quick Select Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Setup")
                            .font(QROWDTheme.headlineFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        VStack(spacing: 12) {
                            QuickSetupButton(
                                title: "Basic DJ Setup",
                                description: "Controller, Speakers, Microphone",
                                items: ["DJ Controller", "Speakers", "Microphone"]
                            ) {
                                withAnimation {
                                    viewModel.selectedEquipment.formUnion(["DJ Controller", "Speakers", "Microphone"])
                                }
                            }
                            
                            QuickSetupButton(
                                title: "Professional Setup",
                                description: "CDJs, Mixer, Speakers, Lights",
                                items: ["CDJs", "Mixer", "Speakers", "LED Lights"]
                            ) {
                                withAnimation {
                                    viewModel.selectedEquipment.formUnion(["CDJs", "Mixer", "Speakers", "LED Lights"])
                                }
                            }
                            
                            QuickSetupButton(
                                title: "Full Production",
                                description: "Everything for large events",
                                items: viewModel.availableEquipment
                            ) {
                                withAnimation {
                                    viewModel.selectedEquipment = Set(viewModel.availableEquipment)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Tips Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(QROWDTheme.accentColor)
                            
                            Text("Equipment Tips")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(text: "Select equipment you own or can reliably provide")
                            TipRow(text: "More equipment = higher booking potential")
                            TipRow(text: "Clients often need full setups for events")
                            TipRow(text: "You can partner with others for larger equipment")
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
    
    private func getEquipmentIcon(_ equipment: String) -> String {
        switch equipment {
        case "DJ Controller": return "music.note.house"
        case "CDJs": return "opticaldisc"
        case "Turntables": return "circle.circle"
        case "Mixer": return "slider.horizontal.3"
        case "Speakers": return "speaker.wave.3"
        case "Subwoofer": return "speaker.zzz"
        case "Microphone": return "mic"
        case "LED Lights": return "lightbulb"
        case "Fog Machine": return "cloud"
        case "Laser Lights": return "flashlight.on.fill"
        default: return "gear"
        }
    }
}

struct EquipmentCard: View {
    let equipment: String
    let isSelected: Bool
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? QROWDTheme.buttonGradient : QROWDTheme.cardGradient)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : QROWDTheme.accentColor)
                }
                
                // Title
                Text(equipment)
                    .font(QROWDTheme.bodyFont.weight(.medium))
                    .foregroundColor(isSelected ? .white : QROWDTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : QROWDTheme.borderColor)
                    .font(.title3)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(isSelected ? QROWDTheme.buttonGradient : QROWDTheme.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                            .stroke(isSelected ? Color.clear : QROWDTheme.borderColor, lineWidth: 1)
                    )
                    .shadow(
                        color: isSelected ? QROWDTheme.buttonGlow : Color.clear,
                        radius: isSelected ? 8 : 0,
                        x: 0,
                        y: 4
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

struct QuickSetupButton: View {
    let title: String
    let description: String
    let items: [String]
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
                
                Text("+\(items.count)")
                    .font(QROWDTheme.captionFont.weight(.bold))
                    .foregroundColor(QROWDTheme.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(QROWDTheme.accentColor.opacity(0.2))
                    )
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
    DJEquipmentView(viewModel: DJRegistrationViewModel())
} 