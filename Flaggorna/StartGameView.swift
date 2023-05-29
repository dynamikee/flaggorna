//
//  StartGameView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-18.
//

import SwiftUI
import CoreData

struct StartGameView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int
    @Binding var multiplayer: Bool
    @Binding var numberOfRounds: Int
    @Binding var roundsArray: [RoundStatus]
    
    @State private var offset = CGSize.zero
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    NavigationLink(destination: FlagStatisticsView(flagData: fetchFlagData())) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(OrdinaryButtonStyle())
                    .padding(.top, 64)
                    .padding(.trailing, 16)
                    .alignmentGuide(HorizontalAlignment.trailing) { _ in
                        UIScreen.main.bounds.width - 24 // Adjust the offset as needed
                    }
                }
                Spacer()
                
                Button(action: {
                    score = 0
                    rounds = numberOfRounds
                    multiplayer = true
                    SocketManager.shared.currentScene = "JoinMultiplayer"
                    
                }){
                    Text("PARTY GAME")
                }
                .buttonStyle(OrdinaryButtonStyle())
                .padding()
                
                Button(action: {
                    loadData()
                    score = 0
                    rounds = numberOfRounds
                    self.roundsArray = Array(repeating: .notAnswered, count: numberOfRounds)
                    currentScene = "GetReady"
                }){
                    Text("SINGLE GAME")
                }
                .buttonStyle(OrdinaryButtonStyle())
                .padding()
                
                Spacer()
                
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
            .onAppear {
                SocketManager.shared.loadData()
            }
        }
        .navigationBarTitle("Start Game")
        .accentColor(.white)
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
}

struct FlagStatisticsView: View {
    let flagData: [FlagData]
    
    var sortedFlagData: [FlagData] {
        flagData.sorted { $0.country_name ?? "" < $1.country_name ?? "" }
    }
    
    var body: some View {
        ZStack {
            Color(UIColor(red: 0.11, green: 0.11, blue: 0.15, alpha: 1.00))
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack {
                    ForEach(sortedFlagData, id: \.self) { data in
                        HStack {
                            Image(data.flag ?? "")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 64)
                                .border(Color.gray, width: 1)
                                .padding(.trailing, 8)
                            Text(data.country_name ?? "")
                                .font(.body)
                                .fontWeight(.bold)
                            Spacer()
                            Text("Correct: \(data.right_answers) of \(data.impressions)")
                                .font(.footnote)
                            CircleIndicatorView(data: data)
                        }
                        .padding(8)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

struct CircleIndicatorView: View {
    let data: FlagData
    
    private let greenThreshold: Double = 0.75
    private let redThreshold: Double = 0.35
    
    var body: some View {
        let correctRatio = data.impressions > 0 ? Double(data.right_answers) / Double(data.impressions) : 0
        let symbolName: String
        let color: Color
        
        if data.impressions == 0 {
            symbolName = "seal.fill"
            color = .gray
        } else if correctRatio >= greenThreshold {
            symbolName = "checkmark.seal.fill"
            color = .green
        } else if correctRatio <= redThreshold {
            symbolName = "xmark.seal.fill"
            color = .red
        } else {
            symbolName = "seal.fill"
            color = .yellow
        }
        
        return Image(systemName: symbolName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 32, height: 32)
            .foregroundColor(color)
    }
}

