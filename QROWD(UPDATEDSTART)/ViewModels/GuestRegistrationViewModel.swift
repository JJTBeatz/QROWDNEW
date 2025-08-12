import Foundation
import SwiftUI

@MainActor
class GuestRegistrationViewModel: ObservableObject {
    @Published var registrationData = GuestRegistrationData()
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingError = false
    @Published var skipProfile = false
    
    private let supabaseManager = SupabaseManager.shared
    
    // MARK: - Form Validation
    var hasAnyData: Bool {
        !registrationData.firstName.isEmpty ||
        !registrationData.lastName.isEmpty ||
        !registrationData.city.isEmpty ||
        !registrationData.preferredGenres.isEmpty ||
        !registrationData.instagramHandle.isEmpty
    }
    
    // MARK: - Genre Methods
    func toggleGenre(_ genre: String) {
        if registrationData.preferredGenres.contains(genre) {
            registrationData.preferredGenres.removeAll { $0 == genre }
        } else {
            registrationData.preferredGenres.append(genre)
        }
    }
    
    func isGenreSelected(_ genre: String) -> Bool {
        registrationData.preferredGenres.contains(genre)
    }
    
    // MARK: - Registration Methods
    func createGuestProfile() async {
        guard let userId = supabaseManager.currentUser?.id.uuidString else {
            await showError("User not authenticated")
            return
        }
        
        isLoading = true
        
        do {
            // Only create guest profile if user provided some data
            if hasAnyData {
                let guestProfile = GuestProfile(
                    userId: userId,
                    firstName: registrationData.firstName.isEmpty ? nil : registrationData.firstName,
                    lastName: registrationData.lastName.isEmpty ? nil : registrationData.lastName,
                    city: registrationData.city.isEmpty ? nil : registrationData.city,
                    preferredGenres: registrationData.preferredGenres,
                    instagramHandle: registrationData.instagramHandle
                )
                
                try await supabaseManager.createGuestProfile(guestProfile)
            }
            
            // Update user profile type to guest
            try await supabaseManager.updateUserProfileType(userId: userId, userType: "guest")
            
            isLoading = false
            
        } catch {
            await showError(error.localizedDescription)
        }
    }
    
    func skipProfileCreation() async {
        guard let userId = supabaseManager.currentUser?.id.uuidString else {
            await showError("User not authenticated")
            return
        }
        
        isLoading = true
        
        do {
            // Just update user profile type to guest without creating detailed profile
            try await supabaseManager.updateUserProfileType(userId: userId, userType: "guest")
            isLoading = false
        } catch {
            await showError(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    private func showError(_ message: String) async {
        errorMessage = message
        showingError = true
        isLoading = false
    }
    
    func resetForm() {
        registrationData = GuestRegistrationData()
        errorMessage = ""
        showingError = false
        isLoading = false
        skipProfile = false
    }
}

// MARK: - Available Options
extension GuestRegistrationViewModel {
    var availableGenres: [String] {
        [
            "Electronic", "Hip-Hop", "Pop", "R&B", "Rock",
            "Jazz", "Classical", "Country", "Reggae", "Latin",
            "House", "Techno", "Trance", "Dubstep", "Funk",
            "Soul", "Blues", "Alternative", "Indie", "World"
        ]
    }
} 