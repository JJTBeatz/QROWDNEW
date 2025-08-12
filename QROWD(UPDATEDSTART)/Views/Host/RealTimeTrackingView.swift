import SwiftUI
import MapKit
import CoreLocation

struct RealTimeTrackingView: View {
    let bookingId: String
    @StateObject private var trackingManager = DJTrackingManager.shared
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var djLocation: DJLocation?
    @State private var showingDJDetails = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Map View
            Map(coordinateRegion: $region, annotationItems: mapAnnotations) { annotation in
                MapPin(coordinate: annotation.coordinate, tint: annotation.pinColor)
            }
            .ignoresSafeArea()
            
            // Top Status Bar
            VStack {
                DJStatusBar(djLocation: djLocation)
                Spacer()
            }
            
            // Bottom Info Panel
            VStack {
                Spacer()
                DJInfoPanel(
                    djLocation: djLocation,
                    onDetailsPressed: { showingDJDetails = true }
                )
            }
            
            // Navigation Controls
            VStack {
                HStack {
                    NavigationButton(
                        icon: "xmark",
                        action: { dismiss() }
                    )
                    
                    Spacer()
                    
                    NavigationButton(
                        icon: "location.fill",
                        action: centerOnUser
                    )
                    
                    NavigationButton(
                        icon: "phone.fill",
                        action: callDJ
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingDJDetails) {
            if let djLocation = djLocation {
                DJDetailsSheet(djLocation: djLocation)
            }
        }
        .onAppear {
            startTracking()
        }
        .onReceive(trackingManager.$activeDJLocations) { locations in
            updateDJLocation(from: locations)
        }
    }
    
    private var mapAnnotations: [MapAnnotation] {
        var annotations: [MapAnnotation] = []
        
        // Add user location
        if let userLocation = locationManager.location {
            annotations.append(MapAnnotation(
                coordinate: userLocation.coordinate,
                type: .user,
                isAnimated: false
            ))
        }
        
        // Add DJ location
        if let djLocation = djLocation {
            annotations.append(MapAnnotation(
                coordinate: djLocation.coordinate,
                type: .dj(djLocation.status),
                isAnimated: true
            ))
        }
        
        return annotations
    }
    
    private func startTracking() {
        trackingManager.startTrackingDJ(djId: "dj123", bookingId: bookingId)
        locationManager.requestLocation()
        
        // Simulate DJ movement for demo
        simulateDJMovement()
    }
    
    private func updateDJLocation(from locations: [String: DJLocation]) {
        if let location = locations.values.first {
            djLocation = location
            
            // Update map region to show both user and DJ
            updateMapRegion()
        }
    }
    
    private func updateMapRegion() {
        guard let djLocation = djLocation,
              let userLocation = locationManager.location else { return }
        
        let locations = [
            djLocation.coordinate,
            userLocation.coordinate
        ]
        
        let maxLat = locations.map(\.latitude).max() ?? 0
        let minLat = locations.map(\.latitude).min() ?? 0
        let maxLon = locations.map(\.longitude).max() ?? 0
        let minLon = locations.map(\.longitude).min() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (maxLat + minLat) / 2,
            longitude: (maxLon + minLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: abs(maxLat - minLat) * 1.5,
            longitudeDelta: abs(maxLon - minLon) * 1.5
        )
        
        withAnimation(.easeInOut(duration: 1.0)) {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
    
    private func centerOnUser() {
        if let userLocation = locationManager.location {
            withAnimation(.easeInOut(duration: 0.5)) {
                region.center = userLocation.coordinate
            }
        }
    }
    
    private func callDJ() {
        // Implement call DJ functionality
        if let url = URL(string: "tel://+1234567890") {
            UIApplication.shared.open(url)
        }
    }
    
    private func simulateDJMovement() {
        // Simulate DJ movement for demo purposes
        let startLocation = CLLocation(latitude: 34.0622, longitude: -118.2537)
        trackingManager.updateDJLocation(
            djId: "dj123",
            location: startLocation,
            status: .preparing
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            let enRouteLocation = CLLocation(latitude: 34.0572, longitude: -118.2487)
            trackingManager.updateDJLocation(
                djId: "dj123",
                location: enRouteLocation,
                status: .enRoute
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            let nearbyLocation = CLLocation(latitude: 34.0532, longitude: -118.2447)
            trackingManager.updateDJLocation(
                djId: "dj123",
                location: nearbyLocation,
                status: .nearby
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
            let arrivedLocation = CLLocation(latitude: 34.0522, longitude: -118.2437)
            trackingManager.updateDJLocation(
                djId: "dj123",
                location: arrivedLocation,
                status: .arrived
            )
        }
    }
}

// MARK: - Supporting Views

struct DJStatusBar: View {
    let djLocation: DJLocation?
    
    var body: some View {
        if let djLocation = djLocation {
            VStack(spacing: 4) {
                HStack {
                    DJStatusIndicator(status: djLocation.status)
                    
                    Text(djLocation.status.description)
                        .font(QROWDTheme.bodyFont.weight(.semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if let eta = djLocation.estimatedArrival {
                        Text("ETA: \(formatETA(eta))")
                            .font(QROWDTheme.captionFont.weight(.medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(statusColor(djLocation.status))
                        .shadow(radius: 4)
                )
                .padding(.horizontal, 20)
            }
            .padding(.top, 100)
        }
    }
    
    private func statusColor(_ status: DJTravelStatus) -> Color {
        switch status {
        case .preparing: return .orange
        case .enRoute: return .blue
        case .nearby: return .purple
        case .arrived: return .green
        }
    }
    
    private func formatETA(_ eta: TimeInterval) -> String {
        let minutes = Int(eta / 60)
        return "\(minutes) min"
    }
}

struct DJStatusIndicator: View {
    let status: DJTravelStatus
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: 12, height: 12)
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .opacity(isAnimating ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

struct DJInfoPanel: View {
    let djLocation: DJLocation?
    let onDetailsPressed: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    // DJ Avatar
                    AsyncImage(url: URL(string: "https://example.com/dj-avatar.jpg")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(QROWDTheme.accentColor.opacity(0.3))
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(QROWDTheme.accentColor)
                            )
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DJ Phoenix")
                            .font(QROWDTheme.bodyFont.weight(.semibold))
                            .foregroundColor(QROWDTheme.primaryText)
                        
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text("4.8")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                            
                            Text("• House, Tech House")
                                .font(QROWDTheme.captionFont)
                                .foregroundColor(QROWDTheme.secondaryText)
                        }
                        
                        if let djLocation = djLocation, let eta = djLocation.estimatedArrival {
                            Text("Arriving in \(formatETA(eta))")
                                .font(QROWDTheme.captionFont.weight(.medium))
                                .foregroundColor(QROWDTheme.accentColor)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: onDetailsPressed) {
                        Image(systemName: "chevron.up")
                            .foregroundColor(QROWDTheme.secondaryText)
                    }
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    TrackingActionButton(
                        icon: "message.fill",
                        title: "Message",
                        action: {}
                    )
                    
                    TrackingActionButton(
                        icon: "phone.fill",
                        title: "Call",
                        action: {}
                    )
                    
                    TrackingActionButton(
                        icon: "exclamationmark.triangle.fill",
                        title: "Cancel",
                        action: {},
                        isDestructive: true
                    )
                }
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(QROWDTheme.cardBackground)
                .shadow(radius: 10)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    private func formatETA(_ eta: TimeInterval) -> String {
        let minutes = Int(eta / 60)
        return "\(minutes) minutes"
    }
}

struct TrackingActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    let isDestructive: Bool
    
    init(icon: String, title: String, action: @escaping () -> Void, isDestructive: Bool = false) {
        self.icon = icon
        self.title = title
        self.action = action
        self.isDestructive = isDestructive
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDestructive ? .red : QROWDTheme.accentColor)
                
                Text(title)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(isDestructive ? .red : QROWDTheme.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDestructive ? Color.red.opacity(0.1) : Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isDestructive ? Color.red.opacity(0.3) : QROWDTheme.borderColor, lineWidth: 1)
                    )
            )
        }
    }
}

struct NavigationButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.black.opacity(0.6))
                )
        }
    }
}

