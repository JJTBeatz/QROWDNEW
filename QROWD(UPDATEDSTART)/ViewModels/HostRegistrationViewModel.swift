import Foundation
import SwiftUI

@MainActor
class HostRegistrationViewModel: ObservableObject {
    @Published var registrationData = HostRegistrationData()
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingError = false
    @Published var currentStep = 1
    
    private let supabaseManager = SupabaseManager.shared
    private let totalSteps = 4
    
    // MARK: - Form Validation
    var canProceedToNextStep: Bool {
        switch currentStep {
        case 1:
            return !registrationData.firstName.isEmpty &&
                   !registrationData.lastName.isEmpty &&
                   !registrationData.city.isEmpty
        case 2:
            return !registrationData.preferredGenres.isEmpty
        case 3:
            return !registrationData.typicalEventTypes.isEmpty &&
                   !registrationData.typicalBudgetRange.isEmpty
        case 4:
            return true // Optional fields
        default:
            return false
        }
    }
    
    var canComplete: Bool {
        registrationData.isValid
    }
    
    var progressPercentage: Double {
        Double(currentStep) / Double(totalSteps)
    }
    
    // MARK: - Navigation Methods
    func nextStep() {
        guard canProceedToNextStep else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep < totalSteps {
                currentStep += 1
            }
        }
    }
    
    func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep > 1 {
                currentStep -= 1
            }
        }
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
    
    // MARK: - Event Type Methods
    func toggleEventType(_ eventType: String) {
        if registrationData.typicalEventTypes.contains(eventType) {
            registrationData.typicalEventTypes.removeAll { $0 == eventType }
        } else {
            registrationData.typicalEventTypes.append(eventType)
        }
    }
    
    func isEventTypeSelected(_ eventType: String) -> Bool {
        registrationData.typicalEventTypes.contains(eventType)
    }
    
    // MARK: - Budget Range Methods
    func selectBudgetRange(_ range: String) {
        registrationData.typicalBudgetRange = range
    }
    
    func isBudgetRangeSelected(_ range: String) -> Bool {
        registrationData.typicalBudgetRange == range
    }
    
    // MARK: - Registration Methods
    func createHostProfile() async {
        guard let userId = supabaseManager.currentUser?.id.uuidString else {
            await showError("User not authenticated")
            return
        }
        
        isLoading = true
        
        do {
            // Create host profile
            let hostProfile = HostProfile(
                userId: userId,
                firstName: registrationData.firstName,
                lastName: registrationData.lastName,
                companyName: registrationData.companyName.isEmpty ? nil : registrationData.companyName,
                phoneNumber: registrationData.phoneNumber.isEmpty ? nil : registrationData.phoneNumber,
                city: registrationData.city,
                preferredGenres: registrationData.preferredGenres,
                typicalEventTypes: registrationData.typicalEventTypes,
                typicalBudgetRange: registrationData.typicalBudgetRange,
                instagramHandle: registrationData.instagramHandle,
                websiteUrl: registrationData.websiteUrl
            )
            
            try await supabaseManager.createHostProfile(hostProfile)
            
            // Update user profile type
            try await supabaseManager.updateUserProfileType(userId: userId, userType: "host")
            
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
        registrationData = HostRegistrationData()
        currentStep = 1
        errorMessage = ""
        showingError = false
        isLoading = false
    }
}

// MARK: - Available Options
extension HostRegistrationViewModel {
    var availableGenres: [String] {
        [
            "Electronic", "Hip-Hop", "Pop", "R&B", "Rock",
            "Jazz", "Classical", "Country", "Reggae", "Latin",
            "House", "Techno", "Trance", "Dubstep", "Funk",
            "Soul", "Blues", "Alternative", "Indie", "World"
        ]
    }
} 