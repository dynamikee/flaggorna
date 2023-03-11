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
    @State private var gameCode: String = ""
    @State private var joinOrStart = true
    @State private var showStartButton = false
    
    @EnvironmentObject var socketManager: SocketManager

    private let userDefaults = UserDefaults.standard
    
    private func loadUserData() {
        if let name = userDefaults.string(forKey: "userName") {
            self.name = name
        }
        if let colorString = userDefaults.string(forKey: "userColor"),
           let color = colors.first(where: { colorToString[$0] == colorString }) {
            self.color = color
        } else {
            self.color = colors.randomElement()!
        }
    }

    
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
        
        if joinOrStart {
            VStack {
                Spacer()

                HStack {
                    Text("JOIN GAME :")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    
                    TextField("Code", text: $gameCode)
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 112)

                    Button(action: {
                        joinOrStart = false
                        socketManager.setGameCode(gameCode)
                        
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
                
                Spacer()
                
                Button(action: {
                    joinOrStart = false
                    let code = String(format: "%04d", arc4random_uniform(9000) + 1000)
                    gameCode = code
                    socketManager.setGameCode(code)
                }){
                    Text("HOST NEW GAME")
                }
                .buttonStyle(OrdinaryButtonStyle())
                .padding()
                
            }
            .onAppear {
                loadUserData()
                // Choose a random color for the user
                self.socketManager.socket.connect()
                self.socketManager.startUsersTimer()
                self.currentRound = rounds
                //self.color = colors.randomElement()!
            }
            
        } else {
            VStack {
                Text("GAME CODE \(gameCode)")
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
                    Button(action: {
                        let url = URL(string: "https://mygame.com")!
                            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                            UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Invite friends")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .foregroundColor(.white)
                        }
                        .padding()
                    
                }

                Spacer()
                
                if showStartButton {
                    Button(action: {
                        self.socketManager.stopUsersTimer()
                        SocketManager.shared.currentScene = "GetReadyMultiplayer"
                        let flagQuestion = generateFlagQuestion()
                        
                        let message: [String: Any] = ["type": "startGame", "question": flagQuestion.toDict()]
                        print(message)
                        let jsonData = try? JSONSerialization.data(withJSONObject: message)
                        let jsonString = String(data: jsonData!, encoding: .utf8)!
                        socketManager.send(jsonString)
                        print(jsonString)
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
            
        }
        
        

    }

    private func join() {
        let user = User(id: UUID(), name: name, color: color, score: score, currentRound: currentRound)
        
        // Save user data to UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(name, forKey: "userName")
        defaults.set(colorToString[color], forKey: "userColor")
        
        socketManager.addUser(user)
        socketManager.currentUser = user
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







