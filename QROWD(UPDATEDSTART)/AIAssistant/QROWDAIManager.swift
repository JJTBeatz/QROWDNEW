import Foundation
import Combine

// MARK: - QROWD AI Manager
@MainActor
class QROWDAIManager: ObservableObject {
    static let shared = QROWDAIManager()
    
    // Remove hardcoded API key - use environment variable or config
    private var openAIAPIKey: String? {
        // Try to get from environment or config
        // For now, return nil to use mock responses
        return nil
    }
    
    private let openAIBaseURL = "https://api.openai.com/v1/chat/completions"
    private let supabase = SupabaseManager.shared
    
    @Published var isProcessing = false
    @Published var lastError: String?
    
    private init() {}
    
    // MARK: - AI Query Processing
    func processUserQuery(_ query: String) async -> AIAssistantResponse {
        isProcessing = true
        lastError = nil
        
        do {
            // Store query in Supabase for analytics (if user is authenticated)
            if supabase.isAuthenticated {
                try await storeAIQuery(query: query)
            }
            
            // Parse query intent
            let intent = parseQueryIntent(query)
            
            // Get contextual data based on intent
            let contextData = try await getContextualData(for: intent)
            
            // Generate AI response
            let response = await generateAIResponse(
                query: query,
                intent: intent,
                contextData: contextData
            )
            
            isProcessing = false
            return response
            
        } catch {
            print("DEBUG: AI Error - \(error)")
            isProcessing = false
            lastError = error.localizedDescription
            return createFallbackResponse(for: query)
        }
    }
    
    // MARK: - Query Intent Parsing (Local)
    private func parseQueryIntent(_ query: String) -> AIQueryIntent {
        let lowercaseQuery = query.lowercased()
        
        // Simple keyword-based intent detection
        if lowercaseQuery.contains("dj") || lowercaseQuery.contains("music") || lowercaseQuery.contains("artist") {
            return .djSearch
        } else if lowercaseQuery.contains("venue") || lowercaseQuery.contains("location") || lowercaseQuery.contains("place") {
            return .venueSearch
        } else if lowercaseQuery.contains("event") || lowercaseQuery.contains("party") || lowercaseQuery.contains("show") {
            return .eventSearch
        } else if lowercaseQuery.contains("trend") || lowercaseQuery.contains("popular") || lowercaseQuery.contains("hot") {
            return .trending
        } else {
            return .general
        }
    }
    
    // MARK: - Contextual Data Retrieval
    private func getContextualData(for intent: AIQueryIntent) async throws -> [String: Any] {
        var contextData: [String: Any] = [:]
        
        // Only try to get real data if user is authenticated
        guard supabase.isAuthenticated else {
            return getMockContextData(for: intent)
        }
        
        do {
            switch intent {
            case .djSearch, .trending:
                // Try to get trending DJs
                let trendingDJs = try await supabase.getTrendingDJs()
                contextData["trending_djs"] = trendingDJs
                
            case .venueSearch:
                // Get popular venues (mock for now)
                contextData["popular_venues"] = getMockVenues()
                
            case .eventSearch:
                // Get upcoming events (mock for now)
                contextData["upcoming_events"] = getMockEvents()
                
            case .general:
                // Get general app stats
                contextData["total_djs"] = try await supabase.getTotalDJCount()
                contextData["total_bookings"] = 0 // Default fallback
            }
        } catch {
            print("DEBUG: Failed to get real data, using mock data: \(error)")
            return getMockContextData(for: intent)
        }
        
        return contextData
    }
    
    // MARK: - Mock Data for Development
    private func getMockContextData(for intent: AIQueryIntent) -> [String: Any] {
        switch intent {
        case .djSearch, .trending:
            return ["trending_djs": getMockDJs()]
        case .venueSearch:
            return ["popular_venues": getMockVenues()]
        case .eventSearch:
            return ["upcoming_events": getMockEvents()]
        case .general:
            return ["total_djs": 50, "total_bookings": 125]
        }
    }
    
    private func getMockDJs() -> [[String: Any]] {
        return [
            ["id": "1", "stage_name": "DJ Phoenix", "genres": ["House", "Tech House"], "rating": 4.8, "budget_min": 200],
            ["id": "2", "stage_name": "Beat Master", "genres": ["Hip Hop", "R&B"], "rating": 4.9, "budget_min": 250],
            ["id": "3", "stage_name": "Sonic Wave", "genres": ["EDM", "Trance"], "rating": 4.7, "budget_min": 300]
        ]
    }
    
    private func getMockVenues() -> [[String: Any]] {
        return [
            ["id": "1", "name": "Skyline Rooftop", "location": "Downtown LA", "capacity": 200],
            ["id": "2", "name": "Club Neon", "location": "Hollywood", "capacity": 500],
            ["id": "3", "name": "The Underground", "location": "West Hollywood", "capacity": 150]
        ]
    }
    
