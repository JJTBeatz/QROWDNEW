import SwiftUI

struct DJSocialLinksView: View {
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
                        Text("Connect Your Socials")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Link your social media to showcase your work")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, QROWDTheme.cardPadding)
                    }
                    .padding(.top, 40)
                    
                    // Social Links Form
                    VStack(spacing: 20) {
                        
                        // Instagram
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.pink)
                                
                                Text("Instagram")
                                    .font(QROWDTheme.bodyFont.weight(.semibold))
                                    .foregroundColor(QROWDTheme.primaryText)
                            }
                            
                            SocialTextField(
                                text: $viewModel.instagramHandle,
                                placeholder: "your_username",
                                prefix: "@",
                                icon: "at"
                            )
                            
                            Text("Your Instagram handle without the @ symbol")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                        }
                        
                        // SoundCloud
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "waveform")
                                    .foregroundColor(.orange)
                                
                                Text("SoundCloud")
                                    .font(QROWDTheme.bodyFont.weight(.semibold))
                                    .foregroundColor(QROWDTheme.primaryText)
                            }
                            
                            SocialTextField(
                                text: $viewModel.soundcloudURL,
                                placeholder: "soundcloud.com/your-profile",
                                prefix: "🔗",
                                icon: "link"
                            )
                            
                            Text("Your complete SoundCloud profile URL")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Benefits Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(QROWDTheme.accentColor)
                            
                            Text("Why Connect Socials?")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BenefitRow(icon: "eye.fill", text: "Clients can see your latest content")
                            BenefitRow(icon: "heart.fill", text: "Build trust with social proof")
                            BenefitRow(icon: "music.note", text: "Showcase your music catalog")
                            BenefitRow(icon: "person.3.fill", text: "Display your fan following")
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
                    
                    // Preview Cards
                    if !viewModel.instagramHandle.isEmpty || !viewModel.soundcloudURL.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Profile Preview")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                            
                            VStack(spacing: 12) {
                                if !viewModel.instagramHandle.isEmpty {
                                    SocialPreviewCard(
                                        platform: "Instagram",
                                        handle: "@\(viewModel.instagramHandle)",
                                        icon: "camera.fill",
                                        color: .pink
                                    )
                                }
                                
                                if !viewModel.soundcloudURL.isEmpty {
                                    SocialPreviewCard(
                                        platform: "SoundCloud",
                                        handle: viewModel.soundcloudURL,
                                        icon: "waveform",
                                        color: .orange
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                    }
                    
                    // Tips Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(QROWDTheme.accentColor)
                            
                            Text("Pro Tips")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(text: "These links are optional but highly recommended")
                            TipRow(text: "Keep your profiles public for maximum visibility")
                            TipRow(text: "Post regularly to show you're active")
                            TipRow(text: "You can add more platforms later")
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

struct SocialTextField: View {
    @Binding var text: String
    let placeholder: String
    let prefix: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(QROWDTheme.accentColor)
                .frame(width: 20)
            
            HStack(spacing: 4) {
                Text(prefix)
                    .font(QROWDTheme.bodyFont.weight(.medium))
                    .foregroundColor(QROWDTheme.secondaryText)
                
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.placeholderText)
                    }
                    
                    TextField("", text: $text)
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.primaryText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
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
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(QROWDTheme.accentColor)
                .font(.caption)
                .frame(width: 16)
            
            Text(text)
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.secondaryText)
            
            Spacer()
        }
    }
}

struct SocialPreviewCard: View {
    let platform: String
    let handle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(platform)
                    .font(QROWDTheme.captionFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text(handle)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                .fill(QROWDTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

#Preview {
    DJSocialLinksView(viewModel: DJRegistrationViewModel())
} 