import SwiftUI
import Combine

struct QROWDAIAssistantView: View {
    @StateObject private var aiManager = QROWDAIManager.shared
    @State private var messageText = ""
    @State private var messages: [AIMessage] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                AIAssistantHeader {
                    dismiss()
                }
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Welcome message
                            if messages.isEmpty {
                                WelcomeMessageView { suggestion in
                                    handleSuggestionTap(suggestion)
                                }
                                .id("welcome")
                            }
                            
                            ForEach(messages) { message in
                                AIMessageBubble(message: message) { suggestion in
                                    handleSuggestionTap(suggestion)
                                }
                                .id(message.id)
                            }
                            
                            // Loading indicator
                            if aiManager.isProcessing {
                                AITypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    .onChange(of: messages.count) {
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: aiManager.isProcessing) {
                        if aiManager.isProcessing {
                            scrollToBottom(proxy: proxy)
                        }
                    }
                }
                
                // Input Area
                AIInputArea(
                    messageText: $messageText,
                    isProcessing: aiManager.isProcessing
                ) {
                    sendMessage()
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func handleSuggestionTap(_ suggestion: String) {
        messageText = suggestion
        sendMessage()
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Add user message
        let userMessage = AIMessage(
            id: UUID().uuidString,
            content: text,
            isFromUser: true,
            timestamp: Date(),
            suggestions: [],
            djRecommendations: [],
            venueRecommendations: []
        )
        
        messages.append(userMessage)
        messageText = ""
        
        // Process with AI
        Task {
            let response = await aiManager.processUserQuery(text)
            
            let aiMessage = AIMessage(
                id: UUID().uuidString,
                content: response.message,
                isFromUser: false,
                timestamp: Date(),
                suggestions: response.suggestions,
                djRecommendations: response.djRecommendations,
                venueRecommendations: response.venueRecommendations
            )
            
            await MainActor.run {
                messages.append(aiMessage)
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        let targetId = aiManager.isProcessing ? "typing" : (messages.last?.id ?? "welcome")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(targetId, anchor: .bottom)
            }
        }
    }
}

// MARK: - AI Assistant Header
struct AIAssistantHeader: View {
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(QROWDTheme.primaryText)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                QROWDLogo.small
                
                ZStack {
                    Circle()
                        .fill(QROWDTheme.buttonGradient)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("QROWD AI")
                        .font(QROWDTheme.bodyFont.weight(.semibold))
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Text("Your AI Assistant")
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
            }
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            QROWDTheme.backgroundColor
                .overlay(
                    Rectangle()
                        .fill(QROWDTheme.borderColor)
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
    }
}

// MARK: - Welcome Message
struct WelcomeMessageView: View {
    let suggestions = [
        "Find me a DJ for a rooftop in LA under $300",
        "What's trending this weekend?",
        "Show venues available on Friday",
        "Recommend House DJs for my party"
    ]
    
    let onSuggestionTap: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(QROWDTheme.buttonGradient)
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: QROWDTheme.buttonGlow,
                        radius: 20,
                        x: 0,
                        y: 4
                    )
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text("Hey! I'm your QROWD AI Assistant")
                    .font(QROWDTheme.headlineFont)
                    .foregroundColor(QROWDTheme.primaryText)
                    .multilineTextAlignment(.center)
                
                Text("I can help you find DJs, venues, events, and answer questions about nightlife. Try asking me something!")
                    .font(QROWDTheme.bodyFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Quick suggestions
            VStack(alignment: .leading, spacing: 12) {
                Text("Try asking:")
                    .font(QROWDTheme.captionFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.accentColor)
                
                VStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        SuggestionChip(text: suggestion) {
                            onSuggestionTap(suggestion)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }
}

// MARK: - AI Message Bubble
struct AIMessageBubble: View {
    let message: AIMessage
    let onSuggestionTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 12) {
            HStack {
                if message.isFromUser {
                    Spacer()
                    UserMessageContent(message: message)
                } else {
                    AIMessageContent(message: message)
                    Spacer()
                }
            }
            
            // Show recommendations and suggestions for AI messages
            if !message.isFromUser {
                VStack(spacing: 16) {
                    // DJ Recommendations
                    if !message.djRecommendations.isEmpty {
                        DJRecommendationsView(recommendations: message.djRecommendations)
                    }
                    
                    // Venue Recommendations
                    if !message.venueRecommendations.isEmpty {
                        VenueRecommendationsView(recommendations: message.venueRecommendations)
                    }
                    
                    // Suggestions
                    if !message.suggestions.isEmpty {
                        SuggestionsView(suggestions: message.suggestions, onSuggestionTap: onSuggestionTap)
                    }
                }
            }
        }
    }
}

// MARK: - Message Content Views
struct UserMessageContent: View {
    let message: AIMessage
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .font(QROWDTheme.bodyFont)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(QROWDTheme.buttonGradient)
                        .shadow(
                            color: QROWDTheme.buttonGlow,
                            radius: 6,
                            x: 0,
                            y: 2
                        )
                )
            
            Text(formatTime(message.timestamp))
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.secondaryText)
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
    }
}

