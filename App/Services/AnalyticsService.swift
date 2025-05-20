import Foundation

// Mock analytics service that doesn't depend on any external libraries
class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {
        print("Analytics service initialized (placeholder implementation)")
    }
    
    // MARK: - Event Tracking
    
    func trackScreenView(screenName: String, screenClass: String) {
        print("📊 Analytics: Screen viewed - \(screenName) (\(screenClass))")
    }
    
    func trackQuizStarted(deckId: String, mode: QuizMode) {
        print("📊 Analytics: Quiz started - Deck: \(deckId), Mode: \(mode.rawValue)")
    }
    
    func trackQuizCompleted(deckId: String, questionsAnswered: Int, timeSpentSeconds: Int) {
        print("📊 Analytics: Quiz completed - Deck: \(deckId), Questions: \(questionsAnswered), Time: \(timeSpentSeconds)s")
    }
    
    func trackQuestionAnswered(questionId: String, isCorrect: Bool, timeSpentSeconds: Double, confidence: Double) {
        print("📊 Analytics: Question answered - ID: \(questionId), Correct: \(isCorrect), Time: \(timeSpentSeconds)s, Confidence: \(confidence)")
    }
    
    func trackError(code: String, message: String, context: String) {
        print("📊 Analytics: Error - Code: \(code), Message: \(message), Context: \(context)")
    }
    
    func trackSubscriptionEvent(action: String, plan: String, success: Bool) {
        print("📊 Analytics: Subscription event - Action: \(action), Plan: \(plan), Success: \(success)")
    }
}

// Removed QuizMode from here to resolve ambiguity. 
// It should be defined in a more central location or within the Quiz module. 