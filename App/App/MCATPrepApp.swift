import SwiftUI
import Combine

@main
struct MCATPrepApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appRouter = AppRouter()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if appRouter.isAuthenticated {
                    MainCoordinator(router: appRouter)
                } else {
                    AuthenticationCoordinator(router: appRouter)
                }
            }
            .environmentObject(appRouter)
            .onAppear {
                setupAppearance()
            }
        }
    }
    
    private func setupAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
} 