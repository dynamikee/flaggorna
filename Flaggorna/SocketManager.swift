//
//  SocketManager.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-06-27.
//

import SwiftUI
import Starscream
import CoreData


class SocketManager: NSObject, ObservableObject, WebSocketDelegate {
    static let shared = SocketManager()
    @Published var users: Set<User> = []
    @Published var currentScene: String

    //let objectWillChange = ObservableObjectPublisher()
    internal var socket: WebSocket
    var countries: [Country]
    var usersTimer: Timer?
    @Published var currentQuestion: FlagQuestion?
    @Published var currentUser: User?
    var gameCode: String
    var rounds: Int
    var score: Int

    //private var currentSceneBinding: Binding<String>?
    
    override init() {
        let url = URL(string: "wss://eu-1.lolo.co/uGPiCKZAeeaKs83jaRaJiV/socket")!
        let request = URLRequest(url: url)
        socket = WebSocket(request: request)
        _currentScene = Published(initialValue: "Start")
        countries = []
        gameCode = ""
        rounds = 10
        score = 0
        super.init()
        socket.delegate = self
    }
    
    func send(_ message: String) {
        socket.write(string: message)
    }
    
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {

        switch event {
        case .connected(_):
            break
        case .disconnected(_):
            break
            
        case .text(let string):
            if let data = string.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let type = json["type"] as? String {
                    switch type {
                    case "usersArray":
                        if let usersArray = json["users"] as? [[String: Any]], let messageGameCode = json["gameCode"] as? String,
                           messageGameCode == gameCode {
                            var newUsers = Set<User>()
                            for userDict in usersArray {
                                if let userIDString = userDict["id"] as? String,
                                   let userID = UUID(uuidString: userIDString),
                                   let userName = userDict["name"] as? String,
                                   let userColorString = userDict["color"] as? String,
                                   let userFlagString = userDict["flag"] as? String,
                                   let userScoreString = userDict["score"] as? String,
                                   let userCurrentRoundString = userDict["currentRound"] as? String {
                                    let newUser = User(id: userID, name: userName, color: color(for: userColorString), flag: userFlagString, score: Int(userScoreString) ?? 0, currentRound: Int(userCurrentRoundString) ?? 0)
                                    newUsers.insert(newUser)
                                }
                                
                            }
                            DispatchQueue.main.async { [weak self] in
                                self?.users.formUnion(newUsers)
                                self?.objectWillChange.send()
                            }
                        }
                        
                    case "userRemoval":
                        if let gameCode = json["gameCode"] as? String,
                           let userIdString = json["userId"] as? String,
                           let userId = UUID(uuidString: userIdString) {
                            DispatchQueue.main.async { [weak self] in
                                if self?.gameCode == gameCode,
                                   let user = self?.users.first(where: { $0.id == userId }) {
                                    self?.users.remove(user)
                                    self?.objectWillChange.send()
                                }
                            }
                        }

                        
                    case "startGame":
                        guard let messageGameCode = json["gameCode"] as? String,
                              messageGameCode == self.gameCode else {
                            // Invalid game code, do nothing
                            return
                        }
                        if (self.currentUser == nil) {
                            return
                        }
                        
                        guard let jsonQuestion = json["question"] as? [String: Any],
                              let flag = jsonQuestion["flag"] as? String,
                              let answerOptions = jsonQuestion["answerOptions"] as? [String],
                              let correctAnswer = jsonQuestion["correctAnswer"] as? String else {
                            // Error handling for when the JSON message is malformed, missing necessary fields,
                            // or game code is incorrect
                            return
                        }
                        print("Anser options as we recieve them in the startmessage")
                        print(answerOptions)
                        
                        let question = FlagQuestion(flag: flag, answerOptions: answerOptions, correctAnswer: correctAnswer)
                        
                        DispatchQueue.main.async { [weak self] in
                            
                            self?.stopUsersTimer()
                            self?.currentScene = "GetReadyMultiplayer"
                            self?.objectWillChange.send()
                            self?.currentQuestion = question
                            
                            let message: [String: Any] =
                            ["type": "flagQuestion",
                             "gameCode": self?.gameCode,
                            "question": ["flag": question.flag,
                                         "answerOptions": question.answerOptions,
                                         "correctAnswer": question.correctAnswer]]
                            guard let jsonData = try? JSONSerialization.data(withJSONObject: message) else {
                                return
                            }
                            
                            let jsonString = String(data: jsonData, encoding: .utf8)!
                            self?.send(jsonString)
                        }

                    case "restoreGame":
                        rounds = 10
                        score = 0
                        
                    case "flagQuestion":
                        guard let messageGameCode = json["gameCode"] as? String,
                              messageGameCode == self.gameCode else {
                            // Invalid game code, do nothing
                            return
                        }
                        
                        guard let jsonQuestion = json["question"] as? [String: Any],
                              let flag = jsonQuestion["flag"] as? String,
                              let answerOptions = jsonQuestion["answerOptions"] as? [String],
                              let correctAnswer = jsonQuestion["correctAnswer"] as? String
                                
                     else {
                        // Error handling for when the JSON message is malformed, missing necessary fields,
                            // or game code is incorrect
                            return
                        }
                        
                        let question = FlagQuestion(flag: flag, answerOptions: answerOptions, correctAnswer: correctAnswer)
                        self.currentQuestion = question

                        
                    case "updateScore":
                        
                        guard let scoreUpdate = json["update"] as? [[String: Any]], let messageGameCode = json["gameCode"] as? String,
                              messageGameCode == gameCode else {
                            print("Missing or malformed users array")
                            return
                        }
                        
                        for userDict in scoreUpdate {
                            guard let userIDString = userDict["id"] as? String,
                                  let userID = UUID(uuidString: userIDString),
                                  let userCurrentRoundString = userDict["currentRound"] as? String,
                                  let userCurrentRound = Int(userCurrentRoundString),
                                  let userScoreString = userDict["score"] as? String,
                                  let userScore = Int(userScoreString)
                            else {
                                print("Missing or malformed user fields")
                                continue
                            }
                            
                            DispatchQueue.main.async { [weak self] in
                                for user in self!.users {
                                    if user.id == userID {
                                        user.currentRound = userCurrentRound
                                        user.score = userScore
                                        
                                        
                                    }
                                }
                                self?.objectWillChange.send()

                            }

                        }
                        
                    case "resetGame":

                        
                        guard let messageGameCode = json["gameCode"] as? String, messageGameCode == gameCode else {
                                print("Missing or malformed game code")
                                return
                            }
                        //reset the number of countries
                        FlagDataManager.loadDataAndUpdateFlagData() { countries in
                            self.countries = countries
                        }
                        
                        // Reset the rounds and scores of all users in the game
                        for user in users {
                            user.currentRound = 10
                            user.score = 0
                        }
                        DispatchQueue.main.async { [weak self] in
                            self?.objectWillChange.send()
                                
                        }
                            

                    default:
                        print("Received unknown message type: \(type)")
                    }
                    
                }
            }


        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            break
            //isConnected = false
        case .error(let error):
            //isConnected = false
            //handleError(error)
            break
        }
    }
    
    
    func setGameCode(_ code: String) {
            self.gameCode = code
    }
    
    func addUser(_ user: User) {
        self.users.insert(user)
        self.objectWillChange.send()
        sendUsersArray()
    }
    
    func updateUser() {
        //Updating the Users set with the new score and round number from the local currentUser variable
        guard let currentUser = self.currentUser else {
            return
        }
        for user in self.users {
            if user.id == currentUser.id {
                user.score = currentUser.score
                user.currentRound = currentUser.currentRound
                
                break
            }
        }
        sendScoreAndRoundUpdate()
    }

    func startUsersTimer() {
        stopUsersTimer() // make sure only one timer is running at a time
        usersTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            if !(self?.users.isEmpty ?? true) {
                self?.sendUsersArray()
            }
        }
    }

    func stopUsersTimer() {
        usersTimer?.invalidate()
        usersTimer = nil
    }

    func sendUsersArray() {
        let usersArray = Array(self.users)
        let usersDict: [String: Any] = [
            "type": "usersArray",
            "gameCode": self.gameCode,
            "users": usersArray.map { ["id": $0.id.uuidString, "name": $0.name, "color": colorToString[$0.color] ?? "", "flag": $0.flag, "score": String($0.score), "currentRound": String($0.currentRound)] }
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: usersDict, options: []),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            socket.write(string: jsonString)
            print("Sending users array")
            print(jsonString)
        }
    }
    
    func sendUserRemoval(_ user: User) {
        let removalDict: [String: Any] = [
            "type": "userRemoval",
            "gameCode": self.gameCode,
            "userId": user.id.uuidString
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: removalDict, options: []),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            socket.write(string: jsonString)
            print("Sending user removal")
            print(jsonString)
        }
    }

    
    func sendScoreAndRoundUpdate() {
        guard let currentUser = currentUser else {
            return
        }
        let userDict: [String: Any] = [
            "type": "updateScore",
            "gameCode": self.gameCode,
            "update": [
                [
                    "id": currentUser.id.uuidString,
                    "score": String(currentUser.score),
                    "currentRound": String(currentUser.currentRound)
                ]
            ]
        ]
        print(userDict)

        if let jsonData = try? JSONSerialization.data(withJSONObject: userDict, options: []),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            socket.write(string: jsonString)
            print("Send Score And Round Update")
            print(jsonString)
        }
    }
    
    func generateFlagQuestion() -> FlagQuestion {
        let randomCountry = self.countries.randomElement()!
        let currentCountry = randomCountry.name
        let countryAlternatives = self.countries.filter { $0.name != currentCountry }
        let answerOptions = countryAlternatives.shuffled().prefix(3).map { $0.name } + [currentCountry]
        let correctAnswer = currentCountry
        let flag = randomCountry.flag

        return FlagQuestion(flag: flag, answerOptions: answerOptions, correctAnswer: correctAnswer)
    }
    
    func loadData() {
        FlagDataManager.loadDataAndUpdateFlagData() { countries in
            self.countries = countries
        }
}
    
    
    
    func color(for string: String) -> Color {
        switch string {
        case ".red":
            return Color.red
        case ".green":
            return Color.green
        case ".blue":
            return Color.blue
        case ".orange":
            return Color.orange
        case ".pink":
            return Color.pink
        case ".purple":
            return Color.purple
        case ".yellow":
            return Color.yellow
        case ".teal":
            return Color.teal
        case ".gray":
            return Color.gray
        default:
            return Color.white
        }
    }
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
    
}
