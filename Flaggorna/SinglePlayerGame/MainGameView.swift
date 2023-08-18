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
                
                
                    #if FLAGGORNA
                GeometryReader { geometry in
                    SceneViewContainer(scene: scene, randomCountry: randomCountry.flag)
                                        .frame(height: geometry.size.width * 0.9)
                }
                    #elseif TEAM_LOGO_QUIZ
                Spacer()
                    Image(randomCountry.flag)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                
                Spacer()
                    #endif
                                
                
                
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
                                
                                //updateUserSpeed(newRoundSpeed: timeTaken)
                                updateUserFlagNerdScore(newRoundSpeed: timeTaken, isCorrect: true)

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
                                updateUserFlagNerdScore(newRoundSpeed: timeTaken, isCorrect: false)
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
    
    private func updateUserFlagNerdScore (newRoundSpeed: Double, isCorrect: Bool) {
        
        //Du måste komma hit oavsett om du har rätt eller inte.
        
        // om du har rätt uppdatera flag.user_speed enligt nedan.
        // hämta average_accuracy * antalet frågor du svarat på (core data stuff) 0.5 * 10
        // Då får vi antalet frågor du svarat rätt på i core data NumberOfCorrectAnswers 5
        // Lägg till en på antal frågor som du svarat rätt på 6
        // Lägg till en på antalet frågor du svarat på 11
        // Dela antal rätt frågor / totalt antal frågor 6 / 11
        // Spara nytt average 0.5454
        
        // om du har fel uppdatera inte flagData.user_speed
        // hämta average_accuracy * antalet frågor som du svarat på (core data stuff) 0.5 * 10
        // Då får vi antalet frågor du svarat rätt på i core data 5
        // Lägg inte till på frågor du svarat rätt på 5
        // Lätt till en till antalet frågor du svarat på 11
        // Spara nytt average 0.4545
        
        let request: NSFetchRequest<FlagData> = FlagData.fetchRequest()
        
        do {
            let results = try viewContext.fetch(request)

            if let flagData = results.first {
                
                if isCorrect {
                    if flagData.user_accuracy > 0 {
                        
                        var numberOfCorrectAnswers = flagData.user_accuracy * Double(flagData.user_total_answers)
                        
                        numberOfCorrectAnswers += 1
                        flagData.user_total_answers += 1
                        
                        let newAccuracy = numberOfCorrectAnswers / Double(flagData.user_total_answers)
                        
                        flagData.user_accuracy = newAccuracy
  
                    } else {
                        var numberOfCorrectAnswers = 1.0
                        
                        flagData.user_total_answers += 1
                        
                        let newAccuracy = numberOfCorrectAnswers / Double(flagData.user_total_answers)
                        
                        flagData.user_accuracy = newAccuracy
                        
                    }

                } else {
                    if flagData.user_accuracy > 0 {
                        
                        var numberOfCorrectAnswers = flagData.user_accuracy * Double(flagData.user_total_answers)
                        
                        flagData.user_total_answers += 1
                        
                        let newAccuracy = numberOfCorrectAnswers / Double(flagData.user_total_answers)
                        
                        flagData.user_accuracy = newAccuracy
  
                    } else {
                        var numberOfCorrectAnswers = 0.0
                        
                        flagData.user_total_answers += 1
                        
                        let newAccuracy = numberOfCorrectAnswers / Double(flagData.user_total_answers)
                        
                        flagData.user_accuracy = newAccuracy
                        
                    }
                }
                
                if isCorrect {
                    
                    if flagData.user_speed > 0 {
                        // Calculate the total cumulative speed achieved so far
                        let totalSpeedAchievedSoFar = flagData.user_speed * Double(flagData.user_correct_answers)
                        
                        flagData.user_correct_answers += 1
                        
                        // Calculate the new total cumulative speed by adding the speed of the current round
                        let newTotalSpeed = totalSpeedAchievedSoFar + newRoundSpeed
                        
                        // Calculate the new average speed
                        let newAverageSpeed = newTotalSpeed / Double(flagData.user_correct_answers)
                        
                        flagData.user_speed = newAverageSpeed
                    } else {
                        // If there's no existing speed data, use the current speed directly
                        flagData.user_speed = newRoundSpeed
                        flagData.user_correct_answers += 1
                    }
                }
                
                try viewContext.save()
            }
        } catch {
            // Handle error
            print("Error updating user speed: \(error)")
        }
    }


}



