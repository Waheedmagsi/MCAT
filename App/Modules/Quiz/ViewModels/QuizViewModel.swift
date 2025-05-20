import Foundation
import Combine
import MBFoundation

class QuizViewModel: ObservableObject {
    // Quiz session properties
    let deckId: String
    let mode: QuizMode
    private(set) var userId: String = "current-user-id" // Would be fetched from auth
    
    // State
    @Published var status: QuizStatus = .loading
    @Published var currentQuestionIndex: Int = 0
    @Published var questions: [QuizQuestion] = []
    @Published var answers: [QuizAnswer] = []
    @Published var selectedChoiceId: String?
    @Published var isShowingExplanation = false
    @Published var confidenceLevel: Double = 0.5
    @Published var isSubmitEnabled = false
    
    // Timing
    private var questionStartTime: Date?
    private var sessionStartTime: Date?
    private var elapsedSeconds: TimeInterval = 0
    private var timer: Timer?
    
    // Services
    private let isPremium: Bool
    private var cancellables = Set<AnyCancellable>()
    
    // Question pool and adaptivity
    private var questionPool: [MBFoundation.Question] = []
    private var remainingQuestionIndices: [Int] = []
    private var isAdaptive: Bool = false
    private let maxQuestions: Int
    
    init(deckId: String, mode: QuizMode) {
        self.deckId = deckId
        self.mode = mode
        
        // Get premium status
        self.isPremium = PurchaseService.shared.isPremium.value
        
        // Configure quiz based on mode
        switch mode {
        case .deck:
            self.isAdaptive = false
            self.maxQuestions = 50 // Allow user to go through the entire deck
        case .dailyDrill:
            self.isAdaptive = true
            self.maxQuestions = 10 // Daily drills are 10 questions max
        case .fullExam:
            self.isAdaptive = isPremium // Only premium users get adaptive full exams
            self.maxQuestions = 230 // MCAT exam length
        }
        
        // Start loading
        loadQuestions()
    }
    
    deinit {
        stopTimer()
    }
    
    // MARK: - Quiz Flow
    
    func loadQuestions() {
        status = .loading
        
        // Check if this is a deck practice or a daily drill
        if mode == .deck {
            // For deck practice, fetch all questions for the deck
            fetchQuestionsForDeck()
        } else {
            // For daily drill or full exam, fetch a larger pool and select adaptively
            fetchQuestionPool()
        }
    }
    
