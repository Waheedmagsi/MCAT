import Foundation
import Combine

struct TopicMastery: Identifiable {
    let id = UUID()
    let name: String
    let mastery: Double
}

enum TopicFilter {
    case all, weakest, strongest
}

class DashboardViewModel: ObservableObject {
    // Overall metrics
    @Published var overallMastery: Double = 0
    @Published var masteryChange: Int? = nil
    @Published var percentileRank: Int? = nil
    
    // Activity stats
    @Published var questionsAnswered: Int = 0
    @Published var studyStreak: Int = 0
    @Published var hoursStudied: Int = 0
    
    // Topic mastery
    @Published var topicMastery: [TopicMastery] = []
    private var allTopics: [TopicMastery] = []
    
    // Weekly activity
    @Published var weeklyActivity: [Bool] = []
    let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    
    // Loading state
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to sync notifications to refresh data
        NotificationCenter.default.publisher(for: .syncCompleted)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshDashboardData()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadDashboardData() {
        if overallMastery == 0 && !isLoading {
            Task { @MainActor in
                await refreshDashboardData()
            }
        }
    }
    
    @MainActor
    func refreshDashboardData() async {
        isLoading = true
        
        // In a real implementation, this would fetch analytics from SupabaseClient
        // For now, generate mock data
        
        // Simulate API delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Generate mock data
        overallMastery = Double.random(in: 60...85)
        masteryChange = Int.random(in: -3...5)
        percentileRank = Int.random(in: 70...95)
        
        questionsAnswered = Int.random(in: 500...2000)
        studyStreak = Int.random(in: 3...21)
        hoursStudied = Int.random(in: 30...120)
        
        // Generate topics with mastery levels
        allTopics = generateMockTopics()
        topicMastery = allTopics
        
        // Generate weekly activity
        weeklyActivity = generateMockWeeklyActivity()
        
        isLoading = false
    }
    
    func filterTopics(filter: TopicFilter) {
        switch filter {
        case .all:
            topicMastery = allTopics
        case .weakest:
            topicMastery = allTopics.sorted { $0.mastery < $1.mastery }.prefix(5).map { $0 }
        case .strongest:
            topicMastery = allTopics.sorted { $0.mastery > $1.mastery }.prefix(5).map { $0 }
        }
    }
    
    // MARK: - Mock Data Generators
    
    private func generateMockTopics() -> [TopicMastery] {
        let topics = [
            "Biology - Cells",
            "Biology - Systems",
            "Organic Chemistry",
            "General Chemistry",
            "Physics - Mechanics",
            "Physics - Waves & Sound",
            "Biochemistry",
            "Psychology",
            "Sociology",
            "Critical Analysis (CARS)"
        ]
        
        return topics.map { topic in
            TopicMastery(name: topic, mastery: Double.random(in: 30...95))
        }
    }
    
    private func generateMockWeeklyActivity() -> [Bool] {
        return (0..<7).map { _ in Bool.random() }
    }
} 