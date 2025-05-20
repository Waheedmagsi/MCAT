import Foundation
import Combine
import UIKit

class ProfileViewModel: ObservableObject {
    // User info
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var isPremium: Bool = false
    @Published var subscriptionTier: String = ""
    @Published var renewalDate: String? = nil
    
    // Settings
    @Published var notificationsEnabled: Bool = true
    
    // Alerts
    @Published var showingAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to premium status changes
        PurchaseService.shared.isPremium
            .sink { [weak self] isPremium in
                self?.isPremium = isPremium
                if isPremium {
                    self?.subscriptionTier = "Monthly"
                    
                    // Calculate renewal date (30 days from now for demo)
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .none
                    let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
                    self?.renewalDate = formatter.string(from: futureDate)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadUserProfile() {
        // In a real implementation, this would fetch user data from SupabaseClient
        // For now, use mock data
        userName = "John Smith"
        userEmail = "john.smith@example.com"
        
        // Notification settings would be loaded from UserDefaults in a real app
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }
    
    func toggleNotifications() {
        notificationsEnabled.toggle()
        
        // Save to UserDefaults
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        
        // In a real app, this would register/unregister for push notifications
        if notificationsEnabled {
            registerForNotifications()
        }
    }
    
    func signOut() {
        // Call the router to sign out
        NotificationCenter.default.post(name: .authStateChanged, object: false)
    }
    
    func contactSupport() {
        // In a real app, this would open a support chat or email
        showAlert(title: "Contact Support", message: "Support email: support@mcatprep.com")
    }
    
    func openPrivacyPolicy() {
        // In a real app, this would open a web view or safari
        if let url = URL(string: "https://mcatprep.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    func openTermsOfService() {
        // In a real app, this would open a web view or safari
        if let url = URL(string: "https://mcatprep.com/terms") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Private Helpers
    
    private func registerForNotifications() {
        // In a real app, this would request permission and register for remote notifications
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
} 