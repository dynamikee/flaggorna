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
    @Binding var multiplayer: Bool
    //@Binding var gameCode: String
    
    @EnvironmentObject var socketManager: SocketManager

    var body: some View {
        VStack(spacing: 32)  {
            Spacer()
            Text("TOP LIST")
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
            Spacer()
            
                Button(action: {
                    //self.socketManager.stopUsersTimer()
                    
                    //socketManager.users = []
                    //multiplayer = false
                    socketManager.loadData()
                    socketManager.countries = []
                    //self.socketManager.socket.disconnect()

                    SocketManager.shared.currentScene = "JoinMultiplayer"


                }){
                    Text("PLAY AGAIN")
                }
                .buttonStyle(OrdinaryButtonStyle())
                .padding()
            Button(action: {
                //self.socketManager.stopUsersTimer()
                
                socketManager.users = []
                multiplayer = false
                socketManager.countries = []
                self.socketManager.socket.disconnect()

                
                currentScene = "Start"

            }){
                Text("DONE")
            }
            .buttonStyle(OrdinaryButtonStyle())
            .padding()

            
            
        }
        .onAppear() {
            

        }
    }
}
