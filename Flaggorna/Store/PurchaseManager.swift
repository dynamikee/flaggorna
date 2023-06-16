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

    let productIds = ["flaggorna_PREMIUM"]
    
    @Published
    private(set) var products: [Product] = []
    private var productsLoaded = false

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
            UserDefaults.standard.set("true", forKey: "premium")
            
            await transaction.finish()
            
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
}
