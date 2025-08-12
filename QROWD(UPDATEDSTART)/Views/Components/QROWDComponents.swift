import SwiftUI

// MARK: - Enhanced QROWD Text Field
struct QROWDTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @FocusState private var isFocused: Bool
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isFocused ? QROWDTheme.accentColor : QROWDTheme.secondaryText)
                .scaleEffect(isFocused ? 1.1 : 1.0)
                .animation(QROWDAnimations.bouncy, value: isFocused)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(QROWDTheme.primaryText)
                .font(QROWDTheme.bodyFont)
                .focused($isFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(QROWDTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused ? QROWDTheme.accentColor.opacity(0.6) : QROWDTheme.secondaryText.opacity(0.2),
                            lineWidth: isFocused ? 2 : 1
                        )
                        .animation(QROWDAnimations.smooth, value: isFocused)
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? QROWDTheme.accentColor.opacity(0.3) : .clear,
            radius: isFocused ? 8 : 0
        )
        .animation(QROWDAnimations.smooth, value: isFocused)
        .onTapGesture {
            isFocused = true
        }
    }
}

// MARK: - Enhanced QROWD Button
struct QROWDButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -1
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    PulsingDotsLoader()
                } else {
                    Text(title)
                        .font(QROWDTheme.headlineFont)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Main gradient background
                    LinearGradient(
                        colors: isEnabled ? [QROWDTheme.accentColor, QROWDTheme.accentColor.opacity(0.8)] : [QROWDTheme.secondaryText, QROWDTheme.secondaryText],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    
                    // Shimmer effect for enabled state
                    if isEnabled && !isLoading {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.3), .clear],
                                    startPoint: UnitPoint(x: shimmerOffset, y: 0.5),
                                    endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 0.5)
                                )
                            )
                            .onAppear {
                                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                    shimmerOffset = 1.3
                                }
                            }
                    }
                }
            )
            .cornerRadius(16)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: isEnabled ? QROWDTheme.accentColor.opacity(isPressed ? 0.6 : 0.3) : .clear,
                radius: isPressed ? 12 : 8,
                x: 0,
                y: isPressed ? 6 : 4
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isEnabled ? QROWDTheme.accentColor.opacity(0.5) : .clear, lineWidth: 1)
            )
        }
        .disabled(!isEnabled || isLoading)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(QROWDAnimations.quick) {
                isPressed = pressing
            }
        }, perform: {})
        .animation(QROWDAnimations.smooth, value: isEnabled)
        .animation(QROWDAnimations.bouncy, value: isPressed)
    }
}

// MARK: - QROWD Async Button
struct QROWDAsyncButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () async -> Void
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(title)
                    .font(QROWDTheme.headlineFont)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: isEnabled ? [QROWDTheme.accentColor, QROWDTheme.accentColor.opacity(0.8)] : [QROWDTheme.secondaryText, QROWDTheme.secondaryText],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: isEnabled ? QROWDTheme.accentColor.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Enhanced Quick Filter Button
struct QuickFilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(QROWDAnimations.bouncy, value: isSelected)
                
                Text(title)
                    .font(QROWDTheme.captionFont)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [QROWDTheme.accentColor, QROWDTheme.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            colors: [QROWDTheme.cardBackground, QROWDTheme.cardBackground],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .foregroundColor(isSelected ? .white : QROWDTheme.primaryText)
            .cornerRadius(20)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: isSelected ? QROWDTheme.accentColor.opacity(0.4) : .clear,
                radius: isSelected ? 6 : 0
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : QROWDTheme.secondaryText.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(QROWDAnimations.quick) {
                isPressed = pressing
            }
        }, perform: {})
        .animation(QROWDAnimations.smooth, value: isSelected)
    }
}

