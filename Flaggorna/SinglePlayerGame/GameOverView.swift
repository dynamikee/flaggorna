//
//  GameOverView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-18.
//

import SwiftUI
import Foundation
import UIKit
import CoreData

struct GameOverView: View {
    
    @Binding var currentScene: String
    @Binding var score: Int
    @Binding var rounds: Int
    @Binding var countries: [Country]
    @Binding var numberOfRounds: Int
    @Binding var roundsArray: [RoundStatus]
    
    @State var highestScore = UserDefaults.standard.integer(forKey: "highScore")
    @State var highscores: [Highscore] = []
    @State private var enteredPlayerName: String = (UserDefaults.standard.string(forKey: "userName") ?? "")
    @State private var showScreen = "Loading"
    @State private var rankToAnimate: Int = 0
    
    @Environment(\.managedObjectContext) private var viewContext

    
    var body: some View {
                
        VStack (spacing: 16) {
            Spacer()
            
            
        switch showScreen {
        case "Loading":
            Text(" ")
                .font(.title)
            
        case "SubmitHighscore":
            Text("NEW HIGH SCORE!")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)
            Text("\(score)")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)
            HStack {
                TextField("Enter your name", text: $enteredPlayerName)
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) // Dismiss the keyboard

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showScreen = "HighscoreSubmitted"
                        updateHighscoreRanks()
                        postUpdatedHighscores(playerName: String(enteredPlayerName.prefix(20))) // Pass enteredPlayerName to the function
                        UserDefaults.standard.set(enteredPlayerName, forKey: "userName")
                    }
                }) {
                    Text(Image(systemName: "arrow.forward"))
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
                .disabled(enteredPlayerName.isEmpty)
            }
            .padding()
            
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
            
        case "HighscoreSubmitted":
            VStack(spacing: 8) {
                Text("THIS WEEKS")
                    .font(.body)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                Text("HIGHSCORES")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .padding(.bottom, 24)
                ForEach(highscores.indices, id: \.self) { index in
                    let highscore = highscores[index]
                    let rowRank = highscore.rank
                    HStack {
                        Group {
                            switch highscore.rank {
                            case 1:
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.white)
                                
                            case 2:
                                Image(systemName: "medal.fill")
                                    .foregroundColor(.white)
                                
                            case 3:
                                Image(systemName: "medal")
                                    .foregroundColor(.white)
                                
                            case 4:
                                Image(systemName: "4.circle")
                                    .foregroundColor(.white)
                            case 5:
                                Image(systemName: "5.circle")
                                    .foregroundColor(.white)
                                
                            default:
                                Text("\(highscore.rank).")
                                    .foregroundColor(.white)
                                
                            }
                        }
                        .font(.largeTitle)
                        
                        Text(highscore.playerName)
                            .font(.body)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(highscore.score)")
                            .font(.body)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity)
                    .opacity(rankToAnimate == 0 || rankToAnimate == rowRank ? 1 : 0.3)
                    .animation(.easeInOut(duration: 1.0).delay(Double(index) * 0.1))
                    .onAppear {

                        if highscore.rank == rankToAnimate {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation {
                                    rankToAnimate = 0 // Reset rankToAnimate to prevent retriggering the animation
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
            
            Button(action: {
                loadData()
                score = 0
                rounds = 10
                roundsArray = Array(repeating: .notAnswered, count: numberOfRounds)
                currentScene = "GetReady"
            }) {
                Text("PLAY AGAIN")
            }
            .buttonStyle(OrdinaryButtonStyle())
                        
            Button(action: {
                currentScene = "Start"
            }) {
                Image(systemName: "xmark")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
            }
            .padding(24)
            
        case "NoHighscore":
            VStack(spacing: 8) {
                Text("THIS WEEKS")
                    .font(.body)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                Text("HIGHSCORES")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .padding(.bottom, 24)
                ForEach(highscores.indices, id: \.self) { index in
                    let highscore = highscores[index]
                    HStack {
                        Group {
                            switch highscore.rank {
                            case 1:
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.white)
                                
                            case 2:
                                Image(systemName: "medal.fill")
                                    .foregroundColor(.white)
                                
                            case 3:
                                Image(systemName: "medal")
                                    .foregroundColor(.white)
                                
                            case 4:
                                Image(systemName: "4.circle")
                                    .foregroundColor(.white)
                            case 5:
                                Image(systemName: "5.circle")
                                    .foregroundColor(.white)
                                
                            default:
                                Text("\(highscore.rank).")
                                    .foregroundColor(.white)
                                
                            }
                        }
                        .font(.largeTitle)
                        
                        Text(highscore.playerName)
                            .font(.body)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(highscore.score)")
                            .font(.body)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            
            Text("Your score: \(score)")
                .font(.body)
                .fontWeight(.black)
                .foregroundColor(.white)

            Spacer()
            
            Button(action: {
                loadData()
                score = 0
                rounds = 10
                roundsArray = Array(repeating: .notAnswered, count: numberOfRounds)
                currentScene = "GetReady"
            }) {
                Text("PLAY AGAIN")
            }
            .buttonStyle(OrdinaryButtonStyle())
                        
            Button(action: {
                currentScene = "Start"
            }) {
                Image(systemName: "xmark")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
            }
            .padding(24)

        default:
            Text("Something went wroing")
                .foregroundColor(.white)
        }
        
        }
        
        .onAppear() {
            updateUserConsistency(score: score)

            fetchTopHighscores()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                checkUserHighscore()
            }
            
            if score > highestScore {
                UserDefaults.standard.set(score, forKey: "highScore")
                UserDefaults.standard.synchronize()
            }
        }
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






    
    
    private func loadData() {
#if FLAGGORNA
let file = Bundle.main.path(forResource: "countries", ofType: "json")!
#elseif TEAM_LOGO_QUIZ
let file = Bundle.main.path(forResource: "teams", ofType: "json")!
#endif
        let data = try! Data(contentsOf: URL(fileURLWithPath: file))
        let decoder = JSONDecoder()
        self.countries = try! decoder.decode([Country].self, from: data)
    }
    
    private func fetchTopHighscores() {
        #if FLAGGORNA
        guard let url = URL(string: "https://eu-1.lolo.co/uGPiCKZAeeaKs83jaRaJiV/highscore2s") else {
            return
        }
        #elseif TEAM_LOGO_QUIZ
        guard let url = URL(string: "https://eu-1.lolo.co/uGPiCKZAeeaKs83jaRaJiV/teams-highscores") else {
            return
        }
        #endif
        
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Failed to fetch highscores: \(error.localizedDescription)")
                return
            }
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(HighscoreResponse.self, from: data)
                    
                    if response.items.isEmpty {
                        print("No highscore items found.")
                        return
                    }
                    let highscoreItem = response.items[0]
                    if highscoreItem.highscores.isEmpty {
                        print("No highscores found.")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.highscores = highscoreItem.highscores
                    }
                } catch {
                    print("Failed to parse highscores data: \(error.localizedDescription)")
                    
                }
            } else {
                print("No data received from the server.")
            }
        }.resume()
    }
    
    
    private func checkUserHighscore() {
        // Check if user's score qualifies for the leaderboard
        let userScore = score
        
        let userRank = highscores.firstIndex { $0.score < userScore } ?? highscores.count
        
        if userRank < 5 {
            // User's score qualifies for the leaderboard
            let newHighscore = Highscore(id: UUID().uuidString, score: userScore, playerName: "", rank: userRank + 1)
            
            // Insert the new highscore at the appropriate position
            highscores.insert(newHighscore, at: userRank)
            rankToAnimate = userRank + 1
            
            // Trim the highscores array to contain only the top 10 scores
            if highscores.count > 5 {
                highscores.removeLast(highscores.count - 5)
            }
            showScreen = "SubmitHighscore"
            
        } else {
            // User's score does not qualify for the leaderboard
            print("Your score does not make it to the top 10.")
            showScreen = "NoHighscore"

        }
    }
    
    
    private func updateHighscoreRanks() {
        for (index, _) in highscores.enumerated() {
            highscores[index].rank = index + 1
        }
    }
    
    private func postUpdatedHighscores(playerName: String) {
        guard let userRank = highscores.firstIndex(where: { $0.playerName == "" }) else {
            return
        }
        
        highscores[userRank].playerName = playerName
        
        #if FLAGGORNA
        // Create a request to update the highscores on the server
        guard let url = URL(string: "https://eu-1.lolo.co/uGPiCKZAeeaKs83jaRaJiV/highscore2s/jx4EHc1pTLPaGFqHnLV3aC") else {
            return
        }
        #elseif TEAM_LOGO_QUIZ
        guard let url = URL(string: "https://eu-1.lolo.co/uGPiCKZAeeaKs83jaRaJiV/teams-highscores/iPsiJLsMnF8BKTEQx76yvq") else {
            return
        }
        #endif
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let requestData = try encoder.encode(UpdatedHighscores(highscores: highscores))
            print(requestData)
            request.httpBody = requestData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Failed to update highscores: \(error.localizedDescription)")
                    return
                }
                
                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 200 {
                        print("Highscores updated successfully")
                        print(response)
                    } else {
                        print("Failed to update highscores. Status code: \(response.statusCode)")
                    }
                }
            }.resume()
        } catch {
            print("Failed to encode highscores data: \(error.localizedDescription)")
        }
    }
}

struct HighscoreResponse: Codable {
    let items: [HighscoreItem]
}

struct HighscoreItem: Codable {
    let highscores: [Highscore]
    let id: String
    let createdAt: String
    let version: Int
    let updatedAt: String
}

struct Highscore: Codable, Identifiable {
    let id: String
    let score: Int
    var playerName: String
    var rank: Int
    
    private enum CodingKeys: String, CodingKey {
        case id, score, playerName = "player_name", rank
    }
}

struct UpdatedHighscores: Codable {
    let highscores: [Highscore]
}

