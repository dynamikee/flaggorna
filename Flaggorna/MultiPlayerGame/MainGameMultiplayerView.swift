//
//  MainGameMultiplayerView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-22.
//

import SwiftUI
import SceneKit
import UIKit
import CoreData

struct MainGameMultiplayerView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int
    
    @EnvironmentObject var socketManager: SocketManager
    
    @State private var timeRemaining = 4 // 4 seconds timer
    @State private var answered = false
    @State private var startTime: Date?
    
    @State private var scene = SCNScene()
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack {
            ProgressView(value: Double(timeRemaining), total: 4) {
                
            }
            .frame(height: 10)
            .progressViewStyle(MyProgressViewStyle())
            .animation(.linear(duration: 1), value: timeRemaining) // Add an animation modifier with a linear timing curve
            
            
            if let question = socketManager.currentQuestion {
                
                Spacer()
                
                    #if FLAGGORNA
                GeometryReader { geometry in
                    SceneViewContainer(scene: scene, randomCountry: question.flag)
                        .frame(height: geometry.size.width * 0.9)
                }
                    #elseif TEAM_LOGO_QUIZ
                Spacer()
                    Image(question.flag)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                
                Spacer()
                    #endif
                                
                
                
                Spacer()
                VStack(spacing: 24) {
                    
                    ForEach(question.answerOptions, id: \.self) { option in
                        
                        Button(action: {
                            let endTime = Date() // Get the end time when the user taps the button
                            let timeTaken = endTime.timeIntervalSince(self.startTime ?? Date())
                            
                            if option == question.correctAnswer {
                                answered = true
                                socketManager.countries.removeAll { $0.name == question.correctAnswer }
                                socketManager.currentUser!.score += calculateScore(timeTaken: timeTaken)
                                
                                if rounds > 0 {
                                    socketManager.currentUser!.currentRound -= 1
                                    rounds -= 1
                                }
                                
                                socketManager.currentScene = "RightMultiplayer"
                                socketManager.updateUser()
                                print("Number of remaining countries: \(socketManager.countries.count)")
                                updateFlagData(isCorrect: true)
                                
                                
                            } else {
                                answered = true
                                if rounds > 0 {
                                    socketManager.currentUser!.currentRound -= 1
                                    rounds -= 1
                                }
                                socketManager.countries.removeAll { $0.name == question.correctAnswer }
                                socketManager.currentScene = "WrongMultiplayer"
                                socketManager.updateUser()
                                print("Number of remaining countries: \(socketManager.countries.count)")
                                updateFlagData(isCorrect: false)
                                
                                
                            }
                        }) {
                            Text(option)
                        }
                        
                        .buttonStyle(CountryButtonStyle())
                    }
                }
                
                .padding(8)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            
            self.startTime = Date()
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if answered {
                    timer.invalidate()
                } else {
                    if self.timeRemaining > 0 {
                        self.timeRemaining -= 1
                    } else {
                        timer.invalidate()
                        socketManager.currentUser!.currentRound -= 1
                        rounds -= 1
                        socketManager.countries.removeAll { $0.name == socketManager.currentQuestion?.correctAnswer }
                        socketManager.currentScene = "WrongMultiplayer"
                        socketManager.updateUser()
                        print("Number of remaining countries: \(socketManager.countries.count)")
                        updateFlagData(isCorrect: false)
                        
                    }
                }
                
            }
        }
    }
    //This is for updating user statistics on core data
    private func updateFlagData(isCorrect: Bool) {
        guard let question = socketManager.currentQuestion else { return }
        
        let request: NSFetchRequest<FlagData> = FlagData.fetchRequest()
        request.predicate = NSPredicate(format: "country_name == %@", question.correctAnswer)
        
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
    
    private func updateUserSpeed(newRoundSpeed: Double) {
        let request: NSFetchRequest<FlagData> = FlagData.fetchRequest()
        
        do {
            let results = try viewContext.fetch(request)

            if let flagData = results.first {
                
                if flagData.user_speed > 0 {
                    // Calculate the total cumulative speed achieved so far
                    let totalSpeedAchievedSoFar = flagData.user_speed * Double(flagData.user_questions_answered)
                    
                    flagData.user_questions_answered += 1
                    
                    // Calculate the new total cumulative speed by adding the speed of the current round
                    let newTotalSpeed = totalSpeedAchievedSoFar + newRoundSpeed
                    
                    // Calculate the new average speed
                    let newAverageSpeed = newTotalSpeed / Double(flagData.user_questions_answered)
                    
                    flagData.user_speed = newAverageSpeed
                } else {
                    // If there's no existing speed data, use the current speed directly
                    flagData.user_speed = newRoundSpeed
                    flagData.user_questions_answered += 1
                }

                try viewContext.save()
            }
        } catch {
            // Handle error
            print("Error updating user speed: \(error)")
        }
    }
    
}

struct MyProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        let percent = configuration.fractionCompleted ?? 0
        return ZStack(alignment: .leading) {
            // Gray background bar
            RoundedRectangle(cornerRadius: 0)
                .foregroundColor(.gray.opacity(0.2))
            
            // Green progress bar
            RoundedRectangle(cornerRadius: 0)
                .frame(width: percent * UIScreen.main.bounds.width, height: 10)
                .foregroundColor(.white)
            
            // Label with time remaining
            //configuration.label
        }
    }
}





