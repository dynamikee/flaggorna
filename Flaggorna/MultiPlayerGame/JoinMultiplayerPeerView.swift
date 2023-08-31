//
//  JoinMultiplayerPeerView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-06-04.
//

import SwiftUI
import UIKit
import MultipeerConnectivity
import CoreData

struct JoinMultiplayerPeerView: View {
    
    @EnvironmentObject private var purchaseManager: PurchaseManager
    
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var rounds: Int
    @Binding var multiplayer: Bool
    @Binding var numberOfRounds: Int
    @Binding var roundsArray: [RoundStatus]
    @Binding var selectedContinents: [String]
    
    @State private var uuidString: String = ""
    @State private var name: String = ""
    @State private var color: Color = .white
    @State private var flag: String = "sweden"
    @State private var score: Int = 0
    @State private var currentRound: Int = 0
    @State private var gameCode: String = ""
    @State var singlePlayer: Bool = true
    
    @EnvironmentObject var socketManager: SocketManager
    
    private let userDefaults = UserDefaults.standard
    
    //
    @State private var nearbyServiceBrowser: MCNearbyServiceBrowser?
    @State var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser?
    
    @StateObject private var multipeerDelegate = MultipeerDelegate()
    
    @State private var isSeeking: Bool = UserDefaults.standard.string(forKey: "userName") != nil

    let serviceType = "flaggorna-quiz"
    
    @State private var showStoreView = false
    
    @State private var showFlagSelection = false
    
