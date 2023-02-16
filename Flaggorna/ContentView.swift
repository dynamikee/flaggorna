
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

    
    
    var body: some View {
        
        ZStack {
            
            Color(UIColor(red: 0.11, green: 0.11, blue: 0.15, alpha: 1.00))
                    .edgesIgnoringSafeArea(.all)
            switch currentScene {
            case "Start":
                StartGameView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds)
            case "GetReady":
                GetReadyView(currentScene: $currentScene)
            case "GetReadyMultiplayer":
                GetReadyMultiplayerView(currentScene: $currentScene)
            case "Main":
                MainGameView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds)
            case "Right":
                RightAnswerView(currentScene: $currentScene, score: $score, rounds: $rounds)
            case "Wrong":
                WrongAnswerView(currentScene: $currentScene, score: $score, rounds: $rounds)
            case "GameOver":
                GameOverView(currentScene: $currentScene, score: $score)
            default:
                StartGameView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds)
            }
            
        }
        

        
    }
    
}



struct Country: Codable, Hashable {
    var name: String
    var flag: String
}

struct User: Hashable, Identifiable {
    var id: UUID
    var name: String
    var color: Color
}

struct StartGameView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int
    
    @State private var offset = CGSize.zero
    
    var body: some View {
        VStack {
            Button(action: {
                loadData()
                score = 0
                rounds = 3
                currentScene = "GetReadyMultiplayer"
                
            }){
                Text("PARTY GAME")
            }
            .buttonStyle(OrdinaryButtonStyle())
            .padding()
            
            Button(action: {
                loadData()
                score = 0
                rounds = 3
                currentScene = "GetReady"
            }){
                Text("SINGLE GAME")
            }
            .buttonStyle(OrdinaryButtonStyle())
            .padding()
        }
        
        .background(
            Image("background")
                .resizable()
                .scaledToFill()
                //.aspectRatio(contentMode: .fill)
                .offset(x: offset.width, y: offset.height)
                .frame(width: UIScreen.main.bounds.width)

                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 5)
                            .repeatForever(autoreverses: true)
                    ) {
                        self.offset.height = -100
                    }
                }
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    private func loadData() {
        let file = Bundle.main.path(forResource: "countries", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: file))
        let decoder = JSONDecoder()
        self.countries = try! decoder.decode([Country].self, from: data)
    }
}


struct GetReadyView: View {
    
    @Binding var currentScene: String
    
    @State private var count = 3
    
    var body: some View {
        VStack {
            Text("GET READY!")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            Text("\(count)")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if self.count > 0 {
                    self.count -= 1
                } else {
                    timer.invalidate()
                    self.currentScene = "Main"
                }
            }
        }
    }
}

struct GetReadyMultiplayerView: View {
    @Binding var currentScene: String
    @State private var name: String = ""
    @State private var color: Color = .white
    @State private var showStartButton = false
    @ObservedObject var socketManager = SocketManager()

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
                    currentScene = "Main"
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
        
        let user = User(id: UUID(), name: name, color: color)
        
        name = ""
        let colorString = colorToString[user.color] ?? ".white"
        
        let json: [String: Any] = [
            "type": "newUser",
            "userID": user.id.uuidString,
            "userName": user.name,
            "userColor": colorString
        ]
        

        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            // Send the JSON message to the WebSocket server using your WebSocketManager
            socketManager.send(jsonString)
        }
    }
}

struct MainGameView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int

    var body: some View {
        let randomCountry = countries.randomElement()!
        let currentCountry = randomCountry.name
        let countryAlternatives = countries.filter { $0.name != currentCountry }
        var randomCountryNames = countryAlternatives.map { $0.name }.shuffled().prefix(3)
        randomCountryNames.append(currentCountry)
        randomCountryNames.shuffle()
  
        return VStack {
            HStack{
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
            Image(randomCountry.flag)
                .resizable()
                .border(.gray, width: 1)
                
                .aspectRatio(contentMode: .fit)
                .frame(width: UIScreen.main.bounds.width * 0.8)
            
            Spacer()
            VStack(spacing: 24){
                ForEach(randomCountryNames, id: \.self) { countryName in
                    Button(action: {
                        if strcmp(currentCountry, countryName) == 0 {
                            self.score += 1
                            if self.rounds > 0 {
                                self.rounds -= 1
                            }
                            self.countries.removeAll { $0.name == currentCountry }
                            self.currentScene = "Right"

                            
                        } else {
                            if self.rounds > 0 {
                                self.rounds -= 1
                            }
                            self.countries.removeAll { $0.name == currentCountry }
                            self.currentScene = "Wrong"
                            
                        }
                    }) {
                        Text(countryName)
                    }
                    .buttonStyle(CountryButtonStyle())
                    
                }
            }
            .padding(8)
        }
    }
}

