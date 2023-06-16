//
//  StoreView.swift
//  
//
//  Created by Mikael Mattsson on 2023-06-15.
//

import SwiftUI
import StoreKit

struct StoreView: View {
    
    @EnvironmentObject private var purchaseManager: PurchaseManager
    
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
            
            ForEach(purchaseManager.products) { product in
                Button {
                    Task {
                        do {
                            try await purchaseManager.purchase(product)
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
                try await purchaseManager.loadProducts()
            } catch {
                print(error)
            }
        }
        .padding(24)
    }

}

