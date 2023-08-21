//
//  GameOverMultiplayerView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-03-06.
//

import SwiftUI
import CoreData


struct GameOverMultiplayerView: View {
    @Binding var currentScene: String
    @Binding var score: Int
    @Binding var rounds: Int
    @Binding var multiplayer: Bool
    //@Binding var gameCode: String
    
    @Environment(\.managedObjectContext) private var viewContext

    @EnvironmentObject var socketManager: SocketManager

    @State var showAlert = false
    
    var body: some View {
        
        VStack(spacing: 32)  {
            Spacer()
            Text("GAME OVER!")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)

            VStack {
                ForEach(socketManager.users.sorted(by: { $0.score < $1.score }).reversed(), id: \.id) { user in
                    HStack {
                        Circle()
                            .foregroundColor(user.color)
                            .frame(width: 20, height: 20)
                        Text(user.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(user.score))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                    }
                    .padding(.horizontal, 16)
                }
            }
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 12, height: 12)
                    .modifier(ParticlesModifier())
                    .offset(x: -100, y : -50)
                        
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .modifier(ParticlesModifier())
                    .offset(x: 60, y : 70)
                
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 12, height: 12)
                    .modifier(ParticlesModifier())
                    .offset(x: 0, y : 0)
            }
            Spacer()
            
            if showAlert {
                    Text("Need to be at least two players")
                    .font(.body)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    
                                .opacity(showAlert ? 1 : 0)
                                .animation(.easeInOut(duration: 0.5))
                        }
            
                Button(action: {

                    if socketManager.users.count < 2 {
                        showAlert = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showAlert = false
                            }
                        }
                    } else {
                        
                        score = 0
                        
                        resetGame()
                        socketManager.loadData()
                        
                        SocketManager.shared.currentScene = "GetReadyMultiplayer"
                        
                        let flagQuestion = socketManager.generateFlagQuestion()
                        let startMessage = StartMessage(type: "startGame", gameCode: socketManager.gameCode, question: flagQuestion)
                        let jsonData = try? JSONEncoder().encode(startMessage)
                        let jsonString = String(data: jsonData!, encoding: .utf8)!
                        socketManager.send(jsonString)
                        
                    }
                }){
                    Text("PLAY AGAIN")
                }
                .buttonStyle(OrdinaryButtonStyle())
                .padding()
            
            Button(action: {
                if let currentUser = self.socketManager.currentUser {
                    self.socketManager.users.remove(currentUser)
                    self.socketManager.sendUserRemoval(currentUser)
                }
                
                socketManager.users = []
                multiplayer = false
                socketManager.countries = []
                self.socketManager.socket.disconnect()
                currentScene = "Start"

            }){
                Text(Image(systemName: "xmark"))
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                
            }
            .padding()

            
            
        }
        .onAppear() {
            rounds = 10
            let currentUserScore = self.socketManager.currentUser?.score
            print("Here is the score when updating nerd score: \(currentUserScore ?? 0)")
            updateUserConsistency(score: currentUserScore ?? 0)
            
            let currentHighscore = UserDefaults.standard.integer(forKey: "highScore")

            print("Here is the current higscore: \(currentHighscore)")
            
            if currentUserScore! > currentHighscore {
                UserDefaults.standard.set(currentUserScore, forKey: "highScore")
                UserDefaults.standard.synchronize()
            }
        }
    }
    func resetGame() {
        // Reset the rounds and scores of all users in the game
        for user in socketManager.users {
            user.currentRound = 10
            user.score = 0
        }
        
        print("Resetting game for: \(socketManager.users)")
        
        // Send a message to all users to inform them of the reset
        let resetMessage = ResetMessage(type: "resetGame", gameCode: socketManager.gameCode)
        let jsonData = try? JSONEncoder().encode(resetMessage)
        let jsonString = String(data: jsonData!, encoding: .utf8)!
        socketManager.send(jsonString)
    }
    
    private func updateUserConsistency(score: Int) {
        let request: NSFetchRequest<FlagData> = FlagData.fetchRequest()

        do {
            let results = try viewContext.fetch(request)

            if let flagData = results.first {

                if flagData.user_consistency > 0 {
                    
                    var numberOfGamesOver50Saved = flagData.user_consistency * Double(flagData.user_games_played)
                    
                    flagData.user_games_played += 1
                                        
                    var numberOfGamesOver50IncludingLastRound = numberOfGamesOver50Saved
                    
                    if score >= 50 {
                        numberOfGamesOver50IncludingLastRound += 1
                    }
                         
                    var newAverageConsistency = numberOfGamesOver50IncludingLastRound / Double(flagData.user_games_played)
                    
                    flagData.user_consistency = newAverageConsistency
                    

                } else {

                    if score >= 50 {
                        flagData.user_consistency = 1.0

                    } else {
                        flagData.user_consistency = 0.0
                    }
                    flagData.user_games_played += 1
                }

                try viewContext.save()
            }
        } catch {
            // Handle error
            print("Error updating user accuracy: \(error)")
        }
    }
    
}


