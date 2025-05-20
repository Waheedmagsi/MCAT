import Foundation
import MBFoundation

// Quiz Session Types

enum QuizMode: String {
    case deck
    case dailyDrill
    case fullExam
}

enum QuizStatus {
    case loading
    case active
    case completed
    case error(String)
}

// Question Display Types

struct QuizQuestion {
    let id: String
    let stemMarkdown: String
    let choices: [QuizChoice]
    let conceptId: String
    let explanationMarkdown: String?
    
    init(from question: MBFoundation.Question) {
        self.id = question.id
        self.stemMarkdown = question.stemMarkdown
        self.conceptId = question.conceptId
        self.explanationMarkdown = nil
        
        self.choices = question.choices.map { QuizChoice(id: $0.id, text: $0.text, isCorrect: $0.isCorrect) }
    }
}

struct QuizChoice {
    let id: String
    let text: String
    let isCorrect: Bool
}

// User Answer Types

enum AnswerResult {
    case correct
    case incorrect
    case unanswered
    
    var color: String {
        switch self {
        case .correct:
            return "green"
        case .incorrect:
            return "red"
        case .unanswered:
            return "gray"
        }
    }
    
    var symbolName: String {
        switch self {
        case .correct:
            return "checkmark.circle.fill"
        case .incorrect:
            return "xmark.circle.fill"
        case .unanswered:
            return "circle"
        }
    }
}

struct QuizAnswer {
    let questionId: String
    let selectedChoiceId: String?
    let isCorrect: Bool
    let timeSpentSeconds: Double
    let confidence: Double
    
    var result: AnswerResult {
        if selectedChoiceId == nil {
            return .unanswered
        }
        return isCorrect ? .correct : .incorrect
    }
}

// Session Stats

struct QuizSessionStats {
    let totalQuestions: Int
    let answeredQuestions: Int
    let correctAnswers: Int
    let incorrectAnswers: Int
    let unansweredQuestions: Int
    let averageTimeSeconds: Double
    let averageConfidence: Double
    
    var percentCorrect: Double {
        guard answeredQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(answeredQuestions) * 100
    }
    
    static func calculate(from answers: [QuizAnswer], totalQuestions: Int) -> QuizSessionStats {
        let answeredCount = answers.filter { $0.selectedChoiceId != nil }.count
        let correctCount = answers.filter { $0.isCorrect }.count
        let incorrectCount = answeredCount - correctCount
        let unansweredCount = totalQuestions - answeredCount
        
        let totalTime = answers.reduce(0) { $0 + $1.timeSpentSeconds }
        let averageTime = answeredCount > 0 ? totalTime / Double(answeredCount) : 0
        
        let totalConfidence = answers.reduce(0) { $0 + $1.confidence }
        let averageConfidence = answeredCount > 0 ? totalConfidence / Double(answeredCount) : 0
        
        return QuizSessionStats(
            totalQuestions: totalQuestions,
            answeredQuestions: answeredCount,
            correctAnswers: correctCount,
            incorrectAnswers: incorrectCount,
            unansweredQuestions: unansweredCount,
            averageTimeSeconds: averageTime,
            averageConfidence: averageConfidence
        )
    }
} 