struct AIMessageContent: View {
    let message: AIMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                // AI Avatar
                Circle()
                    .fill(QROWDTheme.cardGradient)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(QROWDTheme.accentColor)
                    )
                
                Text(message.content)
                    .font(QROWDTheme.bodyFont)
                    .foregroundColor(QROWDTheme.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(QROWDTheme.cardGradient)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(QROWDTheme.borderColor, lineWidth: 1)
                            )
                    )
            }
            
            Text(formatTime(message.timestamp))
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.secondaryText)
                .padding(.leading, 32)
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.85, alignment: .leading)
    }
}

// MARK: - Recommendations Views
struct DJRecommendationsView: View {
    let recommendations: [DJRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.mic")
                    .foregroundColor(QROWDTheme.accentColor)
                Text("Recommended DJs")
                    .font(QROWDTheme.bodyFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.primaryText)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recommendations) { dj in
                        DJRecommendationCard(dj: dj)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.leading, 32)
    }
}

struct VenueRecommendationsView: View {
    let recommendations: [VenueRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(QROWDTheme.accentColor)
                Text("Recommended Venues")
                    .font(QROWDTheme.bodyFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.primaryText)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(recommendations) { venue in
                    VenueRecommendationCard(venue: venue)
                }
            }
        }
        .padding(.leading, 32)
    }
}

struct SuggestionsView: View {
    let suggestions: [String]
    let onSuggestionTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(QROWDTheme.accentColor)
                Text("Try asking:")
                    .font(QROWDTheme.bodyFont.weight(.semibold))
                    .foregroundColor(QROWDTheme.primaryText)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    SuggestionChip(text: suggestion) {
                        onSuggestionTap(suggestion)
                    }
                }
            }
        }
        .padding(.leading, 32)
    }
}

// MARK: - Recommendation Cards
struct DJRecommendationCard: View {
    let dj: DJRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dj.stageName)
                .font(QROWDTheme.bodyFont.weight(.semibold))
                .foregroundColor(QROWDTheme.primaryText)
                .lineLimit(1)
            
            Text(dj.genres.prefix(2).joined(separator: ", "))
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.secondaryText)
                .lineLimit(1)
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", dj.rating))
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.primaryText)
                }
                
                Spacer()
                
                Text(dj.priceRange)
                    .font(QROWDTheme.captionFont.weight(.medium))
                    .foregroundColor(QROWDTheme.accentColor)
            }
        }
        .padding(12)
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(QROWDTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(QROWDTheme.borderColor, lineWidth: 1)
                )
        )
    }
}

struct VenueRecommendationCard: View {
    let venue: VenueRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2.fill")
                .font(.title3)
                .foregroundColor(QROWDTheme.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(venue.name)
                    .font(QROWDTheme.bodyFont.weight(.medium))
                    .foregroundColor(QROWDTheme.primaryText)
                
                Text(venue.location)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
            }
            
            Spacer()
            
            Text("\(venue.capacity) cap")
                .font(QROWDTheme.captionFont.weight(.medium))
                .foregroundColor(QROWDTheme.accentColor)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(QROWDTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(QROWDTheme.borderColor, lineWidth: 1)
                )
        )
    }
}

struct SuggestionChip: View {
    let text: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(QROWDTheme.captionFont)
                .foregroundColor(QROWDTheme.secondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(QROWDTheme.cardGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(QROWDTheme.borderColor, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Input Area
struct AIInputArea: View {
    @Binding var messageText: String
    let isProcessing: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .leading) {
                if messageText.isEmpty {
                    Text("Ask me anything about DJs, venues, or events...")
                        .font(QROWDTheme.bodyFont)
                        .foregroundColor(QROWDTheme.placeholderText)
                        .padding(.horizontal, 16)
                }
                
                TextField("", text: $messageText, axis: .vertical)
                    .font(QROWDTheme.bodyFont)
                    .foregroundColor(QROWDTheme.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .lineLimit(1...4)
                    .disabled(isProcessing)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(QROWDTheme.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(QROWDTheme.borderColor, lineWidth: 1)
                    )
            )
            
            Button(action: onSend) {
                ZStack {
                    Circle()
                        .fill(messageText.isEmpty || isProcessing ? QROWDTheme.cardGradient : QROWDTheme.buttonGradient)
                        .frame(width: 44, height: 44)
                    
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: QROWDTheme.accentColor))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(messageText.isEmpty ? QROWDTheme.secondaryText : .white)
                    }
                }
            }
            .disabled(messageText.isEmpty || isProcessing)
            .animation(.easeInOut(duration: 0.2), value: messageText.isEmpty)
            .animation(.easeInOut(duration: 0.2), value: isProcessing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            QROWDTheme.backgroundColor
                .overlay(
                    Rectangle()
                        .fill(QROWDTheme.borderColor)
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
}

// MARK: - Typing Indicator
struct AITypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(QROWDTheme.cardGradient)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(QROWDTheme.accentColor)
                )
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(QROWDTheme.secondaryText)
                        .frame(width: 6, height: 6)
                        .opacity(animationPhase == index ? 1.0 : 0.3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(QROWDTheme.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(QROWDTheme.borderColor, lineWidth: 1)
                    )
            )
            
            Spacer()
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.85, alignment: .leading)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - AI Message Model
struct AIMessage: Identifiable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let suggestions: [String]
    let djRecommendations: [DJRecommendation]
    let venueRecommendations: [VenueRecommendation]
}

// MARK: - Helper Functions
private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

#Preview {
    QROWDAIAssistantView()
} 