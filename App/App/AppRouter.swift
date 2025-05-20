import SwiftUI
import Combine

enum AppTab {
    case decks
    case dailyDrill
    case dashboard
    case profile
}

class AppRouter: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentTab: AppTab = .decks
    @Published var activeFullExam: String? = nil  // Exam ID if one is active
    @Published var showingPremiumUpgrade: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkAuthenticationStatus()
        
        // Listen for auth state changes
        NotificationCenter.default.publisher(for: .authStateChanged)
            .sink { [weak self] notification in
                if let isAuthed = notification.object as? Bool {
                    self?.isAuthenticated = isAuthed
                }
            }
            .store(in: &cancellables)
    }
    
    func signIn(completion: @escaping (Bool) -> Void) {
        // This would call the auth service in a real implementation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isAuthenticated = true
            completion(true)
        }
    }
    
    func signOut() {
        // Call auth service to sign out
        isAuthenticated = false
        // Reset app state
        currentTab = .decks
        activeFullExam = nil
    }
    
    func startFullExam(examId: String) {
        activeFullExam = examId
    }
    
    func endFullExam() {
        activeFullExam = nil
    }
    
    func showPremiumUpgrade() {
        showingPremiumUpgrade = true
    }
    
    private func checkAuthenticationStatus() {
        // Check local storage or keychain for auth token
        // This is a placeholder implementation
        isAuthenticated = false
    }
} 