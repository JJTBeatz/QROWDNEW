import SwiftUI

// MARK: - Animation Constants
struct QROWDAnimations {
    
    // MARK: - Timing
    static let fast = 0.2
    static let medium = 0.4
    static let slow = 0.8
    static let splash = 1.2
    
    // MARK: - Spring Animations
    static let bouncy = Animation.interpolatingSpring(stiffness: 300, damping: 20)
    static let gentle = Animation.interpolatingSpring(stiffness: 150, damping: 30)
    static let snappy = Animation.interpolatingSpring(stiffness: 200, damping: 15)
    
    // MARK: - Easing Animations
    static let smooth = Animation.easeInOut(duration: medium)
    static let quick = Animation.easeOut(duration: fast)
    static let delayed = Animation.easeInOut(duration: medium).delay(0.1)
    
    // MARK: - Complex Animations
    static let cardFlip = Animation.easeInOut(duration: 0.6)
    static let slideIn = Animation.easeOut(duration: 0.5)
    static let fadeScale = Animation.easeInOut(duration: 0.3)
    static let wiggle = Animation.easeInOut(duration: 0.15).repeatCount(3, autoreverses: true)
}

// MARK: - Animation View Modifiers
extension View {
    
    // MARK: - Scale Animation
    func scaleOnTap(scale: CGFloat = 0.95) -> some View {
        self.scaleEffect(scale)
            .animation(QROWDAnimations.quick, value: scale)
    }
    
    // MARK: - Bounce Animation
    func bounceOnAppear(delay: Double = 0) -> some View {
        self.modifier(BounceOnAppearModifier(delay: delay))
    }
    
    // MARK: - Slide In Animation
    func slideInFromLeft(delay: Double = 0) -> some View {
        self.modifier(SlideInModifier(direction: .leading, delay: delay))
    }
    
    func slideInFromRight(delay: Double = 0) -> some View {
        self.modifier(SlideInModifier(direction: .trailing, delay: delay))
    }
    
    func slideInFromBottom(delay: Double = 0) -> some View {
        self.modifier(SlideInModifier(direction: .bottom, delay: delay))
    }
    
    // MARK: - Fade Animation
    func fadeInUp(delay: Double = 0) -> some View {
        self.modifier(FadeInUpModifier(delay: delay))
    }
    
    // MARK: - Shimmer Effect
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
    
    // MARK: - Glow Effect
    func glowEffect(color: Color = QROWDTheme.accentColor, radius: CGFloat = 10) -> some View {
        self.modifier(GlowModifier(color: color, radius: radius))
    }
    
    // MARK: - Floating Animation
    func floatingAnimation() -> some View {
        self.modifier(FloatingModifier())
    }
    
    // MARK: - Press Animation
    func pressAnimation() -> some View {
        self.modifier(PressAnimationModifier())
    }
    
    // MARK: - Wiggle Animation
    func wiggleOnTap() -> some View {
        self.modifier(WiggleModifier())
    }
    
    // MARK: - Card Flip Animation
    func flipCard(isFlipped: Bool) -> some View {
        self.modifier(CardFlipModifier(isFlipped: isFlipped))
    }
    
    // MARK: - Staggered List Animation
    func staggeredAnimation(index: Int, total: Int) -> some View {
        self.modifier(StaggeredAnimationModifier(index: index, total: total))
    }
}

// MARK: - Animation Modifiers

struct BounceOnAppearModifier: ViewModifier {
    let delay: Double
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(hasAppeared ? 1.0 : 0.8)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .animation(QROWDAnimations.bouncy.delay(delay), value: hasAppeared)
            .onAppear {
                hasAppeared = true
            }
    }
}

struct SlideInModifier: ViewModifier {
    enum Direction {
        case leading, trailing, top, bottom
    }
    
