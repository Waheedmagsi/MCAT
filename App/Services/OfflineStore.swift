import Foundation
import CoreData
import Combine
import MBFoundation

class OfflineStore {
    static let shared = OfflineStore()
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreDataModel")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    private var pendingSyncResponsesCount = CurrentValueSubject<Int, Never>(0)
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Setup sync observation
        NotificationCenter.default.publisher(for: .networkStateChanged)
            .sink { [weak self] notification in
                if let isConnected = notification.object as? Bool, isConnected {
                    self?.syncPendingResponses()
                }
            }
            .store(in: &cancellables)
        
        // Count initial pending responses
        countPendingResponses()
    }
    
    // MARK: - Core Context
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Offline Response Handling
    
    func saveResponse(response: MBFoundation.Response) {
        let context = persistentContainer.viewContext
        
        // Create a LocalResponse entity
        let localResponse = LocalResponse(context: context)
        localResponse.id = response.id
        localResponse.userId = response.userId
        localResponse.questionId = response.questionId
        localResponse.conceptId = "" // This should be populated in a real app
        localResponse.isCorrect = response.isCorrect
        localResponse.confidence = response.confidence
        localResponse.latencyMs = Int32(response.latencyMs)
        localResponse.answeredAt = response.answeredAt
        localResponse.isPendingSync = true
        
        // Update local SAKTLite model
        AlgorithmBridge.shared.updateOfflineModel(with: response)
        
        saveContext()
        
        // Update pending count
        countPendingResponses()
    }
    
    func syncPendingResponses() {
        let context = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<LocalResponse> = LocalResponse.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isPendingSync == YES")
        
        do {
            let pendingResponses = try context.fetch(fetchRequest)
            
            guard !pendingResponses.isEmpty else { return }
            
            print("Syncing \(pendingResponses.count) pending responses")
            
            // In a real implementation, we'd batch these and send to the CAKT server
            // Convert to CAKTResponse objects
            let caktResponses = pendingResponses.map { localResponse in
                CAKTResponse(
                    userId: localResponse.userId ?? "",
                    questionId: localResponse.questionId ?? "",
                    conceptId: localResponse.conceptId ?? "",
                    isCorrect: localResponse.isCorrect,
                    latencyMs: Int(localResponse.latencyMs),
                    confidence: localResponse.confidence,
                    answeredAt: localResponse.answeredAt ?? Date()
                )
            }
            
            // Batch update via CAKTClient
            CAKTClient.shared.batchUpdate(responses: caktResponses)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            // Mark as synced
                            for response in pendingResponses {
                                response.isPendingSync = false
                            }
                            self.saveContext()
                            self.countPendingResponses()
                            NotificationCenter.default.post(name: .syncCompleted, object: nil)
                        case .failure(let error):
                            print("Failed to sync responses: \(error)")
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        } catch {
            print("Error fetching pending responses: \(error)")
        }
    }
    
    private func countPendingResponses() {
        let context = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<LocalResponse> = LocalResponse.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isPendingSync == YES")
        
        do {
            let count = try context.count(for: fetchRequest)
            pendingSyncResponsesCount.send(count)
        } catch {
            print("Error counting pending responses: \(error)")
            pendingSyncResponsesCount.send(0)
        }
    }
    
    // MARK: - Question Caching
    
    func cacheQuestions(_ questions: [MBFoundation.Question], for deckId: String) {
        let context = persistentContainer.viewContext
        
        for question in questions {
            let cachedQuestion = CachedQuestion(context: context)
            cachedQuestion.id = question.id
            cachedQuestion.deckId = question.deckId
            cachedQuestion.conceptId = question.conceptId
            cachedQuestion.stemMarkdown = question.stemMarkdown
            cachedQuestion.difficulty = question.difficulty
            
            // Create choices
            for choice in question.choices {
                let questionChoice = QuestionChoice(context: context)
                questionChoice.id = choice.id
                questionChoice.text = choice.text
                questionChoice.isCorrect = choice.isCorrect
                
                cachedQuestion.addToChoices(questionChoice)
            }
        }
        
        // Update local deck info
        updateLocalDeck(deckId: deckId, questionCount: questions.count)
        
        saveContext()
    }
    
    func loadCachedQuestions(for deckId: String) -> [Question]? {
        let context = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<CachedQuestion> = CachedQuestion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "deckId == %@", deckId)
        
        do {
            let cachedQuestions = try context.fetch(fetchRequest)
            
            if cachedQuestions.isEmpty {
                return nil
            }
            
            return cachedQuestions.compactMap { cachedQuestion in
                guard let id = cachedQuestion.id,
                      let deckId = cachedQuestion.deckId,
                      let conceptId = cachedQuestion.conceptId,
                      let stemMarkdown = cachedQuestion.stemMarkdown,
                      let choicesSet = cachedQuestion.choices as? Set<QuestionChoice> else {
                    return nil
                }
                
                let choices = choicesSet.compactMap { questionChoice in
                    guard let id = questionChoice.id, let text = questionChoice.text else {
                        return nil
                    }
                    return MBFoundation.Choice(id: id, text: text, isCorrect: questionChoice.isCorrect)
                }
                
                return MBFoundation.Question(
                    id: id,
                    stemMarkdown: stemMarkdown,
                    deckId: deckId,
                    conceptId: conceptId,
                    difficulty: cachedQuestion.difficulty,
                    choices: choices
                )
            }
        } catch {
            print("Error fetching cached questions: \(error)")
            return nil
        }
    }
    
    private func updateLocalDeck(deckId: String, questionCount: Int) {
        let context = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<LocalDeck> = LocalDeck.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", deckId)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            let deck: LocalDeck
            
            if let existingDeck = results.first {
                deck = existingDeck
            } else {
                deck = LocalDeck(context: context)
                deck.id = deckId
            }
            
            deck.questionCount = Int32(questionCount)
            deck.lastSynced = Date()
            
            saveContext()
        } catch {
            print("Error updating local deck: \(error)")
        }
    }
    
    // MARK: - User Progress
    
    func updateUserProgress(userId: String, deckId: String, conceptId: String, isCorrect: Bool) {
        let context = persistentContainer.viewContext
        
        // TODO: Verify 'UserProgress' Core Data entity name and ensure its Swift class is generated and included in the target.
        // The following line is commented out as 'UserProgress' could not be found.
        // let userProgress = UserProgress(context: context) 

        // Placeholder: Find existing or create new UserProgress record
        // Example logic (assuming UserProgress has userId, deckId, conceptId as unique keys or fetchable attributes):
        /*
        let fetchRequest: NSFetchRequest<UserProgress> = UserProgress.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@ AND deckId == %@ AND conceptId == %@", userId, deckId, conceptId)
        
        do {
            let results = try context.fetch(fetchRequest)
            let progressRecord: UserProgress
            if let existingRecord = results.first {
                progressRecord = existingRecord
            } else {
                progressRecord = UserProgress(context: context)
                progressRecord.userId = userId
                progressRecord.deckId = deckId
                progressRecord.conceptId = conceptId
                progressRecord.correctCount = 0
                progressRecord.totalAttempts = 0
            }
            
            // Update progress
            progressRecord.totalAttempts += 1
            if isCorrect {
                progressRecord.correctCount += 1
            }
            // progressRecord.lastAttemptDate = Date()
            // progressRecord.masteryLevel = calculateMastery(correct: progressRecord.correctCount, attempts: progressRecord.totalAttempts)
            
        } catch {
            print("Error fetching or creating UserProgress: \(error)")
        }
        */
        
        saveContext()
    }
    
    // Placeholder: Fetch or create UserProgress (replace with actual Core Data logic)
    // private func fetchOrCreateUserProgress(userId: String, conceptId: String, context: NSManagedObjectContext) -> UserProgress {
    //     let fetchRequest: NSFetchRequest<UserProgress> = UserProgress.fetchRequest()
    //     fetchRequest.predicate = NSPredicate(format: "userId == %@ AND conceptId == %@", userId, conceptId)
    //     
    //     do {
    //         let results = try context.fetch(fetchRequest)
    //         if let existingProgress = results.first {
    //             return existingProgress
    //         }
    //     } catch {
    //         print("Error fetching UserProgress: \(error)")
    //     }
    //     
    //     let newProgress = UserProgress(context: context)
    //     newProgress.userId = userId
    //     newProgress.conceptId = conceptId
    //     newProgress.attempts = 0
    //     newProgress.correctAttempts = 0
    //     return newProgress
    // }
    
    func getUserProgress(userId: String, deckId: String? = nil) -> [UserProgress] {
        let context = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<UserProgress> = UserProgress.fetchRequest()
        
        if let deckId = deckId {
            fetchRequest.predicate = NSPredicate(format: "userId == %@ AND deckId == %@", userId, deckId)
        } else {
            fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        }
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching user progress: \(error)")
            return []
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        let context = persistentContainer.viewContext
        
        // Don't delete pending responses
        let entities = ["CachedQuestion", "QuestionChoice", "LocalDeck", "UserProgress"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print("Error clearing \(entityName) cache: \(error)")
            }
        }
        
        print("Cache cleared")
    }
    
    func clearUserData(userId: String) {
        let context = persistentContainer.viewContext
        
        // Entities with userId attribute
        let entities = ["LocalResponse", "UserProgress", "UserSession"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print("Error clearing user data for \(entityName): \(error)")
            }
        }
        
        print("User data cleared for userId: \(userId)")
    }
}

// Placeholder for Core Data Managed Object - this should be generated by Xcode or defined manually based on your .xcdatamodeld
// @objc(UserProgress)
// public class UserProgress: NSManagedObject {
//     @NSManaged public var userId: String?
//     @NSManaged public var conceptId: String?
//     @NSManaged public var attempts: Int32
//     @NSManaged public var correctAttempts: Int32
//     @NSManaged public var lastAttempted: Date?
// }
//
// extension UserProgress {
//    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProgress> {
//        return NSFetchRequest<UserProgress>(entityName: "UserProgress")
//    }
//}

// MARK: - Notifications
// ... existing code ... 