//
//  GameOverMultiplayerView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-03-06.
//

import SwiftUI

struct GameOverMultiplayerView: View {
    @Binding var currentScene: String
    @Binding var score: Int
    @Binding var rounds: Int
    @Binding var multiplayer: Bool
    //@Binding var gameCode: String
    
    @EnvironmentObject var socketManager: SocketManager

    var body: some View {
        VStack(spacing: 32)  {
            Spacer()
            Text("GAME OVER!")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)

            VStack {
                ForEach(socketManager.users.sorted(by: { $0.score < $1.score }).reversed(), id: \.id) { user in
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
            
                Button(action: {
                    
                    score = 0
                    
                    resetGame()
                    socketManager.loadData()
                    
                    SocketManager.shared.currentScene = "GetReadyMultiplayer"
                    
                    let flagQuestion = socketManager.generateFlagQuestion()
                    let startMessage = StartMessage(type: "startGame", gameCode: socketManager.gameCode, question: flagQuestion)
                    let jsonData = try? JSONEncoder().encode(startMessage)
                    let jsonString = String(data: jsonData!, encoding: .utf8)!
                    socketManager.send(jsonString)


                }){
                    Text("PLAY AGAIN")
                }
                .buttonStyle(OrdinaryButtonStyle())
                .padding()
            
            Spacer()

            
            Button(action: {
                //self.socketManager.stopUsersTimer()
                
                socketManager.users = []
                multiplayer = false
                socketManager.countries = []
                self.socketManager.socket.disconnect()
                currentScene = "Start"

            }){
                Text(Image(systemName: "xmark"))
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                
            }
            .padding()

            
            
        }
        .onAppear() {
            rounds = 10

        }
    }
    func resetGame() {
        // Reset the rounds and scores of all users in the game
        for user in socketManager.users {
            user.currentRound = 10
            user.score = 0
        }
        
        // Send a message to all users to inform them of the reset
        let resetMessage = ResetMessage(type: "resetGame", gameCode: socketManager.gameCode)
        let jsonData = try? JSONEncoder().encode(resetMessage)
        let jsonString = String(data: jsonData!, encoding: .utf8)!
        socketManager.send(jsonString)
    }
}