    let direction: Direction
    let delay: Double
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: hasAppeared ? 0 : offsetX,
                y: hasAppeared ? 0 : offsetY
            )
            .opacity(hasAppeared ? 1.0 : 0.0)
            .animation(QROWDAnimations.slideIn.delay(delay), value: hasAppeared)
            .onAppear {
                hasAppeared = true
            }
    }
    
    private var offsetX: CGFloat {
        switch direction {
        case .leading: return -100
        case .trailing: return 100
        default: return 0
        }
    }
    
    private var offsetY: CGFloat {
        switch direction {
        case .top: return -100
        case .bottom: return 100
        default: return 0
        }
    }
}

struct FadeInUpModifier: ViewModifier {
    let delay: Double
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: hasAppeared ? 0 : 30)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .animation(QROWDAnimations.smooth.delay(delay), value: hasAppeared)
            .onAppear {
                hasAppeared = true
            }
    }
}

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var startPoint = UnitPoint(x: -1, y: 0.5)
    @State private var endPoint = UnitPoint(x: 0, y: 0.5)
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: startPoint,
                            endPoint: endPoint
                        )
                    )
                    .opacity(isActive ? 1 : 0)
            )
            .onAppear {
                if isActive {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        startPoint = UnitPoint(x: 1, y: 0.5)
                        endPoint = UnitPoint(x: 2, y: 0.5)
                    }
                }
            }
    }
}

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var isGlowing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isGlowing ? 0.8 : 0.4), radius: isGlowing ? radius * 1.5 : radius)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isGlowing.toggle()
                }
            }
    }
}

struct FloatingModifier: ViewModifier {
    @State private var isFloating = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -5 : 5)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isFloating)
            .onAppear {
                isFloating = true
            }
    }
}

struct PressAnimationModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onTapGesture {
                withAnimation(QROWDAnimations.quick) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(QROWDAnimations.quick) {
                        isPressed = false
                    }
                }
            }
    }
}

struct WiggleModifier: ViewModifier {
    @State private var wiggleOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: wiggleOffset)
            .onTapGesture {
                withAnimation(QROWDAnimations.wiggle) {
                    wiggleOffset = 5
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    wiggleOffset = 0
                }
            }
    }
}

struct CardFlipModifier: ViewModifier {
    let isFlipped: Bool
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .animation(QROWDAnimations.cardFlip, value: isFlipped)
    }
}

struct StaggeredAnimationModifier: ViewModifier {
    let index: Int
    let total: Int
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1.0 : 0.0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(
                QROWDAnimations.smooth.delay(Double(index) * 0.1),
                value: hasAppeared
            )
            .onAppear {
                hasAppeared = true
            }
    }
}

// MARK: - Animated Background Components

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                QROWDTheme.backgroundColor,
                Color(hex: "#1A0B2E"),
                QROWDTheme.backgroundColor
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct ParticleBackground: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(QROWDTheme.accentColor.opacity(0.3))
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .animation(.linear(duration: particle.duration).repeatForever(autoreverses: false), value: particle.position)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        for _ in 0..<20 {
            particles.append(Particle())
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for i in particles.indices {
                particles[i].updatePosition()
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var duration: Double
    
    init() {
        self.position = CGPoint(x: CGFloat.random(in: 0...UIScreen.main.bounds.width), 
                               y: CGFloat.random(in: 0...UIScreen.main.bounds.height))
        self.size = CGFloat.random(in: 2...8)
        self.duration = Double.random(in: 2...8)
    }
    
    mutating func updatePosition() {
        position.x += CGFloat.random(in: -2...2)
        position.y += CGFloat.random(in: -2...2)
        
        // Keep particles on screen
        position.x = max(0, min(UIScreen.main.bounds.width, position.x))
        position.y = max(0, min(UIScreen.main.bounds.height, position.y))
    }
}

// MARK: - Loading Animations

struct PulsingDotsLoader: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(QROWDTheme.accentColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct WaveLoader: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Rectangle()
                    .fill(QROWDTheme.accentColor)
                    .frame(width: 4, height: isAnimating ? 20 : 10)
                    .animation(
                        .easeInOut(duration: 0.8)
                        .repeatForever()
                        .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Transition Animations

struct SlideTransition: ViewModifier {
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
    }
}

struct ScaleTransition: ViewModifier {
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .transition(.scale.combined(with: .opacity))
    }
} 