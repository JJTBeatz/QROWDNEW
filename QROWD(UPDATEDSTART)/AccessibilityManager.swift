import Foundation
import SwiftUI
import AVFoundation

// MARK: - Content Size Category
enum ContentSizeCategory: String, CaseIterable {
    case extraSmall = "UICTContentSizeCategoryXS"
    case small = "UICTContentSizeCategoryS"
    case medium = "UICTContentSizeCategoryM"
    case large = "UICTContentSizeCategoryL"
    case extraLarge = "UICTContentSizeCategoryXL"
    case extraExtraLarge = "UICTContentSizeCategoryXXL"
    case extraExtraExtraLarge = "UICTContentSizeCategoryXXXL"
    case accessibilityMedium = "UICTContentSizeCategoryAccessibilityM"
    case accessibilityLarge = "UICTContentSizeCategoryAccessibilityL"
    case accessibilityExtraLarge = "UICTContentSizeCategoryAccessibilityXL"
    case accessibilityExtraExtraLarge = "UICTContentSizeCategoryAccessibilityXXL"
    case accessibilityExtraExtraExtraLarge = "UICTContentSizeCategoryAccessibilityXXXL"
}

// MARK: - Accessibility Manager
@MainActor
class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    @Published var isVoiceOverEnabled = false
    @Published var preferredContentSizeCategory: ContentSizeCategory = .medium
    @Published var reducedMotionEnabled = false
    @Published var increaseContrastEnabled = false
    
    private init() {
        updateAccessibilitySettings()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.updateAccessibilitySettings()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.updateAccessibilitySettings()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.updateAccessibilitySettings()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.updateAccessibilitySettings()
        }
    }
    
    private func updateAccessibilitySettings() {
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        preferredContentSizeCategory = ContentSizeCategory.allCases.first { category in
            category.rawValue == UIApplication.shared.preferredContentSizeCategory.rawValue
        } ?? .medium
        reducedMotionEnabled = UIAccessibility.isReduceMotionEnabled
        increaseContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    // MARK: - Accessibility Helpers
    func announceForVoiceOver(_ message: String) {
        guard isVoiceOverEnabled else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    func provideFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard !reducedMotionEnabled else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    func getDynamicFontSize(for style: Font.TextStyle) -> Font {
        switch preferredContentSizeCategory {
        case .extraSmall, .small:
            return .system(style, design: .rounded).weight(.medium)
        case .large, .extraLarge:
            return .system(style, design: .rounded).weight(.semibold)
        case .extraExtraLarge, .extraExtraExtraLarge:
            return .system(style, design: .rounded).weight(.bold)
        default:
            return .system(style, design: .rounded)
        }
    }
    
    func getAccessibleColors() -> (primary: Color, secondary: Color, accent: Color) {
        if increaseContrastEnabled {
            return (
                primary: Color.primary,
                secondary: Color.secondary,
                accent: QROWDTheme.accentColor
            )
        } else {
            return (
                primary: QROWDTheme.primaryText,
                secondary: QROWDTheme.secondaryText,
                accent: QROWDTheme.accentColor
            )
        }
    }
}

// MARK: - Accessible Button Component
struct AccessibleButton: View {
    let title: String
    let action: () -> Void
    let icon: String?
    let isEnabled: Bool
    let isLoading: Bool
    let style: ButtonStyle
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    enum ButtonStyle {
        case primary, secondary, destructive
    }
    
    init(
        title: String,
        action: @escaping () -> Void,
        icon: String? = nil,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        style: ButtonStyle = .primary
    ) {
        self.title = title
        self.action = action
        self.icon = icon
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.style = style
    }
    
    var body: some View {
        Button(action: {
            accessibilityManager.provideFeedback()
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .accessibility(hidden: true)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .accessibility(hidden: true)
                }
                
                Text(title)
                    .font(accessibilityManager.getDynamicFontSize(for: .headline))
            }
            .foregroundColor(textColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(12)
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .accessibility(label: Text(accessibilityLabel))
        .accessibility(hint: Text(accessibilityHint))
        .accessibility(addTraits: .isButton)
        .accessibilityRemoveTraits(isEnabled ? [] : .isButton)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return QROWDTheme.accentColor
        case .secondary:
            return QROWDTheme.cardBackground
        case .destructive:
            return .red
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return accessibilityManager.getAccessibleColors().primary
        }
    }
    
    private var accessibilityLabel: String {
        if isLoading {
            return "\(title), loading"
        }
        return title
    }
    
    private var accessibilityHint: String {
        if !isEnabled {
            return "Button is disabled"
        }
        if isLoading {
            return "Please wait"
        }
        
        switch style {
        case .primary:
            return "Double tap to \(title.lowercased())"
        case .secondary:
            return "Alternative action button"
        case .destructive:
            return "Caution: this action cannot be undone"
        }
    }
}

// MARK: - Accessible Text Field
struct AccessibleTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String?
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @FocusState private var isFocused: Bool
    
    init(
        text: Binding<String>,
        placeholder: String,
        icon: String? = nil,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.textContentType = textContentType
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(accessibilityManager.getAccessibleColors().secondary)
                    .accessibility(hidden: true)
            }
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(accessibilityManager.getDynamicFontSize(for: .body))
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .focused($isFocused)
            .accessibility(label: Text(accessibilityLabel))
            .accessibility(hint: Text(accessibilityHint))
        }
        .padding()
        .background(QROWDTheme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isFocused ? QROWDTheme.accentColor : Color.clear,
                    lineWidth: 2
                )
        )
        .cornerRadius(12)
    }
    
    private var accessibilityLabel: String {
        return "\(placeholder) text field"
    }
    
    private var accessibilityHint: String {
        if isSecure {
            return "Secure text entry for \(placeholder.lowercased())"
        }
        return "Enter your \(placeholder.lowercased())"
    }
}

