//
//  GetReadyMultiplayerView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-26.
//

import SwiftUI

struct GetReadyMultiplayerView: View {
    @Binding var currentScene: String
    @Binding var rounds: Int
    
    @State private var timerCount = 2
    
    var body: some View {
        VStack (spacing: 10) {
            Text("GET READY!")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            Text("Round number \(rounds)")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            Text("\(timerCount)")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if self.timerCount > 0 {
                    self.timerCount -= 1
                } else {
                    timer.invalidate()
                    SocketManager.shared.currentScene = "MainMultiplayer"
                }
            }
        }
    }
}
