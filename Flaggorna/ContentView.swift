
import SwiftUI
import Starscream

struct ContentView: View {
    @State var currentScene = "Start"
    @State var countries: [Country] = []
    @State var score = 0
    @State var rounds = 0
    @State var multiplayer: Bool = false
    @EnvironmentObject var socketManager: SocketManager

    var body: some View {
        ZStack {
            Color(UIColor(red: 0.11, green: 0.11, blue: 0.15, alpha: 1.00))
                    .edgesIgnoringSafeArea(.all)
            
            if multiplayer {
                switch SocketManager.shared.currentScene {
                case "JoinMultiplayer":
                    JoinMultiplayerView(currentScene: $currentScene, countries: $countries, rounds: $rounds)
                case "GetReadyMultiplayer":
                    GetReadyMultiplayerView(currentScene: $currentScene, rounds: $rounds)
                case "MainMultiplayer":
                    MainGameMultiplayerView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds)
                case "RightMultiplayer":
                    RightAnswerMultiplayerView(currentScene: $currentScene, score: $score, rounds: $rounds, countries: $countries)
                case "WrongMultiplayer":
                    WrongAnswerMultiplayerView(currentScene: $currentScene, rounds: $rounds, countries: $countries)
                case "GameOverMultiplayer":
                    GameOverMultiplayerView(currentScene: $currentScene, score: $score, multiplayer: $multiplayer)
                default:
                    JoinMultiplayerView(currentScene: $currentScene, countries: $countries, rounds: $rounds)
                }
                
                
            } else {
                switch currentScene {
                case "Start":
                    StartGameView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds, multiplayer: $multiplayer)
                case "GetReady":
                    GetReadyView(currentScene: $currentScene)
                case "Main":
                    MainGameView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds)
                case "Right":
                    RightAnswerView(currentScene: $currentScene, score: $score, rounds: $rounds)
                case "Wrong":
                    WrongAnswerView(currentScene: $currentScene, score: $score, rounds: $rounds)
                case "GameOver":
                    GameOverView(currentScene: $currentScene, score: $score)
                default:
                    StartGameView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds, multiplayer: $multiplayer)
                }
            }
        }
    }
}

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

    //private var currentSceneBinding: Binding<String>?
    
    override init() {
        let url = URL(string: "wss://eu-1.lolo.co/uGPiCKZAeeaKs83jaRaJiV/socket")!
        let request = URLRequest(url: url)
        socket = WebSocket(request: request)
        _currentScene = Published(initialValue: "Start")
        countries = []
        gameCode = ""
        super.init()
        socket.delegate = self
    }
    
    func send(_ message: String) {
        socket.write(string: message)
    }
    
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {

        switch event {
        case .connected(_):
            loadData()
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
                                   let userScoreString = userDict["score"] as? String,
                                   let userCurrentRoundString = userDict["currentRound"] as? String {
                                    let newUser = User(id: userID, name: userName, color: color(for: userColorString), score: Int(userScoreString) ?? 0, currentRound: Int(userCurrentRoundString) ?? 0)
                                    newUsers.insert(newUser)
                                }
                                
                            }
                            DispatchQueue.main.async { [weak self] in
                                self?.users.formUnion(newUsers)
                                self?.objectWillChange.send()
                            }
                        }
                        
                    case "startGame":
                        guard let messageGameCode = json["gameCode"] as? String,
                              messageGameCode == self.gameCode else {
                            // Invalid game code, do nothing
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
            "users": usersArray.map { ["id": $0.id.uuidString, "name": $0.name, "color": colorToString[$0.color] ?? "", "score": String($0.score), "currentRound": String($0.currentRound)] }
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: usersDict, options: []),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            socket.write(string: jsonString)
            print("Sending users array")
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
    
    private func loadData() {
        let file = Bundle.main.path(forResource: "countries", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: file))
        let decoder = JSONDecoder()
        self.countries = try! decoder.decode([Country].self, from: data)
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

struct FlagQuestion: Codable {
    let flag: String
    let answerOptions: [String]
    let correctAnswer: String

    init(flag: String, answerOptions: [String], correctAnswer: String) {
        self.flag = flag
        var shuffledAnswerOptions = answerOptions
        shuffledAnswerOptions.shuffle()
        self.answerOptions = shuffledAnswerOptions
        self.correctAnswer = correctAnswer
    }
}

struct StartMessage: Codable {
    let type: String
    let gameCode: String
    let question: FlagQuestion
}




struct Country: Codable, Hashable {
    var name: String
    var flag: String
}

class User: ObservableObject, Hashable, Identifiable {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    @Published var id: UUID
    @Published var name: String
    @Published var color: Color
    @Published var score: Int
    @Published var currentRound: Int
    
    init(id: UUID = UUID(), name: String, color: Color, score: Int = 0, currentRound: Int = 0, wifiName: String = "") {
        self.id = id
        self.name = name
        self.color = color
        self.score = score
        self.currentRound = currentRound
    }
}



struct CountryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
            configuration.label
            .frame(width: UIScreen.main.bounds.width * 0.8, alignment: .leading)
                .padding(15)
                .background(Color(UIColor(red: 0.22, green: 0.22, blue: 0.25, alpha: 1.00)))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 8)
                )
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
                
        }
}

struct OrdinaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
            configuration.label
            
                .padding(15)
                .background(Color(UIColor(red: 0.22, green: 0.22, blue: 0.25, alpha: 1.00)))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 8)
                )
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
                
        }
}



struct FireworkParticlesGeometryEffect : GeometryEffect {
    var time : Double
    var speed = Double.random(in: 20 ... 200)
    var direction = Double.random(in: -Double.pi ...  Double.pi)
    
    var animatableData: Double {
        get { time }
        set { time = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        let xTranslation = speed * cos(direction) * time
        let yTranslation = speed * sin(direction) * time
        let affineTranslation =  CGAffineTransform(translationX: xTranslation, y: yTranslation)
        return ProjectionTransform(affineTranslation)
    }
}

struct ParticlesModifier: ViewModifier {
    @State var time = 0.0
    @State var scale = 0.1
    let duration = 3.0
    
    func body(content: Content) -> some View {
        ZStack {
            ForEach(0..<80, id: \.self) { index in
                content
                    .hueRotation(Angle(degrees: time * 80))
                    .scaleEffect(scale)
                    .modifier(FireworkParticlesGeometryEffect(time: time))
                    .opacity(((duration-time) / duration))
            }
        }
        .onAppear {
            withAnimation (.easeOut(duration: duration)) {
                self.time = duration
                self.scale = 1.0
            }
        }
    }
}

