import Foundation
import Combine
import MBFoundation

class AlgorithmBridge {
    static let shared = AlgorithmBridge()
    
    private var isOnline = false
    private var cancellables = Set<AnyCancellable>()
    private var saktEngine = SAKTEngine()
    
    private init() {
        // Monitor network connectivity
        SupabaseClient.shared.isConnected
            .sink { [weak self] isConnected in
                self?.isOnline = isConnected
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Algorithm Selection
    
    func predictNextQuestion(userId: String, deckId: String, candidateQuestions: [MBFoundation.Question], completionHandler: @escaping (MBFoundation.Question) -> Void) {
        if isOnline {
            // Use CAKT via Supabase/gRPC
            print("Using online CAKT for prediction")
            
            // Extract concept IDs from the candidate questions
            let conceptIds = candidateQuestions.map { $0.conceptId }
            
            // Get h_vector from local storage if available
            let userSkillVector = getUserSkillVector(userId: userId)
            
            // Call CAKT service
            CAKTClient.shared.predictNextQuestion(userId: userId, conceptIds: conceptIds, hVector: userSkillVector)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            print("Error predicting next question with CAKT: \(error)")
                            // Fall back to offline algorithm
                            self.predictWithOfflineAlgorithm(candidateQuestions: candidateQuestions, completionHandler: completionHandler)
                        }
                    },
                    receiveValue: { bestConceptId in
                        // Find the question with this concept ID
                        if let question = candidateQuestions.first(where: { $0.conceptId == bestConceptId }) {
                            completionHandler(question)
                        } else {
                            // If concept ID not found, fall back to first question
                            completionHandler(candidateQuestions.first!)
                        }
                    }
                )
                .store(in: &cancellables)
        } else {
            // Use offline SAKTLite
            print("Using offline SAKTLite for prediction")
            predictWithOfflineAlgorithm(candidateQuestions: candidateQuestions, completionHandler: completionHandler)
        }
    }
    
    private func predictWithOfflineAlgorithm(candidateQuestions: [MBFoundation.Question], completionHandler: @escaping (MBFoundation.Question) -> Void) {
        // Extract concept IDs
        let conceptIds = candidateQuestions.map { $0.conceptId }
        
        // Ask SAKTEngine for best concept
        if let bestConceptId = saktEngine.getNextBestConcept(from: conceptIds) {
            if let bestQuestion = candidateQuestions.first(where: { $0.conceptId == bestConceptId }) {
                completionHandler(bestQuestion)
                return
            }
        }
        
        // If SAKTLite fails or no match, return random question
        let randomIndex = Int.random(in: 0..<candidateQuestions.count)
        completionHandler(candidateQuestions[randomIndex])
    }
    
    func updateModel(with response: MBFoundation.Response) -> AnyPublisher<MBFoundation.UserSkill, Error> {
        if isOnline {
            // Use CAKT via Supabase/gRPC
            print("Updating online CAKT model")
            
            // Convert to CAKTResponse
            let caktResponse = CAKTResponse(
                userId: response.userId,
                questionId: response.questionId,
                conceptId: "", // This should be populated in a real app
                isCorrect: response.isCorrect,
                latencyMs: response.latencyMs,
                confidence: response.confidence,
                answeredAt: response.answeredAt
            )
            
            return CAKTClient.shared.updateKnowledgeState(response: caktResponse)
                .map { caktUserSkill -> MBFoundation.UserSkill in
                    // Convert CAKTUserSkill to UserSkill
                    let userSkill = MBFoundation.UserSkill(
                        userId: caktUserSkill.userId,
                        thetaGlobal: caktUserSkill.thetaGlobal,
                        thetaByConcept: caktUserSkill.thetaByConcept,
                        hVector: caktUserSkill.hVector
                    )
                    
                    // Update local SAKTLite model with new h_vector
                    self.updateSAKTWithHVector(userId: response.userId, hVector: caktUserSkill.hVector.map { Float($0) })
                    
                    return userSkill
                }
                .catch { error -> AnyPublisher<MBFoundation.UserSkill, Error> in
                    print("Error updating online model: \(error)")
                    
                    // Fall back to offline update
                    self.updateOfflineModel(with: response)
                    
                    // Return estimated skill from offline model
                    return Just(MBFoundation.UserSkill(
                        userId: response.userId,
                        thetaGlobal: 0.6,
                        thetaByConcept: [:],
                        hVector: self.saktEngine.getUserSkillVector().map { Double($0) }
                    ))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        } else {
            // Use offline SAKTLite
            print("Updating offline SAKTLite model")
            
            // Update local model and return a local skill estimate
            updateOfflineModel(with: response)
            
            // Return estimated skill from offline model
            return Just(MBFoundation.UserSkill(
                userId: response.userId,
                thetaGlobal: 0.6,
                thetaByConcept: [:],
                hVector: saktEngine.getUserSkillVector().map { Double($0) }
            ))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        }
    }
    
    // MARK: - Offline Model Management
    
    func updateOfflineModel(with response: MBFoundation.Response) {
        // Extract concept ID - in a real app, this would come from the question
        let conceptId = response.questionId.hasPrefix("q") ? "concept1" : "concept2" 
        
        // Update the SAKTLite model
        saktEngine.recordInteraction(conceptId: conceptId, correct: response.isCorrect)
        
        // Also update local user progress in Core Data
        OfflineStore.shared.updateUserProgress(
            userId: response.userId,
            deckId: response.questionId, // Assuming questionId can be used to get deckId
            conceptId: conceptId, 
            isCorrect: response.isCorrect
        )
    }
    
    private func updateSAKTWithHVector(userId: String, hVector: [Float]) {
        // Update the local SAKTLite model with the h_vector from the server
        saktEngine.setUserSkillVector(hVector)
        
        // In a real app, we would also save this h_vector to local storage
        // for future use when offline
    }
    
    private func getUserSkillVector(userId: String) -> [Double]? {
        // In a real app, this would fetch from local storage if available
        return saktEngine.getUserSkillVector().map { Double($0) }
    }
    
    // MARK: - Helpers
    
    private func createMockQuestion() -> MBFoundation.Question {
        return MBFoundation.Question(
            id: UUID().uuidString,
            stemMarkdown: "Which of the following best describes the function of DNA polymerase?",
            deckId: "deck1",
            conceptId: "concept1",
            difficulty: 0.7,
            choices: [
                MBFoundation.Choice(id: "a", text: "It catalyzes the synthesis of DNA by adding nucleotides", isCorrect: true),
                MBFoundation.Choice(id: "b", text: "It breaks down DNA into nucleotides", isCorrect: false),
                MBFoundation.Choice(id: "c", text: "It transports DNA from the nucleus to the cytoplasm", isCorrect: false),
                MBFoundation.Choice(id: "d", text: "It packages DNA into chromatin", isCorrect: false)
            ]
        )
    }
} 