//
//  GameOverView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-18.
//

import SwiftUI
import Foundation

struct GameOverView: View {
    
    @Binding var currentScene: String
    @Binding var score: Int
    @Binding var rounds: Int
    @Binding var countries: [Country]
    @Binding var numberOfRounds: Int
    @Binding var roundsArray: [RoundStatus]
    
    @State var highestScore = UserDefaults.standard.integer(forKey: "highScore")
    @State var highscores: [Highscore] = []
    
    
    var body: some View {
        
        
        
        VStack (spacing: 16) {
            Spacer()
            if score > highestScore {
                Text("NEW HIGH SCORE!")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                Text("\(score)")
                    .font(.largeTitle)
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
                
            } else {
                Text("Current high score: \(highestScore)")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                Text("Your score: \(score)")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                
            }
            
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(highscores.indices, id: \.self) { index in
                        let highscore = highscores[index]
                        HStack {
                            Text("\(highscore.rank).")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text(highscore.playerName)
                            Spacer()
                            Text("\(highscore.score)")
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                    }
                }
            }
            
            
            Button(action: {
                loadData()
                score = 0
                rounds = 10
                self.roundsArray = Array(repeating: .notAnswered, count: numberOfRounds)
                currentScene = "GetReady"
            }){
                Text("PLAY AGAIN")
            }
            .buttonStyle(OrdinaryButtonStyle())
            .padding()
            
            Spacer()
            
            Button(action: {
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
            fetchTopHighscores()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                
                checkUserHighscore()
            }
            
            if score > highestScore {
                UserDefaults.standard.set(score, forKey: "highScore")
                UserDefaults.standard.synchronize()
            }
            withAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    //what?
                }
            }
        }
        
    }
    private func loadData() {
        let file = Bundle.main.path(forResource: "countries", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: file))
        let decoder = JSONDecoder()
        self.countries = try! decoder.decode([Country].self, from: data)
    }
    
    private func fetchTopHighscores() {
        guard let url = URL(string: "https://eu-1.lolo.co/uGPiCKZAeeaKs83jaRaJiV/highscores") else {
            return
        }
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

        if userRank < 10 {
            // User's score qualifies for the leaderboard
            let playerName = "Tom" // Replace with the player's name
            let newHighscore = Highscore(id: UUID().uuidString, score: userScore, playerName: playerName, rank: userRank + 1)

            // Insert the new highscore at the appropriate position
            highscores.insert(newHighscore, at: userRank)

            // Trim the highscores array to contain only the top 10 scores
            if highscores.count > 10 {
                highscores.removeLast(highscores.count - 10)
            }

            // Update the ranks of the highscores
            updateHighscoreRanks()

            // Update the leaderboard on the server
            postUpdatedHighscores()
        } else {
            // User's score does not qualify for the leaderboard
            print("Your score does not make it to the top 10.")
        }
    }


    private func updateHighscoreRanks() {
        for (index, _) in highscores.enumerated() {
            highscores[index].rank = index + 1
        }
    }



    private func postUpdatedHighscores() {
        // Prepare the updated highscores array to send to the server
        let updatedHighscores = UpdatedHighscores(highscores: highscores)
        
        guard let url = URL(string: "https://eu-1.lolo.co/uGPiCKZAeeaKs83jaRaJiV/highscores/d26F26cYyUpPdHmCUnyd6H") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT" // Use PUT instead of POST
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase // Convert camelCase to snake_case
            
            let requestData = try encoder.encode(updatedHighscores)
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
    let playerName: String
    var rank: Int

    private enum CodingKeys: String, CodingKey {
        case id, score, playerName = "player_name", rank
    }
}



struct UpdatedHighscores: Codable {
    let highscores: [Highscore]
}

