import Foundation
import Combine

struct DailyDrillStat: Identifiable {
    let id = UUID()
    let date: String
    let score: Int
    let correct: Int
    let total: Int
}

class DailyDrillViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var drillAvailable = false
    @Published var questionCount = 0
    @Published var estimatedMinutes = 0
    @Published var targetSkill = ""
    @Published var dailyDrillDescription = ""
    @Published var nextDrillTime = ""
    @Published var hasCompletedDrills = false
    @Published var recentDrillStats: [DailyDrillStat] = []
    
    @Published var showingDrill = false
    @Published var showingPremiumAlert = false
    
    private var isPremium = false
    private var timer: Timer?
    private var nextDrillDate: Date?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to premium status
        PurchaseService.shared.isPremium
            .sink { [weak self] isPremium in
                self?.isPremium = isPremium
            }
            .store(in: &cancellables)
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func checkDailyDrillStatus() {
        isLoading = true
        
        // In a real implementation, this would:
        // 1. Check if the user has already completed today's drill
        // 2. Check if they're a premium user with unlimited drills
        // 3. Calculate the next available drill time
        
        // For demo purposes, simulate loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Set default values
            self.questionCount = 10
            self.estimatedMinutes = 5
            self.targetSkill = "Bio-Energetics"
            self.dailyDrillDescription = "Today's drill focuses on your weakest concepts from recent practice. Complete these 10 questions to boost your mastery."
            
            // Decide if drill is available
            let randomAvailable = Bool.random()
            self.drillAvailable = isPremium || randomAvailable
            
            // Setup next drill time if not available
            if !self.drillAvailable {
                let nextDate = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date()
                self.nextDrillDate = nextDate
                self.updateNextDrillTime()
                self.startTimer()
            }
            
            // Generate recent stats
            self.hasCompletedDrills = true
            self.recentDrillStats = self.generateMockStats()
            
            self.isLoading = false
        }
    }
    
    func startDailyDrill() {
        // Track analytics
        AnalyticsService.shared.trackQuizStarted(deckId: "daily", mode: .dailyDrill)
        
        // Show the drill
        showingDrill = true
    }
    
    func showPremiumFeatures() {
        showingPremiumAlert = true
    }
    
    // MARK: - Private Helpers
    
    private func startTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateNextDrillTime()
        }
    }
    
    private func updateNextDrillTime() {
        guard let nextDate = nextDrillDate else { return }
        
        let now = Date()
        let remaining = nextDate.timeIntervalSince(now)
        
        if remaining <= 0 {
            nextDrillTime = "Now"
            drillAvailable = true
            timer?.invalidate()
        } else {
            let hours = Int(remaining) / 3600
            let minutes = (Int(remaining) % 3600) / 60
            
            if hours > 0 {
                nextDrillTime = "\(hours)h \(minutes)m"
            } else {
                nextDrillTime = "\(minutes) minutes"
            }
        }
    }
    
    private func generateMockStats() -> [DailyDrillStat] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        var stats: [DailyDrillStat] = []
        
        // Generate stats for the past 5 days
        for i in 1...5 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dateString = dateFormatter.string(from: date)
            
            let total = 10
            let correct = Int.random(in: 3...10)
            let score = (correct * 100) / total
            
            stats.append(DailyDrillStat(
                date: dateString,
                score: score,
                correct: correct,
                total: total
            ))
        }
        
        return stats
    }
} 