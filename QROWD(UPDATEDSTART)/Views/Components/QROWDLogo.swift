import SwiftUI

// MARK: - QROWD Logo Component
struct QROWDLogo: View {
    let size: CGFloat
    let showGlow: Bool
    let showShadow: Bool
    let animated: Bool
    let showTitle: Bool
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    init(
        size: CGFloat = 60,
        showGlow: Bool = false,
        showShadow: Bool = true,
        animated: Bool = false,
        showTitle: Bool = false
    ) {
        self.size = size
        self.showGlow = showGlow
        self.showShadow = showShadow
        self.animated = animated
        self.showTitle = showTitle
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Logo Image
            Image("QrowdLogoTransparent")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .shadow(
                    color: showShadow ? QROWDTheme.cardShadow : .clear,
                    radius: showShadow ? 8 : 0,
                    x: 0,
                    y: showShadow ? 4 : 0
                )
                .glowEffect(
                    color: showGlow ? QROWDTheme.accentColor : .clear,
                    radius: showGlow ? 10 : 0
                )
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    if animated {
                        startAnimation()
                    }
                }
            
            // Optional title
            if showTitle {
                Text("QROWD")
                    .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    .foregroundColor(QROWDTheme.primaryText)
                    .tracking(2)
            }
        }
    }
    
    private func startAnimation() {
        // Continuous gentle rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // Gentle breathing effect
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            scale = 1.05
        }
    }
}

// MARK: - Logo Variants
extension QROWDLogo {
    // Navigation header logo
    static var navigationHeader: some View {
        QROWDLogo(size: 32, showGlow: false, showShadow: false, animated: false)
    }
    
    // Large display logo
    static var largeDisplay: some View {
        QROWDLogo(size: 120, showGlow: true, showShadow: true, animated: true, showTitle: true)
    }
    
    // Medium size for cards
    static var medium: some View {
        QROWDLogo(size: 60, showGlow: false, showShadow: true, animated: false)
    }
    
    // Small size for buttons/icons
    static var small: some View {
        QROWDLogo(size: 24, showGlow: false, showShadow: false, animated: false)
    }
    
    // Loading state with animation
    static var loading: some View {
        QROWDLogo(size: 40, showGlow: true, showShadow: false, animated: true)
    }
}

// MARK: - Logo with background
struct QROWDLogoWithBackground: View {
    let size: CGFloat
    let backgroundColor: Color
    let cornerRadius: CGFloat
    
    init(
        size: CGFloat = 60,
        backgroundColor: Color = QROWDTheme.cardBackground,
        cornerRadius: CGFloat = 12
    ) {
        self.size = size
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)
                .frame(width: size + 20, height: size + 20)
                .shadow(color: QROWDTheme.cardShadow, radius: 4, x: 0, y: 2)
            
            QROWDLogo(size: size, showGlow: false, showShadow: false)
        }
    }
}

// MARK: - Animated Logo Button
struct QROWDLogoButton: View {
    let size: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            QROWDLogo(size: size, showGlow: isPressed, showShadow: true)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
    }
}

// MARK: - Press Events Extension
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if pressing {
                onPress()
            } else {
                onRelease()
            }
        }, perform: {})
    }
}

#Preview("Logo Variants") {
    ScrollView {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Text("Navigation Header")
                    .font(.caption)
                    .foregroundColor(.secondary)
                QROWDLogo.navigationHeader
            }
            
            VStack(spacing: 10) {
                Text("Large Display")
                    .font(.caption)
                    .foregroundColor(.secondary)
                QROWDLogo.largeDisplay
            }
            
            VStack(spacing: 10) {
                Text("Medium")
                    .font(.caption)
                    .foregroundColor(.secondary)
                QROWDLogo.medium
            }
            
            VStack(spacing: 10) {
                Text("Small")
                    .font(.caption)
                    .foregroundColor(.secondary)
                QROWDLogo.small
            }
            
            VStack(spacing: 10) {
                Text("Loading")
                    .font(.caption)
                    .foregroundColor(.secondary)
                QROWDLogo.loading
            }
            
            VStack(spacing: 10) {
                Text("With Background")
                    .font(.caption)
                    .foregroundColor(.secondary)
                QROWDLogoWithBackground()
            }
        }
        .padding()
    }
    .background(QROWDTheme.backgroundColor)
} 