import Foundation
import SwiftUI

@MainActor
class HostSearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var djCards: [DJCard] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filters = DJSearchFilters()
    @Published var selectedDJ: DJCard?
    
    private let supabaseManager = SupabaseManager.shared
    
    // MARK: - Search DJs
    func searchDJs() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let results = try await supabaseManager.searchDJs(filters: filters)
            djCards = results
        } catch {
            errorMessage = "Failed to search DJs: \(error.localizedDescription)"
            print("Error searching DJs: \(error)")
            
            // Load mock data for demo purposes
            djCards = createMockDJCards()
        }
        
        isLoading = false
    }
    
    // MARK: - Apply Filters
    func applyFilters() async {
        await searchDJs()
    }
    
    // MARK: - Clear Filters
    func clearFilters() async {
        filters = DJSearchFilters()
        searchText = ""
        await searchDJs()
    }
    
    // MARK: - Mock Data for Demo
    private func createMockDJCards() -> [DJCard] {
        return [
            DJCard(from: DJCardData(
                id: "1",
                stage_name: "DJ Nebula",
                city: "Los Angeles, CA",
                genres: ["House", "Electronic", "Techno"],
                rating: 4.9,
                budget_min: 200.0,
                promo_media_urls: ["https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500"],
                is_available: true,
                is_pro: true
            )),
            DJCard(from: DJCardData(
                id: "2",
                stage_name: "DJ Phoenix",
                city: "Miami, FL",
                genres: ["House", "Latin", "Pop"],
                rating: 4.8,
                budget_min: 300.0,
                promo_media_urls: ["https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500"],
                is_available: true,
                is_pro: false
            )),
            DJCard(from: DJCardData(
                id: "3",
                stage_name: "DJ Storm",
                city: "Brooklyn, NY",
                genres: ["Hip-Hop", "R&B", "Electronic"],
                rating: 4.7,
                budget_min: 250.0,
                promo_media_urls: ["https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?w=500"],
                is_available: false,
                is_pro: true
            )),
            DJCard(from: DJCardData(
                id: "4",
                stage_name: "DJ Fuego",
                city: "Austin, TX",
                genres: ["Latin", "Reggaeton", "Salsa"],
                rating: 4.6,
                budget_min: 180.0,
                promo_media_urls: ["https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=500"],
                is_available: true,
                is_pro: false
            )),
            DJCard(from: DJCardData(
                id: "5",
                stage_name: "DJ Retro",
                city: "San Francisco, CA",
                genres: ["Rock", "Pop", "Disco"],
                rating: 4.5,
                budget_min: 220.0,
                promo_media_urls: ["https://images.unsplash.com/photo-1556908114-f6e7ad7d3136?w=500"],
                is_available: true,
                is_pro: false
            ))
        ]
    }
}

// MARK: - DJ Search Filters Extension
extension DJSearchFilters {
    var hasActiveFilters: Bool {
        return !city.isEmpty || 
               minBudget != nil || 
               maxBudget != nil || 
               !genres.isEmpty || 
               guestCount != nil || 
               eventDate != nil || 
               availableNow
    }
    
    var activeFilterCount: Int {
        var count = 0
        if !city.isEmpty { count += 1 }
        if minBudget != nil { count += 1 }
        if maxBudget != nil { count += 1 }
        if !genres.isEmpty { count += genres.count }
        if guestCount != nil { count += 1 }
        if eventDate != nil { count += 1 }
        if availableNow { count += 1 }
        return count
    }
} 