// MARK: - Accessible Card Component
struct AccessibleCard<Content: View>: View {
    let content: Content
    let title: String?
    let subtitle: String?
    let action: (() -> Void)?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    init(
        title: String? = nil,
        subtitle: String? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: {
                    Task { @MainActor in
                        accessibilityManager.provideFeedback(style: .light)
                    }
                    action()
                }) {
                    cardContent
                }
                .accessibility(addTraits: .isButton)
            } else {
                cardContent
            }
        }
        .accessibility(label: Text(accessibilityLabel))
        .accessibility(hint: Text(accessibilityHint))
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(accessibilityManager.getDynamicFontSize(for: .headline))
                    .foregroundColor(accessibilityManager.getAccessibleColors().primary)
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(accessibilityManager.getDynamicFontSize(for: .subheadline))
                    .foregroundColor(accessibilityManager.getAccessibleColors().secondary)
            }
            
            content
        }
        .padding()
        .background(QROWDTheme.cardBackground)
        .cornerRadius(12)
    }
    
    private var accessibilityLabel: String {
        var label = ""
        if let title = title {
            label += title
        }
        if let subtitle = subtitle {
            if !label.isEmpty { label += ", " }
            label += subtitle
        }
        return label.isEmpty ? "Card" : label
    }
    
    private var accessibilityHint: String {
        if action != nil {
            return "Double tap to view details"
        }
        return ""
    }
}

// MARK: - Screen Reader Announcements
struct ScreenReaderAnnouncement: ViewModifier {
    let message: String
    let delay: Double
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    accessibilityManager.announceForVoiceOver(message)
                }
            }
    }
}

// MARK: - View Extensions for Accessibility
extension View {
    func announceForScreenReader(_ message: String, delay: Double = 0.5) -> some View {
        modifier(ScreenReaderAnnouncement(message: message, delay: delay))
    }
    
    func accessibleTapGesture(action: @escaping () -> Void) -> some View {
        self
            .onTapGesture {
                Task { @MainActor in
                    AccessibilityManager.shared.provideFeedback(style: .light)
                }
                action()
            }
            .accessibility(addTraits: .isButton)
    }
    
    func accessibleNavigation<Destination: View>(
        to destination: Destination,
        title: String
    ) -> some View {
        NavigationLink(destination: destination) {
            self
        }
        .accessibility(label: Text(title))
        .accessibility(hint: Text("Navigate to \(title)"))
        .accessibility(addTraits: .isButton)
    }
}

// MARK: - Accessibility Testing Helper
#if DEBUG
struct AccessibilityTestingOverlay: View {
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    if accessibilityManager.isVoiceOverEnabled {
                        Text("VoiceOver ON")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    if accessibilityManager.reducedMotionEnabled {
                        Text("Reduced Motion")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    if accessibilityManager.increaseContrastEnabled {
                        Text("High Contrast")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Text("Size: \(accessibilityManager.preferredContentSizeCategory.rawValue)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(2)
                }
                .padding()
            }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func showAccessibilityTesting() -> some View {
        self.overlay(AccessibilityTestingOverlay())
    }
}
#endif 