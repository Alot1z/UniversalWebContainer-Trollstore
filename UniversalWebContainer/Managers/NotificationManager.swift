import Foundation
import UserNotifications
import WebKit

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    func requestPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to request notification permissions: \(error.localizedDescription)"
                } else {
                    self?.isAuthorized = granted
                    self?.checkAuthorizationStatus()
                }
            }
        }
    }
    
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Local Notifications
    func scheduleLocalNotification(
        for webApp: WebApp,
        title: String,
        body: String,
        timeInterval: TimeInterval = 0,
        repeats: Bool = false
    ) {
        guard isAuthorized else {
            errorMessage = "Notification permissions not granted"
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = AppConstants.webAppNotificationCategory
        content.userInfo = [
            "webAppId": webApp.id.uuidString,
            "webAppName": webApp.name,
            "webAppUrl": webApp.url.absoluteString
        ]
        
        let trigger: UNNotificationTrigger
        if timeInterval > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: repeats)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }
        
        let request = UNNotificationRequest(
            identifier: "\(webApp.id.uuidString)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to schedule notification: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func scheduleRepeatingNotification(
        for webApp: WebApp,
        title: String,
        body: String,
        dateComponents: DateComponents
    ) {
        guard isAuthorized else {
            errorMessage = "Notification permissions not granted"
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = AppConstants.webAppNotificationCategory
        content.userInfo = [
            "webAppId": webApp.id.uuidString,
            "webAppName": webApp.name,
            "webAppUrl": webApp.url.absoluteString
        ]
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "\(webApp.id.uuidString)_repeating",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to schedule repeating notification: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func cancelNotifications(for webApp: WebApp) {
        let identifiers = notificationCenter.deliveredNotifications
            .filter { notification in
                notification.request.content.userInfo["webAppId"] as? String == webApp.id.uuidString
            }
            .map { $0.request.identifier }
        
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Web Push Notifications
    func registerForWebPush(for webApp: WebApp) {
        guard isAuthorized else {
            errorMessage = "Notification permissions not granted"
            return
        }
        
        // Request push notification registration
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
        
        // Save webapp for push notifications
        var pushWebApps = getPushWebApps()
        if !pushWebApps.contains(where: { $0.id == webApp.id }) {
            pushWebApps.append(webApp)
            savePushWebApps(pushWebApps)
        }
    }
    
    func unregisterFromWebPush(for webApp: WebApp) {
        var pushWebApps = getPushWebApps()
        pushWebApps.removeAll { $0.id == webApp.id }
        savePushWebApps(pushWebApps)
    }
    
    func handlePushNotification(_ userInfo: [AnyHashable: Any]) {
        guard let webAppIdString = userInfo["webAppId"] as? String,
              let webAppId = UUID(uuidString: webAppIdString) else {
            return
        }
        
        // Handle push notification for specific webapp
        DispatchQueue.main.async {
            // Post notification to app
            NotificationCenter.default.post(
                name: .webAppPushNotificationReceived,
                object: nil,
                userInfo: [
                    "webAppId": webAppId,
                    "userInfo": userInfo
                ]
            )
        }
    }
    
    // MARK: - Notification Categories
    func setupNotificationCategories() {
        let openAction = UNNotificationAction(
            identifier: "OPEN_WEBAPP",
            title: "Open",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: AppConstants.webAppNotificationCategory,
            actions: [openAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([category])
    }
    
    // MARK: - Background App Refresh
    func enableBackgroundAppRefresh() {
        // This would require background modes in Info.plist
        // and proper background task handling
    }
    
    func disableBackgroundAppRefresh() {
        // Disable background refresh
    }
    
    // MARK: - Notification History
    func getDeliveredNotifications() -> [UNNotification] {
        var notifications: [UNNotification] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        notificationCenter.getDeliveredNotifications { deliveredNotifications in
            notifications = deliveredNotifications
            semaphore.signal()
        }
        
        semaphore.wait()
        return notifications
    }
    
    func getPendingNotifications() -> [UNNotificationRequest] {
        var requests: [UNNotificationRequest] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        notificationCenter.getPendingNotificationRequests { pendingRequests in
            requests = pendingRequests
            semaphore.signal()
        }
        
        semaphore.wait()
        return requests
    }
    
    func clearNotificationHistory() {
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    // MARK: - Notification Settings
    func getNotificationSettings() -> UNNotificationSettings? {
        var settings: UNNotificationSettings?
        let semaphore = DispatchSemaphore(value: 0)
        
        notificationCenter.getNotificationSettings { notificationSettings in
            settings = notificationSettings
            semaphore.signal()
        }
        
        semaphore.wait()
        return settings
    }
    
    func updateNotificationSettings(for webApp: WebApp, enabled: Bool) {
        var webAppSettings = getWebAppNotificationSettings()
        webAppSettings[webApp.id.uuidString] = enabled
        saveWebAppNotificationSettings(webAppSettings)
    }
    
    func isNotificationEnabled(for webApp: WebApp) -> Bool {
        let webAppSettings = getWebAppNotificationSettings()
        return webAppSettings[webApp.id.uuidString] ?? true
    }
    
    // MARK: - Badge Management
    func setBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    func clearBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    func incrementBadge() {
        DispatchQueue.main.async {
            let currentBadge = UIApplication.shared.applicationIconBadgeNumber
            UIApplication.shared.applicationIconBadgeNumber = currentBadge + 1
        }
    }
    
    func decrementBadge() {
        DispatchQueue.main.async {
            let currentBadge = UIApplication.shared.applicationIconBadgeNumber
            UIApplication.shared.applicationIconBadgeNumber = max(0, currentBadge - 1)
        }
    }
    
    // MARK: - Private Methods
    private func getPushWebApps() -> [WebApp] {
        guard let data = userDefaults.data(forKey: "push_webapps") else { return [] }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([WebApp].self, from: data)
        } catch {
            return []
        }
    }
    
    private func savePushWebApps(_ webApps: [WebApp]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(webApps)
            userDefaults.set(data, forKey: "push_webapps")
        } catch {
            errorMessage = "Failed to save push webapps: \(error.localizedDescription)"
        }
    }
    
    private func getWebAppNotificationSettings() -> [String: Bool] {
        return userDefaults.dictionary(forKey: "webapp_notification_settings") as? [String: Bool] ?? [:]
    }
    
    private func saveWebAppNotificationSettings(_ settings: [String: Bool]) {
        userDefaults.set(settings, forKey: "webapp_notification_settings")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let webAppPushNotificationReceived = Notification.Name("webAppPushNotificationReceived")
    static let notificationPermissionChanged = Notification.Name("notificationPermissionChanged")
}

// MARK: - Notification Manager Extensions
extension NotificationManager {
    func scheduleTestNotification() {
        let testWebApp = WebApp(name: "Test", url: URL(string: "https://example.com")!)
        scheduleLocalNotification(
            for: testWebApp,
            title: "Test Notification",
            body: "This is a test notification from Universal WebContainer"
        )
    }
    
    func scheduleReminderNotification(
        for webApp: WebApp,
        message: String,
        delay: TimeInterval
    ) {
        scheduleLocalNotification(
            for: webApp,
            title: "Reminder",
            body: message,
            timeInterval: delay,
            repeats: false
        )
    }
    
    func scheduleDailyReminder(
        for webApp: WebApp,
        title: String,
        body: String,
        hour: Int,
        minute: Int
    ) {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        scheduleRepeatingNotification(
            for: webApp,
            title: title,
            body: body,
            dateComponents: dateComponents
        )
    }
}
