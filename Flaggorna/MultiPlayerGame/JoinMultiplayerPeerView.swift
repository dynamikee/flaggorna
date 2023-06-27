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
    
    @State private var uuidString: String = ""
    @State private var name: String = ""
    @State private var color: Color = .white
    @State private var score: Int = 0
    @State private var currentRound: Int = 0
    @State private var gameCode: String = ""
    @State private var needMorePlayersAlert = false
    
    @EnvironmentObject var socketManager: SocketManager
    
    private let userDefaults = UserDefaults.standard
    
    //
    @State private var nearbyServiceBrowser: MCNearbyServiceBrowser?
    @State var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser?
    
    @StateObject private var multipeerDelegate = MultipeerDelegate()
    
    @State var isSeeking = false
    
    let serviceType = "flaggorna-quiz"
    
    @State private var showStoreView = false
    
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
        
        
        VStack {
            HStack {
                Button(action: {
                    if let currentUser = self.socketManager.currentUser {
                        self.socketManager.users.remove(currentUser)
                        self.socketManager.sendUserRemoval(currentUser)
                    }
                    
                    //self.socketManager.users = []
                    multiplayer = false
                    //self.socketManager.countries = []
                    currentScene = "Start"
                    self.socketManager.socket.disconnect()
                    
                }) {
                    Text(Image(systemName: "xmark"))
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
                Spacer()
                
            }
            Spacer()
        }
        .padding()
        
        
        Spacer()
        
        if isSeeking == false {
            HStack {
                TextField("Enter your name", text: $name)
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                Button(action: {
                    isSeeking = true
                    userDefaults.set(name, forKey: "userName")
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
                //            if name.isEmpty {
                //                isSeeking = false
                //            } else {
                //                isSeeking = true
                //            }
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
                }
                Spacer()
                if needMorePlayersAlert {
                    Text("Friends need to be nearby to play")
                        .font(.body)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    
                        .opacity(needMorePlayersAlert ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5))
                }
                
                Button(action: {
                    if socketManager.users.count < 2 {
//                        needMorePlayersAlert = true
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                            withAnimation {
//                                needMorePlayersAlert = false
//                            }
//                        }
                        loadData()
                        score = 0
                        rounds = numberOfRounds
                        self.roundsArray = Array(repeating: .notAnswered, count: numberOfRounds)
                        
                        if let currentUser = self.socketManager.currentUser {
                            self.socketManager.users.remove(currentUser)
                            self.socketManager.sendUserRemoval(currentUser)
                        }
                        
                        //self.socketManager.users = []
                        multiplayer = false
                        //self.socketManager.countries = []
                        currentScene = "GetReady"
                        self.socketManager.socket.disconnect()

                        
                    } else if socketManager.users.count > 4 {
                        // premium is needed
                        if purchaseManager.hasUnlockedPremium {
                            self.socketManager.stopUsersTimer()
                            SocketManager.shared.currentScene = "GetReadyMultiplayer"
                            
                            let flagQuestion = socketManager.generateFlagQuestion()
                            let startMessage = StartMessage(type: "startGame", gameCode: gameCode, question: flagQuestion)
                            let jsonData = try? JSONEncoder().encode(startMessage)
                            let jsonString = String(data: jsonData!, encoding: .utf8)!
                            socketManager.send(jsonString)
                            
                            isSeeking = false
                            
                        } else {
                            showStoreView = true

                        }
                        
                        
                    } else {
                        // premium is not needed
                        self.socketManager.stopUsersTimer()
                        SocketManager.shared.currentScene = "GetReadyMultiplayer"
                        
                        let flagQuestion = socketManager.generateFlagQuestion()
                        let startMessage = StartMessage(type: "startGame", gameCode: gameCode, question: flagQuestion)
                        let jsonData = try? JSONEncoder().encode(startMessage)
                        let jsonString = String(data: jsonData!, encoding: .utf8)!
                        socketManager.send(jsonString)
                        
                        isSeeking = false
                        
                        
                        
                    }
                }){
                    Text("START GAME")
                }
                .padding()
                .buttonStyle(OrdinaryButtonStyle())
                .sheet(isPresented: $showStoreView) {
                    StoreView(isPresented: $showStoreView) // Pass the isPresented binding here
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
                
                //isSeeking = true
                
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
    
    private func loadData() {
        let file = Bundle.main.path(forResource: "countries", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: file))
        let decoder = JSONDecoder()
        self.countries = try! decoder.decode([Country].self, from: data)
        
        // Update Core Data with flag data
        updateFlagData()
    }
    
    private func updateFlagData() {
        let managedObjectContext = PersistenceController.shared.container.viewContext
        
        // Fetch existing flag data
        let fetchRequest: NSFetchRequest<FlagData> = FlagData.fetchRequest()
        var existingFlagData: [FlagData] = []
        
        do {
            existingFlagData = try managedObjectContext.fetch(fetchRequest)
        } catch {
            // Handle Core Data fetch error
            print("Error fetching flag data: \(error)")
        }
        
        // Create a dictionary of existing flag data by country name
        var existingFlagDataDict: [String: FlagData] = [:]
        for flagData in existingFlagData {
            if let countryName = flagData.country_name {
                existingFlagDataDict[countryName] = flagData
            }
        }
        
        // Update or create flag data for each country
        for country in countries {
            if let existingFlagData = existingFlagDataDict[country.name] {
                // Update existing flag data
                existingFlagData.flag = country.flag
                
            } else {
                // Create new flag data
                let flagData = FlagData(context: managedObjectContext)
                flagData.country_name = country.name
                flagData.flag = country.flag
                flagData.impressions = 0
                flagData.right_answers = 0
            }
        }
        
        // Save the changes to Core Data
        do {
            try managedObjectContext.save()
        } catch {
            // Handle Core Data saving error
            print("Error saving flag entities: \(error)")
        }
    }
    
    private func fetchFlagData() -> [FlagData] {
        let managedObjectContext = PersistenceController.shared.container.viewContext
        
        let fetchRequest: NSFetchRequest<FlagData> = FlagData.fetchRequest()
        
        do {
            let flagData = try managedObjectContext.fetch(fetchRequest)
            return flagData
        } catch {
            // Handle Core Data fetch error
            print("Error fetching flag data: \(error)")
            return []
        }
    }
    
    private func join() {
        guard let uuid = UUID(uuidString: uuidString) else {
            // Handle the case where the UUID string is not valid
            return
        }
        
        let user = User(id: uuid, name: name, color: color, score: score, currentRound: currentRound)
        
        // Save user data to UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(uuidString, forKey: "userID")
        defaults.set(name, forKey: "userName")
        defaults.set(colorToString[color], forKey: "userColor")
        
        
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
                // ...
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
