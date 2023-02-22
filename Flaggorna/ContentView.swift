
import SwiftUI
import Starscream

struct ContentView: View {
    @State var currentScene = "Start"
    @State var countries: [Country] = []
    @State var score = 0
    @State var rounds = 3
    @State var multiplayer: Bool = false
    @EnvironmentObject var socketManager: SocketManager

    var body: some View {
        ZStack {
            Color(UIColor(red: 0.11, green: 0.11, blue: 0.15, alpha: 1.00))
                    .edgesIgnoringSafeArea(.all)
            
            if multiplayer {
                switch SocketManager.shared.currentScene {
                case "JoinMultiplayer":
                    JoinMultiplayerView(currentScene: $currentScene, countries: $countries)
                case "GetReadyMultiplayer":
                    GetReadyMultiplayerView(currentScene: $currentScene)
                case "MainMultiplayer":
                    MainGameMultiplayerView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds)
                case "RightMultiplayer":
                    RightAnswerMultiplayerView(currentScene: $currentScene, score: $score, rounds: $rounds)
                case "WrongMultiplayer":
                    WrongAnswerMultiplayerView(currentScene: $currentScene, score: $score, rounds: $rounds)
                case "GameOverMultiplayer":
                    GameOverMultiplayerView(currentScene: $currentScene, score: $score)
                default:
                    JoinMultiplayerView(currentScene: $currentScene, countries: $countries)
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

struct FlagQuestion: Codable {
    let flag: String
    let answerOptions: [String]
    let correctAnswer: String

    func toDict() -> [String: Any] {
        return [
            "flag": flag,
            "answerOptions": answerOptions,
            "correctAnswer": correctAnswer
        ]
    }
}


struct MainGameMultiplayerView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int
    
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
                                score += 1
                                if rounds > 0 {
                                    rounds -= 1
                                }
                                countries.removeAll { $0.name == question.correctAnswer }
                                socketManager.currentScene = "RightMultiplayer"
                            } else {
                                if rounds > 0 {
                                    rounds -= 1
                                }
                                countries.removeAll { $0.name == question.correctAnswer }
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




class SocketManager: NSObject, ObservableObject, WebSocketDelegate {
    static let shared = SocketManager()
    @Published var users: Set<User> = []
    @Published var currentScene: String

    //let objectWillChange = ObservableObjectPublisher()
    internal var socket: WebSocket
    var countries: [Country]
    var usersTimer: Timer?
    @Published var currentQuestion: FlagQuestion?

    //private var currentSceneBinding: Binding<String>?
    
    override init() {
        let url = URL(string: "wss://eu-1.lolo.co/uGPiCKZAeeaKs83jaRaJiV/socket")!
        let request = URLRequest(url: url)
        socket = WebSocket(request: request)
        _currentScene = Published(initialValue: "Start")
        countries = []
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
                        if let usersArray = json["users"] as? [[String: Any]] {
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
                        DispatchQueue.main.async { [weak self] in
                            self?.stopUsersTimer()
                            self?.currentScene = "GetReadyMultiplayer"
                            self?.objectWillChange.send()

                            // Generate a flag question
                            let randomCountry = self?.countries.randomElement()!
                            let currentCountry = randomCountry?.name
                            let countryAlternatives = self?.countries.filter { $0.name != currentCountry }
                            let answerOptions = countryAlternatives!.shuffled().prefix(3).map { $0.name } + [currentCountry]
                            let correctAnswer = currentCountry
                            let flag = randomCountry?.flag
                            let question = FlagQuestion(flag: flag!, answerOptions: answerOptions.compactMap { $0 }, correctAnswer: correctAnswer!)

                            // Send the flag question to all clients
                            let message: [String: Any] = ["type": "flagQuestion", "question": question.toDict()]
                            guard let jsonData = try? JSONSerialization.data(withJSONObject: message) else {
                                return
                            }
                            let jsonString = String(data: jsonData, encoding: .utf8)!
                            self?.send(jsonString)
                            self?.currentQuestion = question
                            print(jsonString)
                            print(self?.currentQuestion)
                            
                        }
                        
                    case "flagQuestion":
                        
                        guard let jsonQuestion = json["question"] as? [String: Any],
                              let flag = jsonQuestion["flag"] as? String,
                              let answerOptions = jsonQuestion["answerOptions"] as? [String],
                              let correctAnswer = jsonQuestion["correctAnswer"] as? String else {
                            // Error handling for when the JSON message is malformed or missing necessary fields
                            return
                        }
                        print("Mottager flagga")
                        print(jsonQuestion)
                    
                        let question = FlagQuestion(flag: flag, answerOptions: answerOptions, correctAnswer: correctAnswer)
                        self.currentQuestion = question
                        print(self.currentQuestion)



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
    
    
    func addUser(_ user: User) {
        self.users.insert(user)
        self.objectWillChange.send()
        sendUsersArray()
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
            "users": usersArray.map { ["id": $0.id.uuidString, "name": $0.name, "color": colorToString[$0.color] ?? "", "score": String($0.score), "currentRound": String($0.currentRound)] }
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: usersDict, options: []),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            socket.write(string: jsonString)
            print("sendUserArray")
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

struct Country: Codable, Hashable {
    var name: String
    var flag: String
}

struct User: Hashable, Identifiable {
    var id: UUID
    var name: String
    var color: Color
    var score: Int
    var currentRound: Int
}


struct GetReadyMultiplayerView: View {
    @Binding var currentScene: String
    
    @State private var timerCount = 3
    
    var body: some View {
        VStack {
            Text("GET READY 4 MULTIPLAYER")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            Text("\(timerCount)")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if self.timerCount > 0 {
                    self.timerCount -= 1
                } else {
                    timer.invalidate()
                    SocketManager.shared.currentScene = "MainMultiplayer"
                }
            }
        }
    }
}





struct RightAnswerMultiplayerView: View {
    @Binding var currentScene: String
    @Binding var score: Int
    @Binding var rounds: Int
    
    var body: some View {
        Text("RightAnswerMultiplayerView")
    }
}
struct WrongAnswerMultiplayerView: View {
    @Binding var currentScene: String
    @Binding var score: Int
    @Binding var rounds: Int
    
    var body: some View {
        Text("WrongAnswerMultiplayerView")
    }
}
struct GameOverMultiplayerView: View {
    @Binding var currentScene: String
    @Binding var score: Int

    var body: some View {
        Text("GameOverMultiplayerView")
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

