import SwiftUI

struct AnimationShowcaseView: View {
    @State private var isPressed = false
    @State private var showModal = false
    @State private var searchText = ""
    @State private var selectedFilter = false
    @State private var progress: Double = 0.3
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    
                    // Header
                    VStack(spacing: 16) {
                        Text("🎨 QROWD Animations")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .glowEffect(color: QROWDTheme.accentColor, radius: 8)
                            .bounceOnAppear()
                        
                        Text("Modern animations inspired by ReactBits & Dribbble")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .fadeInUp(delay: 0.2)
                    }
                    
                    // Button Animations Section
                    AnimatedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Button Animations", icon: "hand.tap.fill")
                            
                            VStack(spacing: 12) {
                                QROWDButton(
                                    title: "Primary Button",
                                    isLoading: false,
                                    isEnabled: true
                                ) {}
                                
                                QROWDSecondaryButton(
                                    title: "Secondary Button",
                                    isEnabled: true
                                ) {}
                                
                                MagneticButton(
                                    title: "Magnetic Button",
                                    icon: "hand.draw"
                                ) {}
                            }
                        }
                    }
                    .slideInFromLeft(delay: 0.3)
                    
                    // Input Animations Section
                    AnimatedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Input Animations", icon: "textformat")
                            
                            VStack(spacing: 12) {
                                QROWDTextField(
                                    text: $searchText,
                                    placeholder: "Search with glow effect...",
                                    icon: "magnifyingglass"
                                )
                                
                                HStack(spacing: 12) {
                                    QuickFilterButton(
                                        title: "House",
                                        icon: "music.note",
                                        isSelected: selectedFilter
                                    ) {
                                        selectedFilter.toggle()
                                    }
                                    
                                    QuickFilterButton(
                                        title: "Hip-Hop",
                                        icon: "music.note",
                                        isSelected: false
                                    ) {}
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .slideInFromRight(delay: 0.4)
                    
                    // Card Animations Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Card Animations", icon: "rectangle.stack.fill")
                            .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        HStack(spacing: 16) {
                            FloatingCard {
                                StatDisplay(title: "Floating", value: "Card", icon: "cloud")
                            }
                            .frame(maxWidth: .infinity)
                            
                            PulsingCard {
                                StatDisplay(title: "Pulsing", value: "Card", icon: "heart.fill")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        InteractiveCard(onTap: {
                            showModal = true
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Interactive Card")
                                        .font(QROWDTheme.headlineFont)
                                        .foregroundColor(QROWDTheme.primaryText)
                                    
                                    Text("Tap to see modal animation")
                                        .font(QROWDTheme.captionFont)
                                        .foregroundColor(QROWDTheme.secondaryText)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(QROWDTheme.accentColor)
                            }
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                    }
                    .staggeredAnimation(index: 2, total: 6)
                    
                    // Status & Loading Section
                    AnimatedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Status & Loading", icon: "circle.fill")
                            
                            VStack(spacing: 16) {
                                HStack(spacing: 20) {
                                    StatusIndicator(isOnline: true, label: "Online")
                                    StatusIndicator(isOnline: false, label: "Offline")
                                    Spacer()
                                }
                                
                                HStack(spacing: 20) {
                                    PulsingDotsLoader()
                                    Spacer()
                                    WaveLoader()
                                    Spacer()
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Progress")
                                            .font(QROWDTheme.bodyFont)
                                            .foregroundColor(QROWDTheme.primaryText)
                                        
                                        Spacer()
                                        
                                        Text("\(Int(progress * 100))%")
                                            .font(QROWDTheme.captionFont)
                                            .foregroundColor(QROWDTheme.accentColor)
                                    }
                                    
                                    MorphingProgressBar(progress: $progress)
                                    
                                    Button("Update Progress") {
                                        withAnimation {
                                            progress = Double.random(in: 0.1...1.0)
                                        }
                                    }
                                    .font(QROWDTheme.captionFont)
                                    .foregroundColor(QROWDTheme.accentColor)
                                }
                            }
                        }
                    }
                    .slideInFromBottom(delay: 0.5)
                    
                    // Gesture Animations Section
                    AnimatedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Gesture Animations", icon: "hand.point.up.left.fill")
                            
                            VStack(spacing: 16) {
                                Text("Try different interactions:")
                                    .font(QROWDTheme.bodyFont)
                                    .foregroundColor(QROWDTheme.secondaryText)
                                
                                HStack(spacing: 20) {
                                    Button("Wiggle") {
                                        // Wiggle animation is handled by the modifier
                                    }
                                    .padding()
                                    .background(QROWDTheme.cardBackground)
                                    .cornerRadius(12)
                                    .foregroundColor(QROWDTheme.primaryText)
                                    .wiggleOnTap()
                                    
                                    Button("Press Me") {
                                        // Press animation is handled by the modifier
                                    }
                                    .padding()
                                    .background(QROWDTheme.accentColor)
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .pressAnimation()
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .fadeInUp(delay: 0.6)
                    
                    // Animation Showcase List
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Staggered List Animation", icon: "list.bullet")
                            .padding(.horizontal, QROWDTheme.cardPadding)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(0..<5, id: \.self) { index in
                                AnimatedListItem(
                                    title: "List Item \(index + 1)",
                                    subtitle: "Staggered animation example",
                                    index: index
                                )
                                .staggeredAnimation(index: index, total: 5)
                            }
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical, 20)
            }
            .background(AnimatedGradientBackground())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showModal) {
            ModalView()
        }
    }
}

// MARK: - Supporting Components

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(QROWDTheme.accentColor)
                .floatingAnimation()
            
            Text(title)
                .font(QROWDTheme.headlineFont)
                .foregroundColor(QROWDTheme.primaryText)
            
            Spacer()
        }
    }
}

struct StatDisplay: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(QROWDTheme.accentColor)
            
            Text(value)
                .font(QROWDTheme.headlineFont)
                .foregroundColor(QROWDTheme.primaryText)
            
            Text(title)
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct AnimatedListItem: View {
    let title: String
    let subtitle: String
    let index: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(QROWDTheme.accentColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("\(index + 1)")
                        .font(QROWDTheme.bodyFont.bold())
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(QROWDTheme.bodyFont)
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text(subtitle)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(QROWDTheme.secondaryText)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(QROWDTheme.cardGradient)
        )
        .pressAnimation()
    }
}

struct ModalView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                QROWDTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("🎉 Modal Animation")
                        .font(QROWDTheme.titleFont)
                        .foregroundColor(QROWDTheme.primaryText)
                        .bounceOnAppear()
                    
                    Text("This modal slides in with smooth animations")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .fadeInUp(delay: 0.2)
                    
                    QROWDButton(
                        title: "Close Modal",
                        isLoading: false,
                        isEnabled: true
                    ) {
                        dismiss()
                    }
                    .slideInFromBottom(delay: 0.3)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(QROWDTheme.accentColor)
                }
            }
        }
        .modifier(ScaleTransition(isPresented: true))
    }
}

#Preview {
    AnimationShowcaseView()
} 