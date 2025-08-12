import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    @Published var isRegisteredForRemoteNotifications = false
    
    private override init() {
        super.init()
        checkPermission()
    }
    
    // MARK: - Permission Management
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            hasPermission = granted
            
            if granted {
                await registerForRemoteNotifications()
            }
        } catch {
            print("Failed to request notification permission: \(error)")
        }
    }
    
    private func checkPermission() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            hasPermission = settings.authorizationStatus == .authorized
        }
    }
    
    private func registerForRemoteNotifications() async {
        guard hasPermission else { return }
        
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Ticket Sale Notifications
    func notifyHostOfTicketSale(
        hostId: String,
        eventTitle: String,
        ticketQuantity: Int,
        totalAmount: Double,
        buyerName: String? = nil
    ) async {
        
        // For demo purposes, we'll create a local notification
        // In production, you'd send this via your backend to APNs
        
        let content = UNMutableNotificationContent()
        content.title = "🎟️ Ticket Sale!"
        content.body = "\(ticketQuantity) ticket\(ticketQuantity > 1 ? "s" : "") sold for \(eventTitle)"
        content.subtitle = "You earned $\(String(format: "%.2f", totalAmount * 0.9))" // After platform fee
        content.sound = .default
        content.badge = 1
        
        // Add custom data
        content.userInfo = [
            "type": "ticket_sale",
            "event_title": eventTitle,
            "ticket_quantity": ticketQuantity,
            "total_amount": totalAmount,
            "host_id": hostId
        ]
        
        // Create trigger (immediate for demo)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "ticket_sale_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled ticket sale notification for host: \(hostId)")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    // MARK: - Event Reminder Notifications
    func scheduleEventReminder(
        for event: TrendingEvent,
        userId: String,
        ticketQuantity: Int
    ) async {
        
        let content = UNMutableNotificationContent()
        content.title = "🎪 Event Reminder"
        content.body = "\(event.title) starts in 1 hour!"
        content.subtitle = "Your \(ticketQuantity) ticket\(ticketQuantity > 1 ? "s are" : " is") ready"
        content.sound = .default
        
        content.userInfo = [
            "type": "event_reminder",
            "event_id": event.id,
            "event_title": event.title,
            "user_id": userId
        ]
        
        // Calculate trigger time (1 hour before event)
        let eventTime = event.eventDate
        let reminderTime = Calendar.current.date(byAdding: .hour, value: -1, to: eventTime) ?? eventTime
        
        // Only schedule if event is in the future
        guard reminderTime > Date() else { return }
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "event_reminder_\(event.id)_\(userId)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled event reminder for: \(event.title)")
        } catch {
            print("Failed to schedule event reminder: \(error)")
        }
    }
    
    // MARK: - Marketing Notifications
    func sendTrendingEventsNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Trending Tonight"
        content.body = "Check out the hottest events happening in your area!"
        content.sound = .default
        
        content.userInfo = [
            "type": "trending_events",
            "action": "open_home_tab"
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "trending_events_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule trending events notification: \(error)")
        }
    }
    
    // MARK: - Handle Remote Notifications
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "ticket_sale":
            handleTicketSaleNotification(userInfo)
        case "event_reminder":
            handleEventReminderNotification(userInfo)
        case "trending_events":
            handleTrendingEventsNotification(userInfo)
        default:
            print("Unknown notification type: \(type)")
        }
    }
    
    private func handleTicketSaleNotification(_ userInfo: [AnyHashable: Any]) {
        // Handle ticket sale notification tap
        // Could navigate to earnings/sales dashboard
        print("Handling ticket sale notification: \(userInfo)")
    }
    
    private func handleEventReminderNotification(_ userInfo: [AnyHashable: Any]) {
        // Handle event reminder notification tap
        // Could navigate to user's tickets
        print("Handling event reminder notification: \(userInfo)")
    }
    
    private func handleTrendingEventsNotification(_ userInfo: [AnyHashable: Any]) {
        // Handle trending events notification tap
        // Could navigate to home tab with trending events
        print("Handling trending events notification: \(userInfo)")
    }
    
    // MARK: - Badge Management
    func updateBadgeCount(_ count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
    
    // MARK: - Cleanup
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func removePendingNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleRemoteNotification(response.notification.request.content.userInfo)
        completionHandler()
    }
}

// MARK: - Notification Models
struct TicketSaleNotification {
    let eventTitle: String
    let ticketQuantity: Int
    let totalAmount: Double
    let hostPayout: Double
    let buyerName: String?
    let timestamp: Date
    
    init(eventTitle: String, ticketQuantity: Int, totalAmount: Double, platformFeePercentage: Double, buyerName: String? = nil) {
        self.eventTitle = eventTitle
        self.ticketQuantity = ticketQuantity
        self.totalAmount = totalAmount
        self.hostPayout = totalAmount * (1 - platformFeePercentage / 100)
        self.buyerName = buyerName
        self.timestamp = Date()
    }
}

struct EventReminderNotification {
    let eventId: String
    let eventTitle: String
    let eventTime: Date
    let ticketQuantity: Int
    let venueName: String
    let location: String
} 