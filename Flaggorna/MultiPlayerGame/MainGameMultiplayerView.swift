//
//  MainGameMultiplayerView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-22.
//

import SwiftUI

struct MainGameMultiplayerView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int
    @EnvironmentObject var currentUser: User
    
    @EnvironmentObject var socketManager: SocketManager


    var body: some View {
        VStack {
            if let question = socketManager.currentQuestion {
                HStack {
                    Text("Score: \(score)")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    Spacer()
                    Text("Round: \(rounds)")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
                .padding(24)

                Spacer()
                Image(question.flag)
                    .resizable()
                    .border(.gray, width: 1)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.width * 0.8)

                Spacer()
                VStack(spacing: 24) {
                    ForEach(question.answerOptions, id: \.self) { option in
                        Button(action: {
                            if option == question.correctAnswer {

                                
                                
                                socketManager.countries.removeAll { $0.name == question.correctAnswer }
                                
                                
                                socketManager.currentScene = "RightMultiplayer"
                                
                            } else {
                                if rounds > 0 {
                                    rounds -= 1
                                }
                                socketManager.countries.removeAll { $0.name == question.correctAnswer }
                                socketManager.currentScene = "WrongMultiplayer"
                            }
                        }) {
                            Text(option)
                        }
                        .buttonStyle(CountryButtonStyle())
                    }
                }
                .padding(8)
            } else {
                ProgressView()
            }
        }
    }
}
