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
    @Binding var numberOfRounds: Int
    @Binding var countries: [Country]
    @Binding var selectedContinents: [String]

    @EnvironmentObject var socketManager: SocketManager
    @State private var showNextButton: Bool = false
    
    var body: some View {
        VStack(spacing: 32) {
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
            .padding()
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
                        Image(user.flag)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64)
                            .clipShape(Circle())
                        //.border(sortedFlagData == data ? Color.blue : Color.clear, width: 2)
                            .padding(.trailing, 8)
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(user.score))
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .padding(.trailing, 8)
                        
                    }
                }
            }
            .padding()
            Spacer()
            if showNextButton {
                Button(action: {
                    let flagQuestion = generateFlagQuestion()
                    SocketManager.shared.currentScene = "GetReadyMultiplayer"
                    let startMessage = StartMessage(type: "startGame", gameCode: socketManager.gameCode, question: flagQuestion, selectedContinents: socketManager.selectedContinents)
                    let jsonData = try? JSONEncoder().encode(startMessage)
                    let jsonString = String(data: jsonData!, encoding: .utf8)!
                    socketManager.send(jsonString)
                }){
                    Text("NEXT QUESTION")
                }
                .buttonStyle(OrdinaryButtonStyle())
                .padding()

            } else {
                //TODO - remove this workaround to make the layout not move when the next question button appears.
                Button(action: {}) {
                    Text("NEXT QUESTION")
                        .opacity(0)
                }
                .buttonStyle(OrdinaryButtonStyle())
                .padding()
                .opacity(0)
            }
        }
        .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        if socketManager.users.filter({ $0.currentRound == rounds }).count == socketManager.users.count {
                            if rounds > 0 {
                                showNextButton = true
                            } else {
                                socketManager.currentScene = "GameOverMultiplayer"
                            }
                        }
                        
                    }
                }
    }
    func generateFlagQuestion() -> FlagQuestion {
        let randomCountry = socketManager.countries.randomElement()!
        let currentCountry = randomCountry.name
        let countryAlternatives = socketManager.countries.filter { $0.name != currentCountry }
        let answerOptions = countryAlternatives.shuffled().prefix(3).map { $0.name } + [currentCountry]
        let correctAnswer = currentCountry
        let flag = randomCountry.flag

        return FlagQuestion(flag: flag, answerOptions: answerOptions, correctAnswer: correctAnswer)
    }
    
}


