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
            
            if purchaseManager.hasUnlockedPremium {
                Text("Thank you for purchasing premium!")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            } else {
                
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
                Button {
                    Task {
                        do {
                            try await AppStore.sync()
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Text("Restore Purchases")
                }
            }
        }
        .padding(24)
    }

}

