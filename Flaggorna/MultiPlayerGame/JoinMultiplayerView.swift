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
    @Binding var multiplayer: Bool

    @State private var name: String = ""
    @State private var color: Color = .white
    @State private var score: Int = 0
    @State private var currentRound: Int = 0
    @State private var gameCode: String = ""
    @State private var joinOrStart = true
    @State private var showStartButton = false
    @State private var showHostButton = true
    
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
        VStack {
            HStack {
                Button(action: {
                    socketManager.users = []
                    multiplayer = false
                    socketManager.countries = []
                    currentScene = "Start"
                    
                }) {
                    Text(Image(systemName: "arrow.backward"))
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            Spacer()
        }
        .padding()
        
        
        if joinOrStart {
            VStack (spacing: 10) {
                Spacer()
                HStack{
                    Text("JOIN GAME :")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
                HStack {
                    
                    TextField("Enter Game Code", text: $gameCode)
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .onTapGesture {
                                            showHostButton = false
                                        }
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

                }
                Spacer()
                if showHostButton {
                    Button(action: {
                        joinOrStart = false
                        let code = String(format: "%04d", arc4random_uniform(9000) + 1000)
                        gameCode = code
                        socketManager.setGameCode(code)
                    }){
                        Text("HOST NEW GAME")
                    }
                    .buttonStyle(OrdinaryButtonStyle())
                } else {
                    
                }

            }
            .padding()
            .onAppear {
                loadUserData()
                self.socketManager.socket.connect()
                self.socketManager.startUsersTimer()
                self.currentRound = rounds
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
                    }
                    if showStartButton {
                        Button(action: {
                            let appURL = URL(string: "https://apple.co/3LfGM7G")!
                                let appName = "Flag Party Quiz App - Flaggorna"
                                let appIcon = UIImage(named: "AppIcon")! // Replace "AppIcon" with the name of your app icon image asset
                                
                                let activityViewController = UIActivityViewController(activityItems: [appIcon, "I challenge you on a flag quiz! Join the game with code \(gameCode). Download the \(appName) if you havent already", appURL], applicationActivities: nil)
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
                    } else {
                        
                    }
                    
                }
                Spacer()
                if showStartButton {
                    Button(action: {
                        self.socketManager.stopUsersTimer()
                        SocketManager.shared.currentScene = "GetReadyMultiplayer"
                    
                        let flagQuestion = generateFlagQuestion()
                        let startMessage = StartMessage(type: "startGame", gameCode: gameCode, question: flagQuestion)
                        let jsonData = try? JSONEncoder().encode(startMessage)
                        let jsonString = String(data: jsonData!, encoding: .utf8)!
                        socketManager.send(jsonString)
                    }){
                        Text("START GAME")
                    }
                    .padding()
                    .buttonStyle(OrdinaryButtonStyle())
                } else {
                    HStack {
                        Circle()
                            .foregroundColor(color)
                            .frame(width: 40)
                        TextField("Enter your name", text: $name)
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundColor(.white)
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
                    }
                }
            }
            .padding()
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

        return FlagQuestion(flag: flag, answerOptions: answerOptions, correctAnswer: correctAnswer)
    }



}







