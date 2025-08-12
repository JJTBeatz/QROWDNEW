import Foundation
import SwiftUI
import Combine

@MainActor
class DJRegistrationViewModel: ObservableObject {
    @Published var currentStep = 1
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingError = false
    @Published var isComplete = false
    
    // Step 1: Basic Info
    @Published var stageName = ""
    @Published var city = ""
    @Published var suggestedCities: [String] = []
    
    // Step 2: Budget
    @Published var budgetMin: Double = 100
    @Published var budgetMax: Double = 1000
    
    // Step 3: Genre & Culture
    @Published var selectedGenres: Set<String> = []
    @Published var selectedCultures: Set<String> = []
    
    // Step 4: Equipment
    @Published var selectedEquipment: Set<String> = []
    
    // Step 5: Promo Media
    @Published var audioPromoData: Data?
    @Published var audioPromoURL: String?
    @Published var videoPromoData: Data?
    @Published var videoPromoURL: String?
    
    // Step 6: Availability
    @Published var availability: [String: [String]] = [:]
    
    // Step 7: Social Links
    @Published var instagramHandle = ""
    @Published var soundcloudURL = ""
    
    // Step 8: Stripe Connect
    @Published var stripeConnectId: String?
    @Published var isStripeConnected = false
    
    private let supabaseManager = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Available Options
    let availableGenres = [
        "House", "Tech House", "Deep House", "Techno", "Progressive",
        "Trance", "EDM", "Hip Hop", "R&B", "Pop", "Latin", "Reggaeton",
        "Afrobeats", "Amapiano", "UK Garage", "Drum & Bass", "Dubstep"
    ]
    
    let availableCultures = [
        "African", "Afrobeats", "Latin", "Caribbean", "Asian", "Middle Eastern",
        "European", "American", "Brazilian", "Mexican", "Indian", "Arabic"
    ]
    
    let availableEquipment = [
        "DJ Controller", "CDJs", "Turntables", "Mixer", "Speakers", 
        "Subwoofer", "Microphone", "LED Lights", "Fog Machine", "Laser Lights"
    ]
    
    let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    let timeSlots = ["6PM-10PM", "10PM-2AM", "2AM-6AM", "All Night"]
    
    init() {
        setupCitySearch()
        initializeAvailability()
    }
    
    // MARK: - Step Validation
    var isCurrentStepValid: Bool {
        switch currentStep {
        case 1: return !stageName.isEmpty && !city.isEmpty
        case 2: return budgetMin < budgetMax
        case 3: return !selectedGenres.isEmpty
        case 4: return !selectedEquipment.isEmpty
        case 5: return true // Optional step
        case 6: return !availability.isEmpty
        case 7: return true // Optional step
        case 8: return true // Optional step for now
        default: return false
        }
    }
    
    // MARK: - Navigation
    func handleNextStep() async {
        if currentStep < 8 {
            withAnimation {
                currentStep += 1
            }
        } else {
            await completeDJRegistration()
        }
    }
    
