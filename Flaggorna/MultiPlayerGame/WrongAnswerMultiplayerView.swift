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
    
    var body: some View {
        VStack {
            Text("WRONG ANSWER")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            let rightAnswer = socketManager.currentQuestion?.correctAnswer
            Text("It's \(rightAnswer!)")
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
            Spacer()
        }
    }
}
