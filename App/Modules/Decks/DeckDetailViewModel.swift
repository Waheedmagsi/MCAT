import Foundation
import Combine

class DeckDetailViewModel: ObservableObject {
    // Deck properties
    let deckId: String
    let title: String
    let questionCount: Int
    
    // Details that get loaded
    @Published var description: String = ""
    @Published var conceptName: String?
    @Published var masteryPercentage: Double?
    @Published var lastPracticed: String?
    @Published var questionsAttempted: Int?
    
    // UI state
    @Published var isLoading = false
    @Published var showingQuiz = false
    @Published var showingPremiumAlert = false
    
    private var isPremium: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    init(deck: DeckViewModel) {
        self.deckId = deck.id
        self.title = deck.title
        self.questionCount = deck.questionCount
        self.masteryPercentage = deck.masteryPercentage
        
        // Subscribe to premium status
        PurchaseService.shared.isPremium
            .sink { [weak self] isPremium in
                self?.isPremium = isPremium
            }
            .store(in: &cancellables)
    }
    
    func loadDeckDetails() {
        // In a real app, this would fetch additional details from SupabaseClient
        
        // Simulation for the demo
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            self.description = "This comprehensive deck covers essential concepts in \(self.title). Questions range from foundational principles to advanced applications that frequently appear on the MCAT exam."
            self.conceptName = "General " + self.title
            
            if self.masteryPercentage == nil {
                // If not provided in init, generate random mastery
                self.masteryPercentage = Double.random(in: 0...100)
            }
            
            self.lastPracticed = "3 days ago"
            self.questionsAttempted = Int(Double(self.questionCount) * 0.4)
            
            self.isLoading = false
        }
    }
    
    func startPractice() {
        // Track analytics
        AnalyticsService.shared.trackQuizStarted(deckId: deckId, mode: .deck)
        
        // Start quiz
        showingQuiz = true
    }
    
    func startAdaptiveExam() {
        if isPremium {
            // Track analytics
            AnalyticsService.shared.trackQuizStarted(deckId: deckId, mode: .dailyDrill)
            
            // Start quiz in adaptive mode
            showingQuiz = true
        } else {
            showingPremiumAlert = true
        }
    }
    
    func reviewMistakes() {
        if isPremium {
            // Track analytics
            AnalyticsService.shared.trackQuizStarted(deckId: deckId, mode: .deck)
            
            // Start review mode
            showingQuiz = true
        } else {
            showingPremiumAlert = true
        }
    }
} 