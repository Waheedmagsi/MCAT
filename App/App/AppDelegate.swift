import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize services
        setupServices()
        
        // Configure Supabase (uncomment and insert your actual API key)
        // configureSupabase(apiKey: "your-anon-public-api-key")
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Handle push notification registration
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for notifications: \(error)")
    }
    
    private func setupServices() {
        // Initialize core services
        _ = SupabaseClient.shared
        _ = OfflineStore.shared
        _ = AnalyticsService.shared
        _ = PurchaseService.shared
    }
    
    /// Configures Supabase client with the provided API key
    private func configureSupabase(apiKey: String) {
        SupabaseClient.shared.storeAPIKey(apiKey)
        
        // You can optionally set the environment here for testing
        // ConfigurationManager.shared.setEnvironment("development")
    }
} 