    @State private var showGameModeSelection = false
    @State private var selectedLevel: String = ""
    @State private var levelList: [String] = []
    //@State private var selectedContinents: [String] = []
    @State private var continentList: [String] = []
    
    
    private func loadUserData() {
        if let userID = userDefaults.string(forKey: "userID") {
            self.uuidString = userID
        } else {
            let userID = UUID().uuidString
            self.uuidString = userID
        }
        if let name = userDefaults.string(forKey: "userName") {
            self.name = name
        }
        if let colorString = userDefaults.string(forKey: "userColor"),
           let color = colors.first(where: { colorToString[$0] == colorString }) {
            self.color = color
        } else {
            self.color = colors.randomElement()!
        }
        if let flag = userDefaults.string(forKey: "userFlag") {
            self.flag = flag
        } else {
            if let randomCountry = countries.randomElement() {
                self.flag = randomCountry.flag
            } else {
                // Handle the case where the countries array is empty
                self.flag = "Sweden"
            }
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
    
    @State private var circleScale: CGFloat = 0
    private let animationDuration: TimeInterval = 3.0
    
    var body: some View {
        
        if showFlagSelection {
            ScrollView {

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(countries, id: \.self) { country in
                    Button(action: {
                        let selectedUserFlag = country.flag
                        UserDefaults.standard.setValue(selectedUserFlag, forKey: "userFlag")
                        showFlagSelection = false

                    }) {
                        Image(country.flag)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64)
                            .clipShape(Circle())
                        //.border(sortedFlagData == data ? Color.blue : Color.clear, width: 2)
                            .padding(.trailing, 8)
                    }
                }
            }
            .padding()
                
            }
            
        } else {
                

        
        VStack {
            HStack {
                Button(action: {
                    if let currentUser = self.socketManager.currentUser {
                        self.socketManager.users.remove(currentUser)
                        self.socketManager.sendUserRemoval(currentUser)
                    }
                    
                    multiplayer = false
                    currentScene = "Start"
                    self.socketManager.socket.disconnect()
                    
                }) {
                    Text(Image(systemName: "xmark"))
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
                Spacer()
                Button(action: {
                    
                    multiplayer = false
                    currentScene = "GameModeView"
                    
                }) {
                    Text(Image(systemName:  "slider.vertical.3"))
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
            }
            Spacer()
        }
        .padding()
        
        
        Spacer()
        
        if isSeeking == false {
            HStack {
                Image(flag)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64)
                    .clipShape(Circle())
                    .padding(.trailing, 8)
                    .onTapGesture {
                        showFlagSelection = true // Set the flag selection mode to true
                    }
                
                TextField("Enter your name", text: $name)
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                Button(action: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isSeeking = true
                    }
                    userDefaults.set(name, forKey: "userName")
                    userDefaults.set(flag, forKey: "userFlag")
                }) {
                    Text(Image(systemName: "arrow.forward"))
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
                .disabled(name.isEmpty)
            }
            .padding()
            .onAppear {
                loadUserData()

            }
            
        } else {
            //Denna animationen ställer till det så att knappen flyttas på startvyn när du går tillbaka. Vet inte om det gör det på fler ställen.
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(1))
                    .scaleEffect(circleScale)
                    .opacity(Double(1 - circleScale))
                    .onAppear {
                        startAnimation()
                    }
                
            }
            //.offset(y: UIScreen.main.bounds.height/2.5)
            
            VStack (spacing: 10) {
                Spacer()
                Text("Searching nearby players...")
                    .font(.body)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding()
                VStack {
                    ForEach(socketManager.users.sorted(by: { $0.name < $1.name }), id: \.id) { user in
                        HStack {
                            Image(user.flag)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 64)
                                .clipShape(Circle())
                                .padding(.trailing, 8)
                                  
                            Text(user.name + (user.id.uuidString == uuidString ? " (you)" : ""))
                                .font(.title2)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                }
                Spacer()
                
                
                if socketManager.users.count < 2 {
                    Button {
                        score = 0
                        rounds = numberOfRounds
                        self.roundsArray = Array(repeating: .notAnswered, count: numberOfRounds)
                        
                        if let currentUser = self.socketManager.currentUser {
                            self.socketManager.users.remove(currentUser)
                            self.socketManager.sendUserRemoval(currentUser)
                        }
                        
                        multiplayer = false
                        currentScene = "GetReady"
                        self.socketManager.stopUsersTimer()
                        self.socketManager.socket.disconnect()
                    } label: {
                        Text("START GAME")
                    }
                    .padding()
                    .buttonStyle(OrdinaryButtonStyle())
                    
                } else if socketManager.users.count > 4 {
                    Button {
                        // premium is needed
                        if purchaseManager.hasUnlockedPremium {
                            self.socketManager.stopUsersTimer()
                            SocketManager.shared.currentScene = "GetReadyMultiplayer"
                            
                            let flagQuestion = socketManager.generateFlagQuestion()
                            let startMessage = StartMessage(type: "startGame", gameCode: gameCode, question: flagQuestion, selectedContinents: selectedContinents)
                            let jsonData = try? JSONEncoder().encode(startMessage)
                            let jsonString = String(data: jsonData!, encoding: .utf8)!
                            socketManager.send(jsonString)
                            isSeeking = false
                            
                        } else {
                            showStoreView = true
                            
                        }
                    } label: {
                        Text("START GAME")
                    }
                    .padding()
                    .buttonStyle(OrdinaryButtonStyle())
                    .sheet(isPresented: $showStoreView) {
                        StoreView(isPresented: $showStoreView) // Pass the isPresented binding here
                    }
                    
                } else {
                    Button {
                        // premium is not needed
                        self.socketManager.stopUsersTimer()
                        SocketManager.shared.currentScene = "GetReadyMultiplayer"
                        
                        let flagQuestion = socketManager.generateFlagQuestion()
                        let startMessage = StartMessage(type: "startGame", gameCode: gameCode, question: flagQuestion, selectedContinents: selectedContinents)
                        let jsonData = try? JSONEncoder().encode(startMessage)
                        let jsonString = String(data: jsonData!, encoding: .utf8)!
                        socketManager.send(jsonString)

                        isSeeking = false
                    } label: {
                        Text("START GAME")
                    }
                    .padding()
                    .buttonStyle(OrdinaryButtonStyle())
                    
                }
                
            }
            .preferredColorScheme(.dark)
            .padding()
            .onAppear {
                loadUserData()
                self.socketManager.socket.connect()
                self.socketManager.startUsersTimer()
                self.currentRound = rounds
                
                let peerID = MCPeerID(displayName: UIDevice.current.name)
                startBrowsingForPeers(peerID: peerID, serviceType: serviceType)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if multipeerDelegate.discoveredPeers.isEmpty {
                        let code = String(format: "%04d", arc4random_uniform(9000) + 1000)
                        gameCode = code
                        socketManager.setGameCode(code)
                        join()
                        
                    } else {
                        if let hostGameCode = multipeerDelegate.discoveredPeers.first?.1 {
                            gameCode = hostGameCode
                            socketManager.setGameCode(gameCode)
                            join()
                        }
                    }
                    startAdvertising(peerID: peerID, serviceType: serviceType)
                }
                
            }
            
        }
            
        }
    }
    
    private func join() {
        guard let uuid = UUID(uuidString: uuidString) else {
            // Handle the case where the UUID string is not valid
            return
        }
        
        let user = User(id: uuid, name: name, color: color, flag: flag, score: score, currentRound: currentRound)
        
        // Save user data to UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(uuidString, forKey: "userID")
        defaults.set(name, forKey: "userName")
        defaults.set(colorToString[color], forKey: "userColor")
        defaults.set(flag, forKey: "userFlag")
        
        
        socketManager.addUser(user)
        socketManager.currentUser = user
    }
    
    
    private func startBrowsingForPeers(peerID: MCPeerID, serviceType: String) {
        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser.delegate = multipeerDelegate
        browser.startBrowsingForPeers()
        nearbyServiceBrowser = browser
    }
    
    private func startAdvertising(peerID: MCPeerID, serviceType: String) {
        let discoveryInfo = ["gameCode": gameCode] // Include the game code in the discovery info
        
        let advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser.delegate = multipeerDelegate
        advertiser.startAdvertisingPeer()
        nearbyServiceAdvertiser = advertiser
    }
    
    
    func updateDiscoveredPeers(_ peers: [(MCPeerID, String?)]) {
        DispatchQueue.main.async {
            multipeerDelegate.discoveredPeers = peers
            self.gameCode = multipeerDelegate.gameCode
        }
    }
    
    private func stopBrowsingForPeers() {
        //multipeerDelegate.updateDiscoveredPeers = nil
        // Stop browsing for peers
    }
    
    private func startAnimation() {
        withAnimation(Animation.easeInOut(duration: animationDuration).repeatForever(autoreverses: false)) {
            circleScale = 1
        }
    }
}


class MultipeerDelegate: NSObject, ObservableObject, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    
    //var updateDiscoveredPeers: (([(MCPeerID, String?)]) -> Void)?
    
    @Published var discoveredPeers: [(MCPeerID, String?)] = []
    
    @Published var gameCode = ""
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        let gameCode = info?["gameCode"]
        
        DispatchQueue.main.async { [weak self] in
            if let gameCode = gameCode {
                self?.gameCode = gameCode // Update the gameCode directly
                self?.discoveredPeers.append((peerID, gameCode))
                
            } else {
                // ...
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            self?.discoveredPeers.removeAll(where: { $0.0 == peerID })
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Handle the invitation from the peer
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        // Handle the error if advertising failed to start
    }
    
}
