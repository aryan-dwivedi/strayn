//
//  StoreKitManager.swift
//  strayn
//
//  Created by Aryan Dwivedi on 18/01/26.
//

import StoreKit
import Combine

enum SubscriptionTier: String, CaseIterable, Identifiable {
    case free
    case pro
    case elite
    
    var id: String { rawValue }
}

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published private(set) var currentTier: SubscriptionTier = .free
    @Published private(set) var products: [Product] = []
    
    private let productIds = ["com.strayn.pro", "com.strayn.elite"]
    
    private init() {
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    func loadProducts() async {
        do {
            self.products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Check transaction
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()
            
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == "com.strayn.elite" {
                    currentTier = .elite
                    return
                } else if transaction.productID == "com.strayn.pro" {
                    currentTier = .pro
                    return
                }
            } catch {
                print("Verification failed")
            }
        }
        currentTier = .free
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