// MARK: - QROWD Secondary Button
struct QROWDSecondaryButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(QROWDTheme.bodyFont)
                .fontWeight(.medium)
                .foregroundColor(QROWDTheme.accentColor)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(QROWDTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(QROWDTheme.accentColor.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .opacity(isEnabled ? 1.0 : 0.6)
        .disabled(!isEnabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(QROWDAnimations.quick) {
                isPressed = pressing
            }
        }, perform: {})
        .animation(QROWDAnimations.smooth, value: isEnabled)
    }
}

// MARK: - Loading Button
struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    PulsingDotsLoader()
                } else {
                    Text(title)
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.accentColor)
                }
            }
        }
        .disabled(isLoading)
        .animation(QROWDAnimations.smooth, value: isLoading)
    }
}

// MARK: - Animated Card Components

struct AnimatedCard<Content: View>: View {
    let content: Content
    @State private var isVisible = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(QROWDTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(QROWDTheme.cardGradient)
                    .shadow(color: QROWDTheme.cardShadow, radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            .onAppear {
                withAnimation(QROWDAnimations.bouncy.delay(0.1)) {
                    isVisible = true
                }
            }
    }
}

struct FloatingCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(QROWDTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(QROWDTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                            .stroke(QROWDTheme.borderColor, lineWidth: 1)
                    )
                    .shadow(
                        color: QROWDTheme.secondaryText.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
    }
}

struct PulsingCard<Content: View>: View {
    let content: Content
    @State private var isPulsing = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(QROWDTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(QROWDTheme.cardGradient)
                    .shadow(
                        color: QROWDTheme.cardShadow,
                        radius: isPulsing ? 12 : 8,
                        x: 0,
                        y: isPulsing ? 6 : 4
                    )
                    .scaleEffect(isPulsing ? 1.02 : 1.0)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isPulsing.toggle()
                }
            }
    }
}

struct InteractiveCard<Content: View>: View {
    let content: Content
    let onTap: (() -> Void)?
    @State private var isPressed = false
    @State private var isHovered = false
    
    init(onTap: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.onTap = onTap
    }
    