    private func getMockEvents() -> [[String: Any]] {
        return [
            ["id": "1", "name": "House Music Night", "date": "This Friday", "venue": "Club Neon"],
            ["id": "2", "name": "Rooftop Summer Party", "date": "This Saturday", "venue": "Skyline Rooftop"],
            ["id": "3", "name": "Underground Techno", "date": "Next Friday", "venue": "The Underground"]
        ]
    }
    
    // MARK: - AI Response Generation
    private func generateAIResponse(
        query: String,
        intent: AIQueryIntent,
        contextData: [String: Any]
    ) async -> AIAssistantResponse {
        
        // Try OpenAI if API key is available
        if let apiKey = openAIAPIKey, !apiKey.isEmpty {
            do {
                let contextString = formatContextData(contextData)
                let prompt = createPrompt(query: query, intent: intent, contextString: contextString)
                let aiMessage = try await callOpenAI(prompt: prompt, maxTokens: 300)
                
                return AIAssistantResponse(
                    message: aiMessage,
                    intent: intent,
                    suggestions: generateSuggestions(for: intent),
                    djRecommendations: extractDJRecommendations(from: contextData),
                    venueRecommendations: extractVenueRecommendations(from: contextData)
                )
            } catch {
                print("DEBUG: OpenAI API failed, using fallback: \(error)")
            }
        }
        
        // Fallback to local response generation
        return generateLocalResponse(query: query, intent: intent, contextData: contextData)
    }
    
    // MARK: - Local Response Generation (Fallback)
    private func generateLocalResponse(
        query: String,
        intent: AIQueryIntent,
        contextData: [String: Any]
    ) -> AIAssistantResponse {
        
        let message = generateLocalMessage(for: intent, query: query, contextData: contextData)
        
        return AIAssistantResponse(
            message: message,
            intent: intent,
            suggestions: generateSuggestions(for: intent),
            djRecommendations: extractDJRecommendations(from: contextData),
            venueRecommendations: extractVenueRecommendations(from: contextData)
        )
    }
    
    private func generateLocalMessage(for intent: AIQueryIntent, query: String, contextData: [String: Any]) -> String {
        switch intent {
        case .djSearch:
            let djCount = (contextData["trending_djs"] as? [[String: Any]])?.count ?? 0
            return "I found \(djCount) DJs that might be perfect for your event! Check out the recommendations below. Each DJ has been vetted and has great reviews from previous bookings."
            
        case .venueSearch:
            let venueCount = (contextData["popular_venues"] as? [[String: Any]])?.count ?? 0
            return "I've found \(venueCount) amazing venues for you! These are some of the most popular spots in the area, perfect for hosting memorable events."
            
        case .eventSearch:
            let eventCount = (contextData["upcoming_events"] as? [[String: Any]])?.count ?? 0
            return "There are \(eventCount) exciting events coming up! These events feature top DJs and are happening at some of the best venues in the city."
            
        case .trending:
            return "Right now, House and Tech House music are really popular! I'm seeing a lot of bookings for rooftop parties and club events. The DJ recommendations below are currently trending."
            
        case .general:
            let djCount = contextData["total_djs"] as? Int ?? 0
            return "Welcome to QROWD! We have \(djCount) talented DJs ready to make your event unforgettable. I can help you find the perfect DJ, venue, or answer any questions about planning your event. What would you like to know?"
        }
    }
    
    // MARK: - Fallback Response
    private func createFallbackResponse(for query: String) -> AIAssistantResponse {
        return AIAssistantResponse(
            message: "I'm here to help you find amazing DJs and venues! While I'm currently having some technical difficulties, I can still provide you with recommendations. Try asking me about DJs, venues, or events in your area.",
            intent: .general,
            suggestions: [
                "Show me popular DJs",
                "Find venues in my area",
                "What events are happening?",
                "Help me plan my event"
            ],
            djRecommendations: [],
            venueRecommendations: []
        )
    }
    
