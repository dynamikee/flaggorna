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
    @State private var enteredPlayerName: String = (UserDefaults.standard.string(forKey: "userName") ?? "")
    @State private var showSubmitHighscore = false
    @State private var isLoading = true
    
    var body: some View {
        
        VStack (spacing: 16) {
            Spacer()
            
            if score > highestScore || highscores.prefix(5).contains(where: { $0.score < score }) {
                if showSubmitHighscore {
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
                            showSubmitHighscore = false
                            updateHighscoreRanks()
                            postUpdatedHighscores(playerName: String(enteredPlayerName.prefix(20))) // Pass enteredPlayerName to the function
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
                    
                } else {

                    VStack(spacing: 8) {
                            Text("HIGHSCORES")
                                .font(.largeTitle)
                                .fontWeight(.black)
                                .foregroundColor(.white)
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
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
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
                    .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        currentScene = "Start"
                    }) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                    }
                    .padding()
                    
                    
                }
                
            } else {
                // if you didnt make it to the top 5
                
                    VStack(spacing: 8) {
                        Text("HIGHSCORES")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundColor(.white)
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
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                
                
                Text("Your score: \(score) (\(highestScore))")
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
                .padding()
                
                Spacer()
                
                Button(action: {
                    currentScene = "Start"
                }) {
                    Image(systemName: "xmark")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
                .padding()
                
                
                
            }
            
        }
        .onAppear() {
            fetchTopHighscores()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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
        
        if userRank < 5 {
            // User's score qualifies for the leaderboard
            let newHighscore = Highscore(id: UUID().uuidString, score: userScore, playerName: "", rank: userRank + 1)
            
            // Insert the new highscore at the appropriate position
            highscores.insert(newHighscore, at: userRank)
            
            // Trim the highscores array to contain only the top 10 scores
            if highscores.count > 5 {
                highscores.removeLast(highscores.count - 5)
            }

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
    
    private func postUpdatedHighscores(playerName: String) {
        guard let userRank = highscores.firstIndex(where: { $0.playerName == "" }) else {
            return
        }

        highscores[userRank].playerName = playerName

        // Create a request to update the highscores on the server
        guard let url = URL(string: "https://eu-1.lolo.co/uGPiCKZAeeaKs83jaRaJiV/highscores/tRaYptqu5Bh3ceput8cSBg") else {
            return
        }

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

