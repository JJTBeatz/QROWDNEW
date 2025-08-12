import SwiftUI
import Combine

struct ChatView: View {
    let bookingId: String
    let otherUserName: String
    
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    
    var body: some View {
        ZStack {
            // Background
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    .onAppear {
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: viewModel.messages.count) {
                        scrollToBottom(proxy: proxy)
                    }
                }
                
                // Message Input
                HStack(spacing: 12) {
                    ZStack(alignment: .leading) {
                        if messageText.isEmpty {
                            Text("Type a message...")
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
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(QROWDTheme.cardGradient)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(QROWDTheme.borderColor, lineWidth: 1)
                            )
                    )
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(messageText.isEmpty ? QROWDTheme.secondaryText : QROWDTheme.accentColor)
                    }
                    .disabled(messageText.isEmpty)
                    .animation(.easeInOut(duration: 0.2), value: messageText.isEmpty)
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
        .navigationTitle(otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.setupChat(bookingId: bookingId)
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        Task {
            await viewModel.sendMessage(text: text)
        }
        
        messageText = ""
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = viewModel.messages.last else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: UnitPoint.bottom)
            }
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
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
                    
                    Text(formatTime(message.createdAt))
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
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
                    
                    Text(formatTime(message.createdAt))
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Chat ViewModel
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    
    private var chatId: String?
    private var messageSubscription: AnyCancellable?
    private let supabase = SupabaseManager.shared
    
    func setupChat(bookingId: String) async {
        isLoading = true
        
        do {
            // Get or create chat for this booking
            chatId = try await supabase.getOrCreateChat(bookingId: bookingId)
            
            // Load existing messages
            if let chatId = chatId {
                messages = try await supabase.getChatMessages(chatId: chatId)
                
                // Subscribe to new messages
                subscribeToMessages()
            }
        } catch {
            print("Error setting up chat: \(error)")
        }
        
        isLoading = false
    }
    
    func sendMessage(text: String) async {
        guard let chatId = chatId else { return }
        
        do {
            try await supabase.sendMessage(chatId: chatId, text: text)
        } catch {
            print("Error sending message: \(error)")
        }
    }
    
    private func subscribeToMessages() {
        guard let chatId = chatId else { return }
        
        messageSubscription = supabase.subscribeToChatMessages(chatId: chatId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMessage in
                // Add new message if it's not already in the list
                if let self = self, !self.messages.contains(where: { $0.id == newMessage.id }) {
                    self.messages.append(newMessage)
                }
            }
    }
    
    func cleanup() {
        messageSubscription?.cancel()
    }
}

// MARK: - Chat List View
struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    
    var body: some View {
        ZStack {
            // Background
            QROWDTheme.backgroundColor
                .ignoresSafeArea()
            
            NavigationView {
                VStack {
                    if viewModel.isLoading {
                        VStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: QROWDTheme.accentColor))
                                .scaleEffect(1.5)
                            
                            Text("Loading Chats...")
                                .font(QROWDTheme.bodyFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                                .padding(.top, 16)
                            Spacer()
                        }
                    } else if viewModel.chatPreviews.isEmpty {
                        VStack {
                            Spacer()
                            Image(systemName: "message.circle")
                                .font(.system(size: 60))
                                .foregroundColor(QROWDTheme.secondaryText)
                            
                            Text("No Messages Yet")
                                .font(QROWDTheme.headlineFont)
                                .foregroundColor(QROWDTheme.primaryText)
                                .padding(.top, 16)
                            
                            Text("Your conversations will appear here after bookings")
                                .font(QROWDTheme.bodyFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .padding(.horizontal, QROWDTheme.cardPadding)
                    } else {
                        List {
                            ForEach(viewModel.chatPreviews) { chatPreview in
                                NavigationLink(destination: ChatView(
                                    bookingId: chatPreview.bookingId,
                                    otherUserName: chatPreview.otherUserName
                                )) {
                                    ChatPreviewRow(chatPreview: chatPreview)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .background(QROWDTheme.backgroundColor)
                    }
                }
                .navigationTitle("Messages")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .task {
            await viewModel.loadChats()
        }
    }
}

// MARK: - Chat Preview Row
struct ChatPreviewRow: View {
    let chatPreview: ChatPreview
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(QROWDTheme.cardGradient)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(chatPreview.otherUserName.prefix(1)))
                        .font(QROWDTheme.headlineFont)
                        .foregroundColor(QROWDTheme.primaryText)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chatPreview.otherUserName)
                        .font(QROWDTheme.bodyFont.weight(.semibold))
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    Spacer()
                    
                    Text(formatDate(chatPreview.lastMessageTime))
                        .font(QROWDTheme.captionFont)
                        .foregroundColor(QROWDTheme.secondaryText)
                }
                
                Text(chatPreview.lastMessage)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                    .lineLimit(2)
            }
            
            if chatPreview.unreadCount > 0 {
                Circle()
                    .fill(QROWDTheme.accentColor)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text("\(chatPreview.unreadCount)")
                            .font(.caption2)
                            .foregroundColor(.white)
                    )
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            formatter.timeStyle = .short
        } else {
            formatter.dateStyle = .short
        }
        return formatter.string(from: date)
    }
}

// MARK: - Chat Models
struct ChatPreview: Identifiable {
    let id: String
    let bookingId: String
    let otherUserName: String
    let lastMessage: String
    let lastMessageTime: Date
    let unreadCount: Int
}

// MARK: - Chat List ViewModel
@MainActor
class ChatListViewModel: ObservableObject {
    @Published var chatPreviews: [ChatPreview] = []
    @Published var isLoading = false
    
    func loadChats() async {
        isLoading = true
        
        // Simulated chat previews for demo
        chatPreviews = [
            ChatPreview(
                id: "1",
                bookingId: "booking-1",
                otherUserName: "DJ Phoenix",
                lastMessage: "Looking forward to your event this weekend!",
                lastMessageTime: Date().addingTimeInterval(-3600),
                unreadCount: 2
            ),
            ChatPreview(
                id: "2",
                bookingId: "booking-2",
                otherUserName: "Club Promoter Mike",
                lastMessage: "What time should I arrive for setup?",
                lastMessageTime: Date().addingTimeInterval(-7200),
                unreadCount: 0
            )
        ]
        
        isLoading = false
    }
}

#Preview {
    ChatView(bookingId: "sample-booking", otherUserName: "DJ Phoenix")
} 