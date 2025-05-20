import Foundation
import Combine
import MBFoundation

class DeckListViewModel: ObservableObject {
    @Published var decks: [DeckViewModel] = []
    @Published var filteredDecks: [DeckViewModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for sync events to refresh decks
        NotificationCenter.default.publisher(for: .syncCompleted)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshDecks()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadDecks() {
        if decks.isEmpty && !isLoading {
            Task { @MainActor in
                await refreshDecks()
            }
        }
    }
    
    @MainActor
    func refreshDecks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Check for cached decks first when offline
            let isOnline = SupabaseClient.shared.isConnected.value
            
            if !isOnline {
                // Fetch from cache
                // Implementation would load from OfflineStore
                simulateLoadingDecks()
                return
            }
            
            // Fetch from API
            try await fetchDecksFromAPI()
        } catch {
            errorMessage = "Failed to load decks: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func filterDecks(with searchText: String) {
        if searchText.isEmpty {
            filteredDecks = decks
        } else {
            filteredDecks = decks.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    // MARK: - API & Data Handling
    
    private func fetchDecksFromAPI() async throws {
        // In real implementation, this would call SupabaseClient
        // For now, we'll just simulate API loading
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        simulateLoadingDecks()
    }
    
    private func simulateLoadingDecks() {
        // Generate mock data
        let mockDecks = [
            DeckViewModel(id: "deck1", title: "Biology Foundations", questionCount: 50, masteryPercentage: 78),
            DeckViewModel(id: "deck2", title: "Organic Chemistry", questionCount: 75, masteryPercentage: 45),
            DeckViewModel(id: "deck3", title: "Physics Principles", questionCount: 60, masteryPercentage: 32),
            DeckViewModel(id: "deck4", title: "CARS Practice", questionCount: 80, masteryPercentage: 65),
            DeckViewModel(id: "deck5", title: "Biochemistry", questionCount: 70, masteryPercentage: 55)
        ]
        
        // Update the main decks array and filtered array
        self.decks = mockDecks
        self.filteredDecks = mockDecks
    }
}

// MARK: - View Models

struct DeckViewModel: Identifiable {
    let id: String
    let title: String
    let questionCount: Int
    let masteryPercentage: Double?
    
    init(id: String, title: String, questionCount: Int, masteryPercentage: Double? = nil) {
        self.id = id
        self.title = title
        self.questionCount = questionCount
        self.masteryPercentage = masteryPercentage
    }
    
    init(deck: MBFoundation.Deck, masteryPercentage: Double? = nil) {
        self.id = deck.id
        self.title = deck.title
        self.questionCount = deck.questionCount
        self.masteryPercentage = masteryPercentage
    }
} 