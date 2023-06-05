//
//  JoinMultiplayerPeerView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-06-04.
//

import SwiftUI
import UIKit
import MultipeerConnectivity

struct JoinMultiplayerPeerView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var rounds: Int
    @Binding var multiplayer: Bool
    
    @State private var name: String = ""
    @State private var color: Color = .white
    @State private var score: Int = 0
    @State private var currentRound: Int = 0
    @State private var gameCode: String = ""
    
    @EnvironmentObject var socketManager: SocketManager
    
    private let userDefaults = UserDefaults.standard
    
    //
    @State private var nearbyServiceBrowser: MCNearbyServiceBrowser?
    @State var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser?
    
    @StateObject private var multipeerDelegate = MultipeerDelegate()
    @State private var discoveredPeers: [MCPeerID] = []
    
    let serviceType = "flaggorna-quiz"
    
    
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
        
        
        VStack (spacing: 10) {
            
            Text("GAME CODE \(gameCode)")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            
            Text("List of peers")
                .font(.body)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            VStack {
                ForEach(discoveredPeers, id: \.self) { peer in
                    HStack {
                        Circle()
                            .foregroundColor(.blue) // Set your desired color
                            .frame(width: 20, height: 20)
                        Text(peer.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
            }
            Text("List of sockets")
                .font(.body)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
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
                
            }
            
            Button(action: {
                if socketManager.users.count < 2 {
                    // Starta single game?
                    
                } else {
                    
                    self.socketManager.stopUsersTimer()
                    SocketManager.shared.currentScene = "GetReadyMultiplayer"
                    
                    let flagQuestion = socketManager.generateFlagQuestion()
                    let startMessage = StartMessage(type: "startGame", gameCode: gameCode, question: flagQuestion)
                    let jsonData = try? JSONEncoder().encode(startMessage)
                    let jsonString = String(data: jsonData!, encoding: .utf8)!
                    socketManager.send(jsonString)
                }
            }){
                Text("START GAME")
            }
            .padding()
            .buttonStyle(OrdinaryButtonStyle())

        }
        .padding()
        .onAppear {
            loadUserData()
            self.socketManager.socket.connect()
            self.socketManager.startUsersTimer()
            self.currentRound = rounds
            
            let peerID = MCPeerID(displayName: UIDevice.current.name)
            startBrowsingForPeers(peerID: peerID, serviceType: serviceType)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if discoveredPeers.isEmpty {
                    let code = String(format: "%04d", arc4random_uniform(9000) + 1000)
                    gameCode = code
                    socketManager.setGameCode(code)
                    startAdvertising(peerID: peerID, serviceType: serviceType)
                }
            }
            multipeerDelegate.updateDiscoveredPeers = updateDiscoveredPeers
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

    
    private func updateDiscoveredPeers(_ peers: [MCPeerID]) {
        discoveredPeers = peers
    }

    
    private func stopBrowsingForPeers() {
        multipeerDelegate.updateDiscoveredPeers = nil
        // Stop browsing for peers
    }
    
    
}

class MultipeerDelegate: NSObject, ObservableObject, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    
    var updateDiscoveredPeers: (([MCPeerID]) -> Void)?
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        if let discoveryInfo = info, let gameCode = discoveryInfo["gameCode"] {
            // Handle the game code received from the advertising device
            print("Received game code:", gameCode)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.updateDiscoveredPeers?([peerID])
        }
    }

    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            self?.updateDiscoveredPeers?([])
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Handle the invitation from the peer
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        // Handle the error if advertising failed to start
    }
    
}

