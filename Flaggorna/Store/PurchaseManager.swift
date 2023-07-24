//
//  PurchaseManager.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-06-16.
//

import Foundation
import StoreKit

@MainActor
class PurchaseManager: ObservableObject {
    
    #if FLAGGORNA
    let productIds = ["flaggorna_PREMIUM"]
    #elseif TEAM_LOGO_QUIZ
    let productIds = ["teams_PREMIUM"]
    #endif
    
    @Published
    private(set) var products: [Product] = []
    private var productsLoaded = false
    private(set) var purchasedProductIDs = Set<String>()

    
    @Published private(set) var hasUnlockedPremium: Bool = false

    
    private var updates: Task<Void, Never>? = nil
    
    init() {
        updates = observeTransactionUpdates()
    }
    
    deinit {
        updates?.cancel()
    }
    
    func loadProducts() async throws {
        guard !self.productsLoaded else { return }
        self.products = try await Product.products(for: productIds)
        self.productsLoaded = true
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case let .success(.verified(transaction)):
            // Successful purhcase
            await transaction.finish()
            await self.updatePurchasedProducts()
            
        case let .success(.unverified(_, error)):
            // Successful purchase but transaction/receipt can't be verified
            // Could be a jailbroken phone
            break
        case .pending:
            // Transaction waiting on SCA (Strong Customer Authentication) or
            // approval from Ask to Buy
            break
        case .userCancelled:
            // ^^^
            break
        @unknown default:
            break
        }
    }
    
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
        }
        
        self.hasUnlockedPremium = !self.purchasedProductIDs.isEmpty

    }
    
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await verificationResult in Transaction.updates {
                // Using verificationResult directly would be better
                // but this way works for this tutorial
                await self.updatePurchasedProducts()
            }
        }
    }
}
