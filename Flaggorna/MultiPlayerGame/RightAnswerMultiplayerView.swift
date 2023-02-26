//
//  RightAnswerMultiplayerView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-26.
//

import SwiftUI

struct RightAnswerMultiplayerView: View {
    @Binding var currentScene: String
    @Binding var score: Int
    @Binding var rounds: Int
    @EnvironmentObject var socketManager: SocketManager

    
    var body: some View {
        VStack {
            Text("RIGHT ANSWER")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            VStack {
                ForEach(socketManager.users.sorted(by: { $0.score < $1.score }), id: \.id) { user in
                    HStack {
                        Circle()
                            .foregroundColor(user.color)
                            .frame(width: 20, height: 20)
                        Text(user.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(user.score))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(user.currentRound))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                    }
                    .padding(.horizontal, 16)
                }
            }
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                    .modifier(ParticlesModifier())
                    .offset(x: -100, y : -50)
                        
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .modifier(ParticlesModifier())
                    .offset(x: 60, y : 70)
            }
            Spacer()
            
        }
        .onAppear {
            withAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if rounds > 0 {
                        socketManager.currentScene = "MainMultiplayer"
                    } else {
                        socketManager.currentScene = "GameOverMultiplayer"
                    }
                    
                }
            }
        }
    }
}
