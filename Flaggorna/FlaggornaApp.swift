//
//  FlaggornaApp.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-12.
//

import SwiftUI
import Starscream

@main
struct FlaggornaApp: App {
    @StateObject var socketManager = SocketManager.shared
    let user = User(id: UUID(), name: "", color: .white, score: 0, currentRound: 0)

    
    var body: some Scene {
        WindowGroup {
            
            ContentView()
                .environmentObject(socketManager)
        }
    }
}
