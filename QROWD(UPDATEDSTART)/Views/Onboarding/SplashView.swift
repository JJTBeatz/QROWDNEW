import SwiftUI

struct SplashView: View {
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var gradientOffset: CGFloat = -1
    @State private var isComplete = false
    @State private var logoScale: CGFloat = 0.3
    @State private var logoRotation: Double = 0
    @State private var particlesVisible = false
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()
            
            // Particle background effect
            if particlesVisible {
                ParticleBackground()
                    .opacity(0.3)
            }
            
            // Animated gradient overlay
            QROWDTheme.primaryGradient
                .mask(
                    Rectangle()
                        .offset(x: gradientOffset * UIScreen.main.bounds.width)
                )
                .ignoresSafeArea()
                .opacity(0.1)
            
            VStack(spacing: QROWDTheme.sectionSpacing) {
                Spacer()
                
                // Enhanced QROWD Logo with new image
                VStack(spacing: 16) {
                    // Logo with enhanced animations
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .stroke(QROWDTheme.accentColor.opacity(0.3), lineWidth: 3)
                            .frame(width: 140, height: 140)
                            .scaleEffect(logoOpacity * 0.2 + 0.8)
                            .opacity(logoOpacity * 0.6)
                        
                        // Main logo image with effects
                        Image("QrowdLogoTransparent")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .shadow(color: QROWDTheme.cardShadow, radius: 20, x: 0, y: 10)
                            .glowEffect(color: QROWDTheme.accentColor, radius: 15)
                            .rotationEffect(.degrees(logoRotation))
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // App Title with character animation
                    HStack(spacing: 4) {
                        ForEach(Array("QROWD".enumerated()), id: \.offset) { index, character in
                            Text(String(character))
                                .font(QROWDTheme.titleFont)
                                .foregroundColor(QROWDTheme.primaryText)
                                .opacity(logoOpacity)
                                .offset(y: logoOpacity > 0 ? 0 : 20)
                                .animation(
                                    QROWDAnimations.bouncy.delay(Double(index) * 0.1),
                                    value: logoOpacity
                                )
                        }
                    }
                }
                
                // Enhanced Animated Tagline
                VStack(spacing: 8) {
                    Text("Connect. Create. Celebrate.")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                        .opacity(taglineOpacity)
                        .scaleEffect(taglineOpacity * 0.2 + 0.8)
                        .animation(QROWDAnimations.smooth, value: taglineOpacity)
                    
                    // Animated underline
                    Rectangle()
                        .fill(QROWDTheme.accentColor.opacity(0.6))
                        .frame(width: taglineOpacity * 200, height: 2)
                        .animation(QROWDAnimations.smooth.delay(0.3), value: taglineOpacity)
                }
                
                Spacer()
                
                // Enhanced Loading indicator
                VStack(spacing: 16) {
                    PulsingDotsLoader()
                        .opacity(taglineOpacity)
                    
                    Text("Loading your experience...")
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText.opacity(0.8))
                        .opacity(taglineOpacity)
                        .animation(QROWDAnimations.smooth.delay(0.5), value: taglineOpacity)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            animateSplash()
        }
    }
    
    private func animateSplash() {
        // Start particles immediately
        particlesVisible = true
        
        // Logo scale and fade-in with rotation
        withAnimation(QROWDAnimations.bouncy.delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1
        }
        
        // Logo rotation effect - smooth vinyl spin
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.8)) {
                logoRotation = 360
            }
        }
        
        // Tagline fade-in with enhanced timing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(QROWDAnimations.smooth) {
                taglineOpacity = 1
            }
        }
        
        // Gradient sweep
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.linear(duration: 1.5)) {
                gradientOffset = 2
            }
        }
        
        // Complete and transition with final logo pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(QROWDAnimations.quick) {
                logoScale = 1.1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(QROWDAnimations.quick) {
                logoScale = 1.0
            }
            
            // Complete transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isComplete = true
                onComplete()
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
} 