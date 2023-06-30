//
//  StartGameView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-18.
//

import SwiftUI
import CoreData
import UIKit

struct StartGameView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int
    @Binding var multiplayer: Bool
    @Binding var numberOfRounds: Int
    @Binding var roundsArray: [RoundStatus]
    
    @State private var offset = CGSize.zero
    @State private var isSettingsViewActive = false
    
    @State private var playButtonScale: CGFloat = 1.0
    
    var body: some View {
        
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isSettingsViewActive = true
                        
                    }){
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    
                    }
                    .buttonStyle(OrdinaryButtonStyle())
                    .padding()
                    .sheet(isPresented: $isSettingsViewActive) {
                                    FlagStatisticsView(flagData: fetchFlagData())
                                }
                    
                }
                
                Spacer()
                Spacer()

                    Button(action: {
                        score = 0
                        rounds = numberOfRounds
                        multiplayer = true
                        SocketManager.shared.currentScene = "JoinMultiplayerPeer"
                        
                    }){
                        VStack {
                            Image("party_quiz_logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 300)
                                .foregroundColor(.white)
                            
                            Image("play_button")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 140)
                                .scaleEffect(playButtonScale)
                                .animation(.spring())
                                .padding(8)
                        }
                        
  
                    }

                Spacer()
                Spacer()
       
                Button(action: {
                    loadData()
                    score = 0
                    rounds = numberOfRounds
                    self.roundsArray = Array(repeating: .notAnswered, count: numberOfRounds)
                    currentScene = "GetReady"
                }){
                    Text("SINGLE PLAYER")
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
                    .edgesIgnoringSafeArea(.all)
                
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: 5)
                                .repeatForever(autoreverses: true)
                        ) {
                            self.offset.height = -100
                        }
                    }
            )
            //.edgesIgnoringSafeArea(.all)
            .onAppear {
                SocketManager.shared.loadData()
                animatePlayButton()
            }
            
    }
    
    private func animatePlayButton() {
        withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 100, damping: 10, initialVelocity: 0)) {
            playButtonScale = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 100, damping: 10, initialVelocity: 0)) {
                playButtonScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                animatePlayButton() // Recursively call the function to create a loop
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
                Text("Your answers")
                    .bold()
                    .padding(.top, 24)
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
                                .padding(8)
                        }
                        .padding(4)
                    }
                    
                    VStack {
                                    Button(action: {
                                        // Open Terms of Use (EULA)
                                        openTermsOfUse()
                                    }) {
                                        Text("Terms of Use")
                                            .foregroundColor(.blue)
                                            .underline()
                                    }.padding(24)
                                    
                                    Button(action: {
                                        // Open Privacy Policy
                                        openPrivacyPolicy()
                                    }) {
                                        Text("Privacy Policy")
                                            .foregroundColor(.blue)
                                            .underline()
                                    }.padding(24)
                                }
                                .padding(24)
                        
                }
                .padding()
            }
            .preferredColorScheme(.dark)
        }
    }
    private func openTermsOfUse() {
        guard let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") else {
            return // Invalid URL, handle the error gracefully
        }

        let options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:]

        UIApplication.shared.open(termsOfUseURL, options: options) { success in
            if !success {
                // Failed to open the Terms of Use document, handle the error gracefully
            }
        }
    }
    
    private func openPrivacyPolicy() {
        guard let termsOfUseURL = URL(string: "https://bangahantverk.com/pages/flag-party-quiz-privacy-policy") else {
            return // Invalid URL, handle the error gracefully
        }

        let options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:]

        UIApplication.shared.open(termsOfUseURL, options: options) { success in
            if !success {
                // Failed to open the Terms of Use document, handle the error gracefully
            }
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
            symbolName = "circle.dotted"
            color = .gray
        } else if correctRatio >= greenThreshold {
            symbolName = "circle.fill"
            color = .green
        } else if correctRatio <= redThreshold {
            symbolName = "circle.slash"
            color = .red
        } else {
            symbolName = "circle.bottomhalf.filled"
            color = .yellow
        }
        
        return Image(systemName: symbolName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
            .foregroundColor(color)
    }
}