    var body: some View {
        content
            .padding(QROWDTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(QROWDTheme.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                            .stroke(
                                isHovered ? QROWDTheme.accentColor.opacity(0.5) : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: QROWDTheme.cardShadow,
                        radius: isPressed ? 4 : 8,
                        x: 0,
                        y: isPressed ? 2 : 4
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(QROWDAnimations.quick, value: isPressed)
            .animation(QROWDAnimations.smooth, value: isHovered)
            .onTapGesture {
                onTap?()
            }
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Status Components
// Note: StatusIndicator and MagneticButton are defined later in this file with enhanced animations

// MARK: - Error Message View
struct ErrorMessageView: View {
    let message: String
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text(message)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
            }
            
            if let onRetry = onRetry {
                Button("Retry") {
                    onRetry()
                }
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.accentColor)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// Note: QROWDSecondaryButton is defined earlier in this file with enhanced animations

// QROWDSecureField is defined in AuthView.swift

// SelectableTag is defined in DJGenreView.swift

// MARK: - Progress Bar View
struct ProgressBarView: View {
    let currentStep: Int
    let totalSteps: Int
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(QROWDTheme.captionFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.accentColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(QROWDTheme.borderColor)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [QROWDTheme.accentColor, QROWDTheme.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - PRO Badge View
struct PROBadgeView: View {
    var size: Size = .medium
    
    enum Size {
        case small, medium, large
        
        var fontSize: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .footnote
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8)
            case .large: return EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(size.fontSize)
            Text("PRO")
                .font(size.fontSize.weight(.bold))
        }
        .foregroundColor(.white)
        .padding(size.padding)
        .background(
            LinearGradient(
                colors: [QROWDTheme.accentColor, Color.purple],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .shadow(color: QROWDTheme.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// Note: FloatingCard is defined above with animation in the main animated components section

// SettingsRow is defined in DJSettingsView.swift

// MARK: - Button Styles
struct QROWDPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(QROWDTheme.headlineFont)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [QROWDTheme.accentColor, QROWDTheme.accentColor.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: QROWDTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Success Message View
struct SuccessMessageView: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text(message)
                .font(QROWDTheme.captionFont)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Section Header
struct SectionHeaderView: View {
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(title: String, subtitle: String? = nil, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(QROWDTheme.headlineFont)
                    .foregroundColor(QROWDTheme.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
            }
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle) {
                    action()
                }
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.accentColor)
            }
        }
    }
}

// PROBadgeView is defined above with Size enum

// MARK: - PRO Toggle Button
struct PROToggleButton: View {
    let isPro: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isPro ? "checkmark.seal.fill" : "crown.fill")
                    .font(.title2)
                    .foregroundColor(isPro ? .green : .yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isPro ? "PRO Active" : "Upgrade to PRO")
                        .font(QROWDTheme.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text(isPro ? "All PRO features enabled" : "Unlock verified badge, analytics & more")
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isPro {
                    Text("Manage")
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.accentColor)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("QROWD PRO")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                        
                        Text("$14.99/mo")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(QROWDTheme.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                            .stroke(isPro ? Color.green.opacity(0.3) : QROWDTheme.accentColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - PRO Feature Indicator
struct PROFeatureIndicator: View {
    let feature: String
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .font(.body)
                .foregroundColor(isEnabled ? .green : QROWDTheme.secondaryText)
            
            Text(feature)
                .font(QROWDTheme.captionFont)
                .foregroundColor(isEnabled ? QROWDTheme.primaryText : QROWDTheme.secondaryText)
            
            Spacer()
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String?
    
    init(title: String, value: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
    }
    
    var body: some View {
        VStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(QROWDTheme.accentColor)
            }
            
            Text(value)
                .font(QROWDTheme.headlineFont.weight(.bold))
                .foregroundColor(QROWDTheme.primaryText)
            
            Text(title)
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(QROWDTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(QROWDTheme.borderColor, lineWidth: 1)
                )
        )
    }
}

// MARK: - Animated Components

// FloatingCard is defined above - simpler version used

// MARK: - Pulse Animation
struct PulseView: View {
    let color: Color
    let size: CGFloat
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(opacity)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: scale)
            .onAppear {
                scale = 1.3
                opacity = 0.3
            }
    }
}

// MARK: - Status Indicator with Pulse
struct StatusIndicator: View {
    let isOnline: Bool
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                if isOnline {
                    PulseView(color: .green, size: 12)
                }
                Circle()
                    .fill(isOnline ? .green : .gray)
                    .frame(width: 8, height: 8)
            }
            
            Text(label)
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.primaryText)
        }
    }
}

// MARK: - Shimmer Effect
struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    let gradient = LinearGradient(
        colors: [
            Color.gray.opacity(0.3),
            Color.gray.opacity(0.1),
            Color.gray.opacity(0.3)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        gradient
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .black, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase)
            )
            .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
            .onAppear {
                phase = 300
            }
    }
}

// MARK: - Shimmer Card Placeholder
struct ShimmerCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 20)
                .cornerRadius(4)
                .overlay(ShimmerView())
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 16)
                .cornerRadius(4)
                .overlay(ShimmerView())
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 16)
                .cornerRadius(4)
                .overlay(ShimmerView())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                .fill(QROWDTheme.cardBackground)
        )
    }
}

// MARK: - Magnetic Button
struct MagneticButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                Text(title)
                    .font(QROWDTheme.bodyFont)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(QROWDTheme.accentColor)
                    .shadow(
                        color: QROWDTheme.accentColor.opacity(0.4),
                        radius: scale > 1 ? 20 : 10,
                        x: 0,
                        y: scale > 1 ? 8 : 4
                    )
            )
        }
        .scaleEffect(scale)
        .offset(offset)
        .offset(dragOffset)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scale)
        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: offset)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { } onPressingChanged: { pressing in
            scale = pressing ? 1.1 : 1.0
        }
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    if distance < 50 {
                        // Snap back with elastic effect
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            offset = .zero
                        }
                    }
                }
        )
    }
}

