import Foundation
import StoreKit
import Combine

class PurchaseService {
    static let shared = PurchaseService()
    
    private(set) var products: [Product] = []
    private(set) var isPremium = CurrentValueSubject<Bool, Never>(false)
    
    private var updates: Task<Void, Error>? = nil
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Start listening for transactions
        setupTransactionListener()
        
        // Load products
        Task {
            await loadProducts()
            await updatePurchasedState()
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    // MARK: - Product Management
    
    func loadProducts() async {
        do {
            // Define your product IDs
            let productIds = ["premium.monthly", "premium.yearly", "premium.lifetime"]
            
            // Request products from App Store
            products = try await Product.products(for: productIds)
            
            print("Loaded \(products.count) products")
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase Flow
    
    func purchase(productId: String) async throws -> Transaction? {
        guard let product = products.first(where: { $0.id == productId }) else {
            throw PurchaseError.productNotFound
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Check if the transaction is verified
                switch verification {
                case .verified(let transaction):
                    // Transaction is verified
                    await transaction.finish()
                    await updatePurchasedState()
                    return transaction
                case .unverified:
                    throw PurchaseError.failedVerification
                }
            case .userCancelled:
                return nil
            case .pending:
                throw PurchaseError.pending
            @unknown default:
                throw PurchaseError.unknown
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - Transaction Management
    
    private func setupTransactionListener() {
        updates = Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // Handle successful transaction
                    await self.updatePurchasedState()
                    
                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw PurchaseError.failedVerification
        }
    }
    
    // MARK: - Premium Status
    
    func updatePurchasedState() async {
        var hasPremium = false
        
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productID.contains("premium") {
                    hasPremium = true
                    break
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        // Update premium status
        await MainActor.run {
            self.isPremium.send(hasPremium)
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        // With StoreKit 2, explicit restore is typically unnecessary
        // as Transaction.currentEntitlements automatically includes all purchases
        await updatePurchasedState()
    }
    
    // MARK: - Helper Methods
    
    func formatPrice(for productId: String) -> String {
        guard let product = products.first(where: { $0.id == productId }) else {
            return "N/A"
        }
        
        return product.displayPrice
    }
}

// MARK: - Errors

enum PurchaseError: Error {
    case productNotFound
    case failedVerification
    case pending
    case unknown
} 