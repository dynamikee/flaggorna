
import SwiftUI
import Combine
import UIKit
import Starscream
import Foundation

struct ContentView: View {
    @State var currentScene = "Start"
    @State var countries: [Country] = []
    @State var score = 0
    @State var rounds = 3
    @State var multiplayer: Bool = false
    
    
    

    var body: some View {
        ZStack {
            Color(UIColor(red: 0.11, green: 0.11, blue: 0.15, alpha: 1.00))
                    .edgesIgnoringSafeArea(.all)
            
            if multiplayer {
                switch SocketManager.shared.currentScene {
                case "JoinMultiplayer":
                    JoinMultiplayerView(currentScene: $currentScene)
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
                    JoinMultiplayerView(currentScene: $currentScene)
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

struct JoinMultiplayerView: View {
    @Binding var currentScene: String
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
                    SocketManager.shared.currentScene = "MainMultiplayer"
                    let message: [String: Any] = ["type": "startGame"]
                    let jsonData = try? JSONSerialization.data(withJSONObject: message)
                    let jsonString = String(data: jsonData!, encoding: .utf8)!
                    socketManager.send(jsonString)
                    print(SocketManager.shared.currentScene)
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
            self.color = colors.randomElement()!
        }
    }

    private func join() {
        let user = User(id: UUID(), name: name, color: color, score: score, currentRound: currentRound)
        //name = ""
        socketManager.addUser(user)
    }
}

struct GetReadyMultiplayerView: View {
    @Binding var currentScene: String
    
    @State private var timerCount = 3
    
    var body: some View {
        VStack {
            Text("GET READY!")
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




struct MainGameMultiplayerView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int
    
    var body: some View {
        Text("maingamemultiplayer")
            .font(.title)
            .fontWeight(.black)
            .foregroundColor(.white)
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



class SocketManager: NSObject, ObservableObject, WebSocketDelegate {
    static let shared = SocketManager()
    @Published var users: Set<User> = []
    @Published var currentScene: String
    let objectWillChange = ObservableObjectPublisher()
    internal var socket: WebSocket
    var usersTimer: Timer?

    private var currentSceneBinding: Binding<String>?
    
    override init() {
        let url = URL(string: "wss://eu-1.lolo.co/uGPiCKZAeeaKs83jaRaJiV/socket")!
        let request = URLRequest(url: url)
        socket = WebSocket(request: request)
        _currentScene = Published(initialValue: "Start")
        super.init()
        socket.delegate = self
    }


    
    func send(_ message: String) {
        socket.write(string: message)
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
                            self?.currentScene = "MainMultiplayer"
                            self?.stopUsersTimer()
                            self?.objectWillChange.send()
                        }
                        // handle other message types if needed
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