// MARK: - Breathing Animation
struct BreathingView<Content: View>: View {
    let content: Content
    @State private var scale: CGFloat = 1.0
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: scale)
            .onAppear {
                scale = 1.05
            }
    }
}

// MARK: - Morphing Progress Bar
struct MorphingProgressBar: View {
    @Binding var progress: Double
    let height: CGFloat = 8
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: height / 2)
                .fill(QROWDTheme.borderColor.opacity(0.3))
                .frame(height: height)
            
            RoundedRectangle(cornerRadius: height / 2)
                .fill(
                    LinearGradient(
                        colors: [
                            QROWDTheme.accentColor,
                            QROWDTheme.accentColor.opacity(0.7)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(0, CGFloat(animatedProgress) * 300), height: height)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animatedProgress)
                .overlay(
                    // Shimmer effect on progress bar
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .mask(
                            RoundedRectangle(cornerRadius: height / 2)
                                .frame(width: max(0, CGFloat(animatedProgress) * 300), height: height)
                        )
                )
        }
        .onChange(of: progress) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Glow Effect
struct GlowEffect: ViewModifier {
    let color: Color
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.8), radius: intensity * 2, x: 0, y: 0)
            .shadow(color: color.opacity(0.4), radius: intensity * 4, x: 0, y: 0)
            .shadow(color: color.opacity(0.2), radius: intensity * 8, x: 0, y: 0)
    }
}

extension View {
    func glow(color: Color = .blue, intensity: CGFloat = 1.0) -> some View {
        self.modifier(GlowEffect(color: color, intensity: intensity))
    }
}

// MARK: - Animated DJ Card
struct AnimatedDJCard: View {
    let djName: String
    let stageName: String
    let isOnline: Bool
    let isPro: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(stageName)
                            .font(QROWDTheme.headlineFont.bold())
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        if isPro {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .glow(color: .blue, intensity: 0.5)
                        }
                    }
                    
                    Text(djName)
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
                
                Spacer()
                
                StatusIndicator(isOnline: isOnline, label: isOnline ? "Live" : "Offline")
            }
            
            HStack(spacing: 12) {
                StatCard(title: "Rating", value: "4.8", icon: "star.fill")
                StatCard(title: "Bookings", value: "127", icon: "calendar.badge.checkmark")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                .fill(QROWDTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                        .stroke(QROWDTheme.borderColor.opacity(isHovered ? 0.6 : 0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(
            color: QROWDTheme.accentColor.opacity(isHovered ? 0.2 : 0.05),
            radius: isHovered ? 16 : 8,
            x: 0,
            y: isHovered ? 8 : 4
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isHovered.toggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isHovered.toggle()
                }
            }
        }
    }
}

// MARK: - Enhanced Loading View
struct EnhancedLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            PulsingDotsLoader()
            
            Text("Loading...")
                .font(QROWDTheme.bodyFont)
                .foregroundColor(QROWDTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(QROWDTheme.backgroundColor)
    }
}

#Preview {
    ScrollView(.vertical, showsIndicators: true) {
        VStack(spacing: 20) {
            QROWDTextField(text: .constant(""), placeholder: "Search...", icon: "magnifyingglass")
            
            FloatingCard {
                StatCard(title: "This Month", value: "5", subtitle: "Bookings")
            }
            
            BreathingView {
                MagneticButton(title: "Book Now", icon: "calendar.badge.plus") {}
            }
            
            AnimatedDJCard(
                djName: "John Smith",
                stageName: "DJ Voltage",
                isOnline: true,
                isPro: true
            )
            
            ShimmerCard()
            
            VStack {
                Text("Loading Progress")
                    .font(QROWDTheme.bodyFont)
                MorphingProgressBar(progress: .constant(0.7))
            }
            
            // StatCard examples
            HStack {
                StatCard(title: "This Month", value: "5", subtitle: "Bookings")
                StatCard(title: "DJs Available", value: "50", icon: "music.mic")
            }
        }
        .padding()
    }
    .background(QROWDTheme.backgroundColor)
} 