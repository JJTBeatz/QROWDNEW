#if DEBUG
import SwiftUI
import Foundation

// MARK: - Developer Tools Manager
@MainActor
class DeveloperToolsManager: ObservableObject {
    static let shared = DeveloperToolsManager()
    
    @Published var showingDebugPanel = false
    @Published var enableNetworkLogging = true
    @Published var enablePerformanceMonitoring = true
    @Published var showTouchIndicators = false
    @Published var simulateSlowNetwork = false
    
    private init() {}
    
    func toggleDebugPanel() {
        showingDebugPanel.toggle()
    }
}

// MARK: - Debug Panel View
struct DebugPanelView: View {
    @StateObject private var devTools = DeveloperToolsManager.shared
    @StateObject private var errorManager = ErrorManager.shared
    @StateObject private var imageCache = ImageCacheManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Performance Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Performance")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Toggle("Network Logging", isOn: $devTools.enableNetworkLogging)
                        Toggle("Performance Monitoring", isOn: $devTools.enablePerformanceMonitoring)
                        Toggle("Touch Indicators", isOn: $devTools.showTouchIndicators)
                        Toggle("Simulate Slow Network", isOn: $devTools.simulateSlowNetwork)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Error Management Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Error Management")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("Current Error: \(errorManager.currentError?.userFriendlyMessage ?? "None")")
                                .font(.subheadline)
                            Spacer()
                            Button("Clear") {
                                errorManager.clearError()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        Button("Trigger Test Error") {
                            errorManager.handleError(
                                NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "This is a test error"]),
                                context: "Debug Panel Test"
                            )
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Cache Management Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cache Management")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Cache Size: \(imageCache.getCacheSize())")
                            .font(.subheadline)
                        
                        HStack {
                            Button("Clear Cache") {
                                imageCache.clearCache()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Preload Test Images") {
                                preloadTestImages()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Notifications Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notifications")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Button("Test Notification") {
                            Task {
                                await testNotification()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Mock Data Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mock Data")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Button("Generate Mock DJ Data") {
                            generateMockDJData()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Debug Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        devTools.showingDebugPanel = false
                    }
                }
            }
        }
    }
    
    private func testNotification() async {
        let mockEvent = TrendingEvent(
            from: TrendingEventData(
                event_id: "test_123",
                title: "Test Event",
                thumbnail_url: nil,
                event_date: ISO8601DateFormatter().string(from: Date().addingTimeInterval(7200)), // 2 hours from now
                start_time: "20:00",
                location: "Test Location",
                venue_name: "Test Venue",
                ticket_price: 25.0,
                available_tickets: 100,
                dj_stage_name: "Test DJ",
                recent_sales_count: 0
            )
        )
        
        await NotificationManager.shared.scheduleEventReminder(
            for: mockEvent,
            userId: "test_user",
            ticketQuantity: 1
        )
    }
    
    private func preloadTestImages() {
        let testURLs = [
            "https://example.com/image1.jpg",
            "https://example.com/image2.jpg",
            "https://example.com/image3.jpg"
        ]
        
        for urlString in testURLs {
            Task {
                _ = await imageCache.loadImage(from: urlString)
            }
        }
    }
    
    private func generateMockDJData() {
        // Create mock DJ data for testing
        let mockDJData = DJCardData(
            id: "mock_dj_123",
            stage_name: "Test DJ",
            city: "Test City",
            genres: ["Electronic", "House"],
            rating: 4.5,
            budget_min: 150.0,
            promo_media_urls: ["https://example.com/promo1.jpg"],
            is_available: true,
            is_pro: false
        )
        
        let mockDJCard = DJCard(from: mockDJData)
        print("Generated mock DJ: \(mockDJCard.stageName)")
    }
}

// MARK: - Network Logger
class NetworkLogger: ObservableObject {
    static let shared = NetworkLogger()
    
    @Published var logs: [NetworkLog] = []
    
    private init() {}
    
    @MainActor
    func logRequest(_ request: URLRequest) {
        guard DeveloperToolsManager.shared.enableNetworkLogging else { return }
        
        let log = NetworkLog(
            url: request.url?.absoluteString ?? "Unknown",
            method: request.httpMethod ?? "GET",
            timestamp: Date(),
            type: .request
        )
        logs.append(log)
    }
    
    @MainActor
    func logResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        guard DeveloperToolsManager.shared.enableNetworkLogging else { return }
        
        let log = NetworkLog(
            url: response?.url?.absoluteString ?? "Unknown",
            method: "Response",
            timestamp: Date(),
            type: .response,
            error: error?.localizedDescription
        )
        logs.append(log)
    }
    
    func clearLogs() {
        logs.removeAll()
    }
}



// MARK: - Data Models
struct NetworkLog: Identifiable {
    let id = UUID()
    let url: String
    let method: String
    let timestamp: Date
    let type: NetworkLogType
    let error: String?
    
    init(url: String, method: String, timestamp: Date, type: NetworkLogType, error: String? = nil) {
        self.url = url
        self.method = method
        self.timestamp = timestamp
        self.type = type
        self.error = error
    }
}

enum NetworkLogType {
    case request
    case response
}



#endif 
