//
//  MainGameMultiplayerView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-22.
//

import SwiftUI
import SceneKit
import UIKit

struct MainGameMultiplayerView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int
    
    @EnvironmentObject var socketManager: SocketManager
    
    @State private var timeRemaining = 4 // 4 seconds timer
    @State private var answered = false
    
    @State private var scene = SCNScene()

    var body: some View {
        VStack {
            ProgressView(value: Double(timeRemaining), total: 4) {
                
            }
            .frame(height: 10)
            .progressViewStyle(MyProgressViewStyle())
            .animation(.linear(duration: 1), value: timeRemaining) // Add an animation modifier with a linear timing curve

            
            if let question = socketManager.currentQuestion {

                Spacer()
                
                SceneViewContainer(scene: scene, randomCountry: question.flag)

                    .padding(.horizontal, 24)
                
                
//                Image(question.flag)
//                    .resizable()
//                    .border(.gray, width: 1)
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: UIScreen.main.bounds.width * 0.8)

                Spacer()
                VStack(spacing: 24) {
                    
                    ForEach(question.answerOptions, id: \.self) { option in

                                            Button(action: {
                            if option == question.correctAnswer {
                                answered = true
                                socketManager.countries.removeAll { $0.name == question.correctAnswer }
                                socketManager.currentUser!.score += 1
                                
                                if rounds > 0 {
                                    socketManager.currentUser!.currentRound -= 1
                                    rounds -= 1
                                }
                                
                                socketManager.currentScene = "RightMultiplayer"
                                socketManager.updateUser()
                                print("Number of remaining countries: \(socketManager.countries.count)")

                                
                            } else {
                                answered = true
                                if rounds > 0 {
                                    socketManager.currentUser!.currentRound -= 1
                                    rounds -= 1
                                }
                                socketManager.countries.removeAll { $0.name == question.correctAnswer }
                                socketManager.currentScene = "WrongMultiplayer"
                                socketManager.updateUser()
                                print("Number of remaining countries: \(socketManager.countries.count)")

                                
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
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if answered {
                    timer.invalidate()
                } else {
                    if self.timeRemaining > 0 {
                        self.timeRemaining -= 1
                    } else {
                        timer.invalidate()
                        socketManager.currentUser!.currentRound -= 1
                        rounds -= 1
                        socketManager.countries.removeAll { $0.name == socketManager.currentQuestion?.correctAnswer }
                        socketManager.currentScene = "WrongMultiplayer"
                        socketManager.updateUser()
                        print("Number of remaining countries: \(socketManager.countries.count)")

                    }
                }
                
            }
        }
    }
}

struct MyProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        let percent = configuration.fractionCompleted ?? 0
        return ZStack(alignment: .leading) {
            // Gray background bar
            RoundedRectangle(cornerRadius: 0)
                .foregroundColor(.gray.opacity(0.2))
            
            // Green progress bar
            RoundedRectangle(cornerRadius: 0)
                .frame(width: percent * UIScreen.main.bounds.width, height: 10)
                .foregroundColor(.white)
            
            // Label with time remaining
            //configuration.label
        }
    }
}