struct RightAnswerView: View {
    @Binding var currentScene: String
    @Binding var score: Int
    @Binding var rounds: Int
   

    var body: some View {
        VStack {
            Spacer()
            Text("Right answer!")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            Text("Your score: \(score)")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                    .modifier(ParticlesModifier())
                    .offset(x: -100, y : -50)
                        
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .modifier(ParticlesModifier())
                    .offset(x: 60, y : 70)
            }
            Spacer()
            
        }
        .onAppear {
            withAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if rounds > 0 {
                        self.currentScene = "Main"
                    } else {
                        self.currentScene = "GameOver"
                    }
                    
                }
            }
        }
    }
}





struct WrongAnswerView: View {
    
    @Binding var currentScene: String
    @Binding var score: Int
    @Binding var rounds: Int
    
    
    var body: some View {
        VStack {
            Spacer()
            Text("Wrong answer")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            Text("Your score: \(score)")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)

            Spacer()
            
        }
        .onAppear {
            withAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if rounds > 0 {
                        self.currentScene = "Main"
                    } else {
                        self.currentScene = "GameOver"
                    }
                }
            }
        }
    }
    
}



struct GameOverView: View {
    
    @Binding var currentScene: String
    @Binding var score: Int

    
    var body: some View {
        VStack {
            Text("Your score: \(score)")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            Button(action: {
                currentScene = "Start"
            }){
                Text("Continue")
            }
            .buttonStyle(OrdinaryButtonStyle())
            .padding()
        }
        
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

class SocketManager: NSObject, ObservableObject, WebSocketDelegate {
    @Published var users: Set<User> = []
    @Published var socket: WebSocket
    var usersTimer: Timer?
    
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
    
    override init() {
        let url = URL(string: "wss://eu-1.lolo.co/uGPiCKZAeeaKs83jaRaJiV/socket")!
        let request = URLRequest(url: url)
        socket = WebSocket(request: request)
        super.init()
        socket.delegate = self
        //socket.connect()
    }
    
    func send(_ message: String) {
        socket.write(string: message)
    }
    
    func startUsersTimer() {
        stopUsersTimer() // make sure only one timer is running at a time
        usersTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            if !(self?.users.isEmpty)! {
                self?.sendUsersArray()
            }
        }
    }

        
    func stopUsersTimer() {
            usersTimer?.invalidate()
            usersTimer = nil
    }

    func sendUsersArray() {
        let usersArray = Array(users)
        let usersDict: [String: Any] = [
            "type": "usersArray",
            "users": usersArray.map { ["id": $0.id.uuidString, "name": $0.name, "color": colorToString[$0.color] ?? ""] }
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: usersDict, options: []),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            socket.write(string: jsonString)
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
                    if type == "newUser" {
                        if let userIDString = json["userID"] as? String, let userID = UUID(uuidString: userIDString), let newUserName = json["userName"] as? String, let newUserColorString = json["userColor"] as? String {
                            
                            let newUser = User(id: userID, name: newUserName, color: color(for: newUserColorString))
                            DispatchQueue.main.async { [weak self] in
                                self?.users.insert(newUser)
                            }
                            let usersArray = Array(users)
                            let usersDict: [String: Any] = [
                                "type": "usersArray",
                                "users": usersArray.map { ["id": $0.id.uuidString, "name": $0.name, "color": colorToString[$0.color] ?? ""] }
                            ]
                            if let jsonData = try? JSONSerialization.data(withJSONObject: usersDict, options: []),
                               let jsonString = String(data: jsonData, encoding: .utf8) {
                                socket.write(string: jsonString)
                                print(jsonString)
                            }
                        }
                    } else if type == "usersArray" {
                            if let usersArray = json["users"] as? [[String: Any]] {
                                var newUsers = Set<User>()
                                for userDict in usersArray {
                                    if let userIDString = userDict["id"] as? String, let userID = UUID(uuidString: userIDString), let userName = userDict["name"] as? String, let userColorString = userDict["color"] as? String {
                                        let newUser = User(id: userID, name: userName, color: color(for: userColorString))
                                        newUsers.insert(newUser)
                                    }
                                }
                                DispatchQueue.main.async { [weak self] in
                                    self?.users = newUsers
                                }
                            }
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
}






