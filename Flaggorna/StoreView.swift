//
//  StoreView.swift
//  
//
//  Created by Mikael Mattsson on 2023-06-15.
//

import SwiftUI
import StoreKit

struct StoreView: View {
    let productIds = ["flaggorna_PREMIUM"]
    
    @State
    private var products: [Product] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Play with more than four friends")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("You need a premium subscription")
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            ForEach(self.products) { product in
                Button {
                    Task {
                        do {
                            try await self.purchase(product)
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Text("\(product.displayPrice)")
                }
                .padding()
                .buttonStyle(OrdinaryButtonStyle())
            }
        }.task {
            do {
                try await self.loadProducts()
            } catch {
                print(error)
            }
        }
        .padding(24)
    }
    
    private func loadProducts() async throws {
        self.products = try await Product.products(for: productIds)
    }
    
    private func purchase(_ product: Product) async throws {
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