    // MARK: - City Search
    private func setupCitySearch() {
        $city
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.searchCities(query: searchText)
            }
            .store(in: &cancellables)
    }
    
    private func searchCities(query: String) {
        guard !query.isEmpty else {
            suggestedCities = []
            return
        }
        
        // Mock city suggestions - in real app, use location API
        let cities = [
            "New York, NY", "Los Angeles, CA", "Chicago, IL", "Miami, FL",
            "Las Vegas, NV", "Atlanta, GA", "Houston, TX", "Dallas, TX",
            "Phoenix, AZ", "Philadelphia, PA", "San Antonio, TX", "San Diego, CA",
            "Detroit, MI", "San Jose, CA", "Austin, TX", "Jacksonville, FL"
        ]
        
        suggestedCities = cities.filter { $0.localizedCaseInsensitiveContains(query) }
    }
    
    // MARK: - Availability Management
    private func initializeAvailability() {
        for weekday in weekdays {
            availability[weekday] = []
        }
    }
    
    func toggleAvailability(day: String, timeSlot: String) {
        if availability[day]?.contains(timeSlot) == true {
            availability[day]?.removeAll { $0 == timeSlot }
        } else {
            availability[day]?.append(timeSlot)
        }
    }
    
    func isTimeSlotSelected(day: String, timeSlot: String) -> Bool {
        availability[day]?.contains(timeSlot) ?? false
    }
    
    // MARK: - Media Upload
    func uploadAudioPromo(data: Data) async {
        isLoading = true
        do {
            let fileName = "audio_promo_\(UUID().uuidString).mp3"
            audioPromoURL = try await supabaseManager.uploadFile(data: data, fileName: fileName)
            audioPromoData = data
        } catch {
            errorMessage = "Failed to upload audio: \(error.localizedDescription)"
            showingError = true
        }
        isLoading = false
    }
    
    func uploadVideoPromo(data: Data) async {
        isLoading = true
        do {
            let fileName = "video_promo_\(UUID().uuidString).mp4"
            videoPromoURL = try await supabaseManager.uploadFile(data: data, fileName: fileName)
            videoPromoData = data
        } catch {
            errorMessage = "Failed to upload video: \(error.localizedDescription)"
            showingError = true
        }
        isLoading = false
    }
    
    // MARK: - Stripe Connect
    func connectStripe() async {
        // In a real app, this would integrate with Stripe Connect
        isLoading = true
        
        // Simulate Stripe Connect flow
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.stripeConnectId = "acct_\(UUID().uuidString)"
            self?.isStripeConnected = true
            self?.isLoading = false
        }
    }
    
    // MARK: - Final Registration
    private func completeDJRegistration() async {
        isLoading = true
        
        guard let currentUser = supabaseManager.currentUser else {
            errorMessage = "User not authenticated - please sign in again"
            showingError = true
            isLoading = false
            return
        }
        
        let userId = currentUser.id.uuidString
        print("DEBUG: Creating DJ profile for user ID: \(userId)")
        print("DEBUG: Authentication state: \(supabaseManager.isAuthenticated)")
        
        let djProfile = DJProfile(
            id: nil,
            userId: userId,
            stageName: stageName,
            city: city,
            genres: Array(selectedGenres),
            budgetMin: budgetMin,
            budgetMax: budgetMax,
            equipment: Array(selectedEquipment),
            availability: availability,
            instagramHandle: instagramHandle.isEmpty ? nil : instagramHandle,
            soundcloudUrl: soundcloudURL.isEmpty ? nil : soundcloudURL,
            stripeAccountId: stripeConnectId,
            audioPromoUrl: audioPromoURL,
            videoPromoUrl: videoPromoURL,
            bio: nil,
            profileImageUrl: nil,
            rating: 0.0,
            isPro: false
        )
        
        print("DEBUG: DJ Profile data: \(djProfile)")
        
        do {
            // Try to refresh session first to fix authentication issues
            do {
                try await supabaseManager.refreshSession()
                print("DEBUG: Session refreshed successfully")
            } catch {
                print("DEBUG: Session refresh failed, continuing anyway: \(error)")
            }
            
            // Double check authentication before profile creation
            if !supabaseManager.isAuthenticated {
                throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication expired"])
            }
            
            try await supabaseManager.createDJProfile(djProfile)
            print("DEBUG: DJ profile created successfully")
            await MainActor.run {
                isComplete = true
            }
        } catch {
            print("DEBUG: Error creating DJ profile: \(error)")
            await MainActor.run {
                if error.localizedDescription.contains("row-level security") || 
                   error.localizedDescription.contains("permission") ||
                   error.localizedDescription.contains("policy") {
                    errorMessage = "Database permission error. Please:\n\n1. Sign out and sign back in\n2. Or ask admin to run the database fix\n3. Or try again in a few minutes\n\nError: \(error.localizedDescription)"
                } else {
                    errorMessage = "Failed to save profile: \(error.localizedDescription)"
                }
                showingError = true
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
} 