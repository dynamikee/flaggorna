//
//  JoinMultiplayerView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-19.
//

import SwiftUI

struct JoinMultiplayerView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var rounds: Int
    @State private var name: String = ""
    @State private var color: Color = .white
    @State private var score: Int = 0
    @State private var currentRound: Int = 0
    @State private var showStartButton = false
    
    @EnvironmentObject var socketManager: SocketManager

    
    private let colors = [
        Color.red, Color.green, Color.blue, Color.orange, Color.pink, Color.purple,
        Color.yellow, Color.teal, Color.gray
    ]
    
    let colorToString: [Color: String] = [
        .red: ".red",
        .green: ".green",
        .blue: ".blue",
        .orange: ".orange",
        .pink: ".pink",
        .purple: ".purple",
        .yellow: ".yellow",
        .teal: ".teal",
        .gray: ".gray"
    ]
    
    var body: some View {
        
        VStack {
            Text("Players:")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(socketManager.users.sorted(by: { $0.name < $1.name }), id: \.id) { user in
                    HStack {
                        Circle()
                            .foregroundColor(user.color)
                            .frame(width: 20, height: 20)
                        Text(user.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
            }

            Spacer()
            
            if showStartButton {
                Button(action: {
                    self.socketManager.stopUsersTimer()
                    SocketManager.shared.currentScene = "GetReadyMultiplayer"
                    let message: [String: Any] = ["type": "startGame"]
                    let jsonData = try? JSONSerialization.data(withJSONObject: message)
                    let jsonString = String(data: jsonData!, encoding: .utf8)!
                    socketManager.send(jsonString)
                }){
                    Text("START GAME")
                }
                .buttonStyle(OrdinaryButtonStyle())
                .padding()

            } else {
                HStack {
                    Circle()
                        .foregroundColor(color)
                        .frame(width: 40)
                    TextField("Enter your name", text: $name)
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .padding()
                    Button(action: {
                        join()
                        showStartButton = true
                    }) {
                        Text(Image(systemName: "arrow.forward"))
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        
                    }
                    .disabled(name.isEmpty)
                    .padding()

                }
                .padding()
            }
        }
        .onAppear {
            // Choose a random color for the user
            self.socketManager.socket.connect()
            self.socketManager.startUsersTimer()
            self.currentRound = rounds
            self.color = colors.randomElement()!
        }
    }

    private func join() {
        let user = User(id: UUID(), name: name, color: color, score: score, currentRound: currentRound)
        //name = ""
        socketManager.addUser(user)
        socketManager.currentUser = user
        print("Detta är den lokala användaren")
        print(socketManager.currentUser?.name)
        
        
    }
    
    func generateFlagQuestion() -> FlagQuestion {
        let randomCountry = countries.randomElement()!
        let currentCountry = randomCountry.name
        let countryAlternatives = countries.filter { $0.name != currentCountry }
        let answerOptions = countryAlternatives.shuffled().prefix(3).map { $0.name } + [currentCountry]
        let correctAnswer = currentCountry
        let flag = randomCountry.flag

        return FlagQuestion(flag: flag, answerOptions: answerOptions, correctAnswer: correctAnswer)
    }
}


