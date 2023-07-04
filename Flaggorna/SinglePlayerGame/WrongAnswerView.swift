//
//  WrongAnswerView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-18.
//

import SwiftUI
import CoreData


struct WrongAnswerView: View {
    
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int
    @Binding var currentCountry: String
    @Binding var numberOfRounds: Int
    @Binding var roundsArray: [RoundStatus]
    
    
    var body: some View {
        VStack(spacing: 32) {
            HStack {
                ForEach(roundsArray.reversed(), id: \.self) { roundStatus in
                    switch roundStatus {
                    case .notAnswered:
                        Image(systemName: "circle.dotted")
                            .foregroundColor(.gray)
                    case .correct:
                        Image(systemName: "circle.fill")
                            .foregroundColor(.green)
                    case .incorrect:
                        Image(systemName: "circle.slash")
                            .foregroundColor(.red)
                    }
                    
                }
                Spacer()
                ZStack {
                    Circle()
                        .foregroundColor(.yellow)
                        .frame(width: 32, height: 32)
                    Text(String(score))
                        .foregroundColor(.black)
                }
            }
            .padding()
            .foregroundColor(.white)
            .fontWeight(.bold)

            
            Spacer()
            Text("Oh no!")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)
            Text("It was \(currentCountry)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Spacer()
            
            Button(action: {
                loadData()
                score = 0
                rounds = 10
                roundsArray = Array(repeating: .notAnswered, count: numberOfRounds)
                currentScene = "GetReady"
            }) {
                Image(systemName: "gobackward")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .padding(24)
            

            
        }
        .onAppear {
            withAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    if rounds > 0 {
                        self.currentScene = "Main"
                    } else {
                        self.currentScene = "GameOver"
                    }
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
    
}
