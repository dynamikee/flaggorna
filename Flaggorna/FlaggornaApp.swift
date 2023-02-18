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
    
    var body: some Scene {
        WindowGroup {
            
            ContentView()
                .environmentObject(socketManager)
        }
    }
}
