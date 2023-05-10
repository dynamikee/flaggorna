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
    @Binding var numberOfRounds: Int
    
    @State private var timerCount = 2
    
    var body: some View {
        VStack (spacing: 10) {
            HStack {
                ForEach((0..<numberOfRounds).reversed(), id: \.self) { index in
                    if index < rounds {
                        Image(systemName: "circle.dotted")
                            .foregroundColor(.gray)
                        
                    } else {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            Spacer()
        
            Text("GET READY!")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)
            
            Spacer()

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
