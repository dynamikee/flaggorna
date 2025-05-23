//
//  FlaggornaApp.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-12.
//

import SwiftUI
import Starscream
import CoreData

@main
struct FlaggornaApp: App {
    @StateObject var socketManager = SocketManager.shared
    let user = User(id: UUID(), name: "", color: .white, score: 0, currentRound: 0)
    let persistenceController = PersistenceController.shared

    @StateObject private var purchaseManager = PurchaseManager()
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(socketManager)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(purchaseManager)
                .task {
                    await purchaseManager.updatePurchasedProducts()
                }
        }
    }
}

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "FlagStats")

        container.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
    }
}
