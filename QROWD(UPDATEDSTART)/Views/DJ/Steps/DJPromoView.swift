import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct DJPromoView: View {
    @ObservedObject var viewModel: DJRegistrationViewModel
    @State private var showingAudioPicker = false
    @State private var showingVideoPicker = false
    @State private var videoPickerItem: PhotosPickerItem?
    
    var body: some View {
        ZStack {
            // Background
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: QROWDTheme.sectionSpacing) {
                    
                    // Header
                    VStack(spacing: 12) {
                        Text("Show Your Skills")
                            .font(QROWDTheme.titleFont)
                            .foregroundColor(QROWDTheme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Upload audio or video promos to showcase your talent")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, QROWDTheme.cardPadding)
                    }
                    .padding(.top, 40)
                    
                    // Upload Cards
                    VStack(spacing: 20) {
                        
                        // Audio Upload
                        VStack(spacing: 16) {
                            HStack {
                                Text("Audio Promo")
                                    .font(QROWDTheme.headlineFont)
                                    .foregroundColor(QROWDTheme.primaryText)
                                
                                Spacer()
                                
                                if viewModel.audioPromoData != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title3)
                                }
                            }
                            
                            MediaUploadCard(
                                title: "Upload Audio Mix",
                                subtitle: "MP3, WAV, M4A up to 50MB",
                                icon: "music.note",
                                hasContent: viewModel.audioPromoData != nil,
                                isLoading: viewModel.isLoading
                            ) {
                                showingAudioPicker = true
                            }
                            
                            if viewModel.audioPromoData != nil {
                                HStack {
                                    Image(systemName: "waveform")
                                        .foregroundColor(QROWDTheme.accentColor)
                                    
                                    Text("Audio uploaded successfully")
                                        .font(QROWDTheme.captionFont)
                                        .foregroundColor(QROWDTheme.secondaryText)
                                    
                                    Spacer()
                                    
                                    Button("Remove") {
                                        viewModel.audioPromoData = nil
                                        viewModel.audioPromoURL = nil
                                    }
                                    .font(QROWDTheme.captionFont)
                                    .foregroundColor(.red)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // Video Upload
                        VStack(spacing: 16) {
                            HStack {
                                Text("Video Promo")
                                    .font(QROWDTheme.headlineFont)
                                    .foregroundColor(QROWDTheme.primaryText)
                                
                                Spacer()
                                
                                if viewModel.videoPromoData != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title3)
                                }
                            }
                            
                            MediaUploadCard(
                                title: "Upload Performance Video",
                                subtitle: "MP4, MOV up to 100MB",
                                icon: "video",
                                hasContent: viewModel.videoPromoData != nil,
                                isLoading: viewModel.isLoading
                            ) {
                                showingVideoPicker = true
                            }
                            
                            if viewModel.videoPromoData != nil {
                                HStack {
                                    Image(systemName: "video.fill")
                                        .foregroundColor(QROWDTheme.accentColor)
                                    
                                    Text("Video uploaded successfully")
                                        .font(QROWDTheme.captionFont)
                                        .foregroundColor(QROWDTheme.secondaryText)
                                    
                                    Spacer()
                                    
                                    Button("Remove") {
                                        viewModel.videoPromoData = nil
                                        viewModel.videoPromoURL = nil
                                    }
                                    .font(QROWDTheme.captionFont)
                                    .foregroundColor(.red)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Example Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Great Promo Examples")
                            .font(QROWDTheme.headlineFont)
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        VStack(spacing: 12) {
                            ExampleCard(
                                type: "Audio",
                                title: "DJ Mix Highlight",
                                description: "3-5 minute mix showing your best transitions and track selection",
                                icon: "headphones"
                            )
                            
                            ExampleCard(
                                type: "Video", 
                                title: "Live Performance",
                                description: "Short clip of you performing at an event, showing crowd engagement",
                                icon: "camera"
                            )
                            
                            ExampleCard(
                                type: "Either",
                                title: "Professional Quality",
                                description: "Clear audio/video quality that represents your professional standards",
                                icon: "star"
                            )
                        }
                    }
                    .padding(.horizontal, QROWDTheme.cardPadding)
                    
                    // Tips Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(QROWDTheme.accentColor)
                            
                            Text("Upload Tips")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(text: "This step is optional but highly recommended")
                            TipRow(text: "Profiles with media get 3x more bookings")
                            TipRow(text: "Keep content under file size limits")
                            TipRow(text: "You can always add or update content later")
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
        .photosPicker(isPresented: $showingVideoPicker, selection: $videoPickerItem, matching: .videos)
        .fileImporter(
            isPresented: $showingAudioPicker,
            allowedContentTypes: [.audio, .mp3, .wav, .mpeg4Audio],
            allowsMultipleSelection: false
        ) { result in
            handleAudioFileSelection(result)
        }
        .onChange(of: videoPickerItem) { _, newItem in
            handleVideoSelection(newItem)
        }
    }
    
    private func handleAudioFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                do {
                    // Check file size (50MB limit)
                    let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                    if let fileSize = resourceValues.fileSize, fileSize > 50 * 1024 * 1024 {
                        await MainActor.run {
                            viewModel.errorMessage = "Audio file must be under 50MB"
                            viewModel.showingError = true
                        }
                        return
                    }
                    
                    let data = try Data(contentsOf: url)
                    await viewModel.uploadAudioPromo(data: data)
                } catch {
                    await MainActor.run {
                        viewModel.errorMessage = "Failed to load audio file: \(error.localizedDescription)"
                        viewModel.showingError = true
                    }
                }
            }
        case .failure(let error):
            viewModel.errorMessage = "Failed to select audio file: \(error.localizedDescription)"
            viewModel.showingError = true
        }
    }
    
    private func handleVideoSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await viewModel.uploadVideoPromo(data: data)
                videoPickerItem = nil
            }
        }
    }
}

struct MediaUploadCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let hasContent: Bool
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: QROWDTheme.accentColor))
                        .scaleEffect(1.2)
                } else {
                    ZStack {
                        Circle()
                            .fill(hasContent ? QROWDTheme.buttonGradient : QROWDTheme.cardGradient)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: hasContent ? "checkmark" : icon)
                            .font(.title)
                            .foregroundColor(hasContent ? .white : QROWDTheme.accentColor)
                    }
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(QROWDTheme.bodyFont.weight(.semibold))
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text(subtitle)
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
                
                if !hasContent && !isLoading {
                    Text("Tap to upload")
                        .font(QROWDTheme.captionFont.weight(.medium))
                        .foregroundColor(QROWDTheme.accentColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(QROWDTheme.accentColor.opacity(0.2))
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                    .fill(QROWDTheme.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: QROWDTheme.cornerRadius)
                            .stroke(hasContent ? QROWDTheme.accentColor : QROWDTheme.borderColor, lineWidth: hasContent ? 2 : 1)
                    )
            )
        }
        .disabled(isLoading)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct ExampleCard: View {
    let type: String
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(QROWDTheme.accentColor)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(type)
                        .font(QROWDTheme.captionFont.weight(.semibold))
                        .foregroundColor(QROWDTheme.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(QROWDTheme.accentColor.opacity(0.2))
                        )
                    
                    Text(title)
                        .font(QROWDTheme.bodyFont.weight(.medium))
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Spacer()
                }
                
                Text(description)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
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

#Preview {
    DJPromoView(viewModel: DJRegistrationViewModel())
} 