    // MARK: - OpenAI API Call (If Available)
    private func callOpenAI(prompt: String, maxTokens: Int = 150) async throws -> String {
        guard let apiKey = openAIAPIKey, !apiKey.isEmpty else {
            throw AIError.apiKeyMissing
        }
        
        guard let url = URL(string: openAIBaseURL) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = OpenAIRequest(
            model: "gpt-3.5-turbo",
            messages: [
                OpenAIMessage(role: "user", content: prompt)
            ],
            max_tokens: maxTokens,
            temperature: 0.7
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw AIError.noResponse
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let message = openAIResponse.choices.first?.message.content else {
            throw AIError.noResponse
        }
        
        return message
    }
    
    private func createPrompt(query: String, intent: AIQueryIntent, contextString: String) -> String {
        return """
        You are QROWD AI, a helpful assistant for a DJ booking platform. Respond naturally and helpfully.
        
        User Query: "\(query)"
        Intent: \(intent.rawValue)
        
        Available Context Data:
        \(contextString)
        
        Instructions:
        - Be friendly, helpful, and knowledgeable about DJ/event booking
        - Use the context data to provide specific recommendations
        - Keep responses concise but informative
        - If recommending DJs/venues, mention specific names from the context
        - Always end with a helpful suggestion or question to continue the conversation
        
        Respond in a conversational, helpful tone as if you're a knowledgeable event booking expert.
        """
    }
    
    // MARK: - Helper Methods
    private func storeAIQuery(query: String) async throws {
        guard let userId = supabase.currentUser?.id else { return }
        
        let queryData = AIQueryInsertData(
            user_id: userId.uuidString,
            query: query,
            created_at: Date().ISO8601Format()
        )
        
        try await supabase.client
            .from("ai_queries")
            .insert(queryData)
            .execute()
    }
    
    private func formatContextData(_ contextData: [String: Any]) -> String {
        var formatted = ""
        
        for (key, value) in contextData {
            formatted += "\(key): \(value)\n"
        }
        
        return formatted.isEmpty ? "No specific context available" : formatted
    }
    
    private func extractDJRecommendations(from contextData: [String: Any]) -> [DJRecommendation] {
        guard let djsData = contextData["trending_djs"] as? [[String: Any]] else { return [] }
        
        return djsData.prefix(3).compactMap { djData in
            guard let id = djData["id"] as? String,
                  let stageName = djData["stage_name"] as? String,
                  let genres = djData["genres"] as? [String],
                  let rating = djData["rating"] as? Double,
                  let priceMin = djData["budget_min"] as? Double else { return nil }
            
            return DJRecommendation(
                id: id,
                stageName: stageName,
                genres: genres,
                rating: rating,
                priceRange: "$\(Int(priceMin))+/hr"
            )
        }
    }
    
    private func extractVenueRecommendations(from contextData: [String: Any]) -> [VenueRecommendation] {
        guard let venuesData = contextData["popular_venues"] as? [[String: Any]] else { return [] }
        
        return venuesData.prefix(3).compactMap { venueData in
            guard let id = venueData["id"] as? String,
                  let name = venueData["name"] as? String,
                  let location = venueData["location"] as? String,
                  let capacity = venueData["capacity"] as? Int else { return nil }
            
            return VenueRecommendation(
                id: id,
                name: name,
                location: location,
                capacity: capacity
            )
        }
    }
    
    private func generateSuggestions(for intent: AIQueryIntent) -> [String] {
        switch intent {
        case .djSearch:
            return [
                "Show me House DJs in Los Angeles",
                "Find Hip-Hop DJs under $200",
                "Recommend DJs for a wedding"
            ]
        case .venueSearch:
            return [
                "Show rooftop venues in Miami",
                "Find venues for 100+ people",
                "Recommend nightclub venues"
            ]
        case .eventSearch:
            return [
                "What events are happening this weekend?",
                "Show me upcoming House music events",
                "Find events near me"
            ]
        case .trending:
            return [
                "What DJs are popular right now?",
                "Show trending music genres",
                "What's hot in nightlife?"
            ]
        case .general:
            return [
                "How do I book a DJ?",
                "What's included in a booking?",
                "Tell me about QROWD"
            ]
        }
    }
}

// MARK: - Data Models
enum AIQueryIntent: String, CaseIterable {
    case djSearch = "dj_search"
    case venueSearch = "venue_search"
    case eventSearch = "event_search"
    case trending = "trending"
    case general = "general"
    
    static func fromString(_ string: String) -> AIQueryIntent {
        return AIQueryIntent(rawValue: string.lowercased()) ?? .general
    }
}

struct AIAssistantResponse {
    let message: String
    let intent: AIQueryIntent
    let suggestions: [String]
    let djRecommendations: [DJRecommendation]
    let venueRecommendations: [VenueRecommendation]
}

struct DJRecommendation: Identifiable {
    let id: String
    let stageName: String
    let genres: [String]
    let rating: Double
    let priceRange: String
}

struct VenueRecommendation: Identifiable {
    let id: String
    let name: String
    let location: String
    let capacity: Int
}

// MARK: - OpenAI API Models
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let max_tokens: Int
    let temperature: Double
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

// MARK: - Supabase Insert Models
struct AIQueryInsertData: Codable {
    let user_id: String
    let query: String
    let created_at: String
}

// MARK: - Errors
enum AIError: Error, LocalizedError {
    case invalidURL
    case noResponse
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noResponse:
            return "No response from AI service"
        case .apiKeyMissing:
            return "OpenAI API key is missing"
        }
    }
} 
