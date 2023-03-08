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
    @Binding var countries: [Country]

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
                    let flagQuestion = generateFlagQuestion()
                    SocketManager.shared.currentScene = "GetReadyMultiplayer"
                    let message: [String: Any] = ["type": "startGame", "question": flagQuestion.toDict(), "answerOrder": flagQuestion.answerOrder]
                    print(message)
                    let jsonData = try? JSONSerialization.data(withJSONObject: message)
                    let jsonString = String(data: jsonData!, encoding: .utf8)!
                    socketManager.send(jsonString)
                    print(jsonString)
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
    func generateFlagQuestion() -> FlagQuestion {
        let randomCountry = countries.randomElement()!
        let currentCountry = randomCountry.name
        let countryAlternatives = countries.filter { $0.name != currentCountry }
        let answerOptions = countryAlternatives.shuffled().prefix(3).map { $0.name } + [currentCountry]
        let correctAnswer = currentCountry
        let flag = randomCountry.flag
        let answerOrder = Array(0..<answerOptions.count).shuffled()

        return FlagQuestion(flag: flag, answerOptions: answerOptions, correctAnswer: correctAnswer, answerOrder: answerOrder)
    }
    
}


