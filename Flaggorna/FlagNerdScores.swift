//
//  FlagNerdScores.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-08-18.
//

import SwiftUI
import CoreData


struct FlagNerdScores: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}


func updateUserFlagNerdScore (newRoundSpeed: Double, isCorrect: Bool) {
    
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
                    var numberOfCorrectAnswers = 0.0
                    
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
                    var numberOfCorrectAnswers = 1.0
                    
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
    