    private func fetchQuestionsForDeck() {
        // Try to load from cache first
        if let cachedQuestions = OfflineStore.shared.loadCachedQuestions(for: deckId) {
            self.questionPool = cachedQuestions
            setupQuestions()
            return
        }
        
        // Otherwise fetch from API
        SupabaseClient.shared.fetchQuestions(deckId: deckId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.status = .error(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] questions in
                    guard let self = self else { return }
                    
                    // Cache questions for offline use
                    OfflineStore.shared.cacheQuestions(questions, for: self.deckId)
                    
                    self.questionPool = questions
                    self.setupQuestions()
                }
            )
            .store(in: &cancellables)
    }
    
    private func fetchQuestionPool() {
        // In a real app, this would fetch from multiple decks based on user's weak areas
        // For now, we'll just get a sample of questions
        
        // Simulate API call to fetch a pool of candidate questions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // Generate a pool of mock questions
            self.questionPool = self.generateMockQuestionPool(count: 30)
            
            // For daily drills and adaptive exams, we'll select questions one by one
            if self.isAdaptive {
                self.setupAdaptiveQuiz()
            } else {
                // For non-adaptive, we'll pre-select all questions
                self.setupQuestions()
            }
        }
    }
    
    private func setupQuestions() {
        // For non-adaptive quizzes, prepare all questions at once
        let allQuestions = questionPool.prefix(maxQuestions).map { QuizQuestion(from: $0) }
        questions = Array(allQuestions)
        
        // Initialize answers array
        answers = Array(repeating: QuizAnswer(
            questionId: "",
            selectedChoiceId: nil,
            isCorrect: false,
            timeSpentSeconds: 0,
            confidence: 0
        ), count: questions.count)
        
        if !questions.isEmpty {
            status = .active
            startQuestionTimer()
            sessionStartTime = Date()
        } else {
            status = .error("No questions available")
        }
    }
    
    private func setupAdaptiveQuiz() {
        // For adaptive quizzes, start with just the first question
        getNextAdaptiveQuestion()
    }
    
    private func getNextAdaptiveQuestion() {
        guard questions.count < maxQuestions else {
            // We've reached our question limit
            return
        }
        
        // Use AlgorithmBridge to get the next most informative question
        AlgorithmBridge.shared.predictNextQuestion(
            userId: userId,
            deckId: deckId,
            candidateQuestions: remainingQuestionsInPool()
        ) { [weak self] nextQuestion in
            guard let self = self else { return }
            
            let quizQuestion = QuizQuestion(from: nextQuestion)
            
            // Add to our questions list
            self.questions.append(quizQuestion)
            
            // Extend answers array
            self.answers.append(QuizAnswer(
                questionId: quizQuestion.id,
                selectedChoiceId: nil,
                isCorrect: false,
                timeSpentSeconds: 0,
                confidence: 0
            ))
            
            // Remove this question from the pool to avoid duplicates
            if let index = self.questionPool.firstIndex(where: { $0.id == nextQuestion.id }) {
                self.questionPool[index] = self.questionPool.last!
                self.questionPool.removeLast()
            }
            
            // Start the quiz if this is the first question
            if self.status == .loading {
                self.status = .active
                self.startQuestionTimer()
                self.sessionStartTime = Date()
            }
        }
    }
    
    private func remainingQuestionsInPool() -> [MBFoundation.Question] {
        // Get questions that haven't been used yet
        let usedQuestionIds = Set(questions.map { $0.id })
        return questionPool.filter { !usedQuestionIds.contains($0.id) }
    }
    
    func selectChoice(choiceId: String) {
        selectedChoiceId = choiceId
        isSubmitEnabled = true
    }
    
    func submitAnswer() {
        guard currentQuestionIndex < questions.count,
              let selectedId = selectedChoiceId else {
            return
        }
        
        stopTimer()
        let question = questions[currentQuestionIndex]
        let selectedChoice = question.choices.first(where: { $0.id == selectedId })
        let isCorrect = selectedChoice?.isCorrect ?? false
        
        let timeSpent = calculateElapsedTime()
        
        // Record the answer
        let answer = QuizAnswer(
            questionId: question.id,
            selectedChoiceId: selectedId,
            isCorrect: isCorrect,
            timeSpentSeconds: timeSpent,
            confidence: confidenceLevel
        )
        
        answers[currentQuestionIndex] = answer
        
        // Log to analytics
        AnalyticsService.shared.trackQuestionAnswered(
            questionId: question.id,
            isCorrect: isCorrect,
            timeSpentSeconds: timeSpent,
            confidence: confidenceLevel
        )
        
        // Create Response object for algorithm update
        let response = MBFoundation.Response(
            id: UUID().uuidString,
            userId: userId,
            questionId: question.id,
            isCorrect: isCorrect,
            confidence: confidenceLevel,
            latencyMs: Int(timeSpent * 1000),
            answeredAt: Date()
        )
        
        // Update the knowledge model via AlgorithmBridge
        AlgorithmBridge.shared.updateModel(with: response)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    // We could use the updated skill state here if needed
                }
            )
            .store(in: &cancellables)
        
        // Store response in offline store for sync
        OfflineStore.shared.saveResponse(response: response)
        
        // Show explanation for premium users
        if isPremium {
            isShowingExplanation = true
        } else {
            moveToNextQuestion()
        }
    }
    
    func moveToNextQuestion() {
        if isShowingExplanation {
            isShowingExplanation = false
        }
        
        isSubmitEnabled = false
        selectedChoiceId = nil
        confidenceLevel = 0.5
        
        if currentQuestionIndex + 1 < questions.count {
            currentQuestionIndex += 1
            startQuestionTimer()
        } else if isAdaptive && remainingQuestionsInPool().count > 0 && questions.count < maxQuestions {
            // For adaptive quizzes, get the next question
            getNextAdaptiveQuestion()
            currentQuestionIndex = questions.count - 1
            startQuestionTimer()
        } else {
            completeQuiz()
        }
    }
    
    func completeQuiz() {
        status = .completed
        
        // Record session completion
        let totalTime = Date().timeIntervalSince(sessionStartTime ?? Date())
        AnalyticsService.shared.trackQuizCompleted(
            deckId: deckId,
            questionsAnswered: answers.filter { $0.selectedChoiceId != nil }.count,
            timeSpentSeconds: Int(totalTime)
        )
    }
    
    // MARK: - Timing Management
    
    private func startQuestionTimer() {
        questionStartTime = Date()
        startTimer()
    }
    
    private func startTimer() {
        elapsedSeconds = 0
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateElapsedTime() {
        elapsedSeconds = calculateElapsedTime()
    }
    
    private func calculateElapsedTime() -> TimeInterval {
        guard let startTime = questionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Helper Methods
    
    var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var progressPercent: Double {
        guard !questions.isEmpty else { return 0 }
        let answered = answers.prefix(currentQuestionIndex).filter { $0.selectedChoiceId != nil }.count
        return Double(answered) / Double(questions.count)
    }
    
    var quizStats: QuizSessionStats {
        return QuizSessionStats.calculate(from: answers, totalQuestions: questions.count)
    }
    
    var formattedElapsedTime: String {
        let minutes = Int(elapsedSeconds) / 60
        let seconds = Int(elapsedSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockQuestionPool(count: Int) -> [MBFoundation.Question] {
        var questions: [MBFoundation.Question] = []
        
        let concepts = ["biochemistry", "biology", "organic_chemistry", "general_chemistry", "physics"]
        
        for i in 0..<count {
            let conceptIndex = i % concepts.count
            let question = MBFoundation.Question(
                id: "q\(i)",
                stemMarkdown: "Question \(i+1): What is the primary function of mitochondria in a cell?",
                deckId: self.deckId,
                conceptId: concepts[conceptIndex],
                difficulty: Double.random(in: 0.3...0.9),
                choices: [
                    MBFoundation.Choice(id: "a", text: "Energy production (ATP synthesis)", isCorrect: true),
                    MBFoundation.Choice(id: "b", text: "Protein synthesis", isCorrect: false),
                    MBFoundation.Choice(id: "c", text: "Lipid storage", isCorrect: false),
                    MBFoundation.Choice(id: "d", text: "Cell division", isCorrect: false)
                ]
            )
            questions.append(question)
        }
        
        return questions
    }
    
    // This would fetch from a specific source, e.g., an LLM or pre-defined content
    // For now, it just returns a placeholder based on the question concept.
    func explanation(for question: MBFoundation.Question) -> String {
        if isPremium {
            return "AI-powered explanation for concept \(question.conceptId) coming soon!"
        } else {
            return "Explanation not available for non-premium users"
        }
    }
} 