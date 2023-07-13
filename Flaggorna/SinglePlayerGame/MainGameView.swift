//
//  MainGameView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-18.
//

import SwiftUI
import UIKit
import SceneKit
import CoreData

struct MainGameView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int
    @Binding var currentCountry: String
    @Binding var roundsArray: [RoundStatus]
    
    @State private var timeRemaining = 4 // 4 seconds timer
    @State private var answered = false
    
    @State private var randomCountry: Country?
    @State private var randomCountryNames: [String] = []
    @State private var startTime: Date?
    
    @State private var scene = SCNScene()

    @Environment(\.managedObjectContext) private var viewContext
    
    var timer: Timer?
    
    var body: some View {
    
        VStack {
            ProgressView(value: Double(timeRemaining), total: 4) {
                
            }
            .frame(height: 10)
            .progressViewStyle(MyProgressViewStyle())
            .animation(.linear(duration: 1), value: timeRemaining) // Add an animation modifier with a linear timing curve
            
            
            if let randomCountry = randomCountry {
                
                GeometryReader { geometry in
                    SceneViewContainer(scene: scene, randomCountry: randomCountry.flag)
                                        .frame(height: geometry.size.width * 0.9)
                                }
                
                
                VStack(spacing: 24){
                    ForEach(randomCountryNames, id: \.self) { countryName in
                        Button(action: {
                            let endTime = Date() // Get the end time when the user taps the button
                            let timeTaken = endTime.timeIntervalSince(self.startTime ?? Date())
                            
                            if strcmp(currentCountry, countryName) == 0 {
                                //self.score += 1
                                if self.rounds > 0 {
                                    self.rounds -= 1
                                }
                                
                                self.score += calculateScore(timeTaken: timeTaken)
                                print(timeTaken)
                                print(self.score)
                                
                                self.countries.removeAll { $0.name == currentCountry }
                                self.roundsArray[self.rounds] = .correct
                                self.currentScene = "Right"
                                updateFlagData(isCorrect: true)
                                
                                
                            } else {
                                if self.rounds > 0 {
                                    self.rounds -= 1
                                }
                                self.countries.removeAll { $0.name == currentCountry }
                                self.roundsArray[self.rounds] = .incorrect
                                self.currentScene = "Wrong"
                                updateFlagData(isCorrect: false)
                                
                            }
                            
                            self.answered = true // set answered to true to invalidate the timer
                            if let timer = timer {
                                timer.invalidate()
                            }
                        }) {
                            Text(countryName)
                        }
                        .buttonStyle(CountryButtonStyle())
                        
                    }
                }
                .padding(8)

            }
            
        }
        .onAppear {
            
            if let randomCountry = countries.randomElement() {
                self.randomCountry = randomCountry
                self.currentCountry = randomCountry.name
                let countryAlternatives = countries
                    .filter { $0.name != randomCountry.name }
                    .shuffled()
                    .prefix(3)
                    .map { $0.name }
                self.randomCountryNames = countryAlternatives + [randomCountry.name]
                self.randomCountryNames.shuffle()
                self.startTime = Date()
            } else {
                // Handle the case where the countries array is empty
                print("Error: The countries array is empty!")
            }
            
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if answered {
                    timer.invalidate()
                } else {
                    if self.timeRemaining > 0 {
                        self.timeRemaining -= 1
                    } else {
                        timer.invalidate()
                        if self.rounds > 0 {
                            self.rounds -= 1
                        }
                        self.roundsArray[self.rounds] = .incorrect
                        self.currentScene = "Wrong"
                        updateFlagData(isCorrect: false)
                        
                    }
                }
                
            }
        }
    }
    //This update is for user statistics on right answers only
    private func updateFlagData(isCorrect: Bool) {
        let request: NSFetchRequest<FlagData> = FlagData.fetchRequest()
        request.predicate = NSPredicate(format: "country_name == %@", currentCountry)
        
        do {
            let results = try viewContext.fetch(request)
            
            if let flagData = results.first {
                flagData.impressions += 1
                
                if isCorrect {
                    flagData.right_answers += 1
                }
                
                try viewContext.save()
            }
        } catch {
            // Handle error
            print("Error updating flag data: \(error)")
        }
    }
}



