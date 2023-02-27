//
//  WrongAnswerMultiplayerView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-26.
//

import SwiftUI

struct WrongAnswerMultiplayerView: View {
    @Binding var currentScene: String
    @Binding var rounds: Int
    @EnvironmentObject var socketManager: SocketManager
    @State private var showNextButton: Bool = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("Oh no!")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)

            let rightAnswer = socketManager.currentQuestion?.correctAnswer
            Text("It was \(rightAnswer!)")
                .font(.title3)
                .fontWeight(.bold)
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
            Spacer()
            if showNextButton {
                Button(action: {
                    //self.socketManager.stopUsersTimer()
                    SocketManager.shared.currentScene = "GetReadyMultiplayer"
                    let message: [String: Any] = ["type": "startGame"]
                    let jsonData = try? JSONSerialization.data(withJSONObject: message)
                    let jsonString = String(data: jsonData!, encoding: .utf8)!
                    socketManager.send(jsonString)
                }){
                    Text("NEXT QUESTION")
                }
                .buttonStyle(OrdinaryButtonStyle())
                .padding()

            }
        }
        .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if socketManager.users.filter({ $0.currentRound == rounds }).count == socketManager.users.count {
                            if rounds > 0 {
                                showNextButton = true
                            } else {
                                socketManager.currentScene = "GameOverMultiplayer"
                            }
                        } else {
                            print("Alla har inte svarat")
                        }
                        
                    }
                }
    }
    
}