struct MapPinView: View {
    let type: MapPinType
    let isAnimated: Bool
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(pinColor.opacity(0.3))
                .frame(width: 40, height: 40)
                .scaleEffect(scale)
            
            Circle()
                .fill(pinColor)
                .frame(width: 20, height: 20)
            
            Image(systemName: pinIcon)
                .foregroundColor(.white)
                .font(.caption.weight(.bold))
        }
        .onAppear {
            if isAnimated {
                withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                    scale = 1.5
                }
            }
        }
    }
    
    private var pinColor: Color {
        switch type {
        case .user: return .blue
        case .dj(.preparing): return .orange
        case .dj(.enRoute): return .blue
        case .dj(.nearby): return .purple
        case .dj(.arrived): return .green
        }
    }
    
    private var pinIcon: String {
        switch type {
        case .user: return "person.fill"
        case .dj: return "music.note"
        }
    }
}

struct DJDetailsSheet: View {
    let djLocation: DJLocation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // DJ Profile
                VStack(spacing: 12) {
                    AsyncImage(url: URL(string: "https://example.com/dj-avatar.jpg")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(QROWDTheme.accentColor.opacity(0.3))
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(QROWDTheme.accentColor)
                                    .font(.title)
                            )
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    
                    Text("DJ Phoenix")
                        .font(QROWDTheme.headlineFont)
                        .foregroundColor(QROWDTheme.primaryText)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("4.8 Rating")
                            .font(QROWDTheme.bodyFont)
                            .foregroundColor(QROWDTheme.secondaryText)
                    }
                }
                
                // Status Info
                VStack(spacing: 16) {
                    InfoRow(
                        title: "Current Status",
                        value: djLocation.status.description,
                        icon: "info.circle.fill"
                    )
                    
                    if let eta = djLocation.estimatedArrival {
                        InfoRow(
                            title: "Estimated Arrival",
                            value: formatETA(eta),
                            icon: "clock.fill"
                        )
                    }
                    
                    InfoRow(
                        title: "Last Updated",
                        value: formatTime(djLocation.lastUpdated),
                        icon: "location.fill"
                    )
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("DJ Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func formatETA(_ eta: TimeInterval) -> String {
        let minutes = Int(eta / 60)
        return "\(minutes) minutes"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(QROWDTheme.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(QROWDTheme.captionFont)
                    .foregroundColor(QROWDTheme.secondaryText)
                
                Text(value)
                    .font(QROWDTheme.bodyFont.weight(.medium))
                    .foregroundColor(QROWDTheme.primaryText)
            }
            
            Spacer()
        }
        .padding(16)
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

// MARK: - Supporting Types

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: MapPinType
    let isAnimated: Bool
    
    var pinColor: Color {
        switch type {
        case .user: return .blue
        case .dj(.preparing): return .orange
        case .dj(.enRoute): return .blue
        case .dj(.nearby): return .purple
        case .dj(.arrived): return .green
        }
    }
}

enum MapPinType {
    case user
    case dj(DJTravelStatus)
}

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}

#Preview {
    RealTimeTrackingView(bookingId: "test123")
} 