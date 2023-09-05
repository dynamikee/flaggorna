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
    @Binding var selectedContinents: [String]
    
    
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
            
//            Button(action: {
//                FlagDataManager.loadDataAndUpdateFlagData() { countries in
//                    self.countries = countries
//                }
//                
//                let filteredCountries = countries.filter { selectedContinents.contains($0.continent) }
//                self.countries = filteredCountries
//                
//                score = 0
//                rounds = 10
//                roundsArray = Array(repeating: .notAnswered, count: numberOfRounds)
//                currentScene = "GetReady"
//            }) {
//                Image(systemName: "gobackward")
//                    .font(.title)
//                    .foregroundColor(.white)
//            }
//            .padding(24)
            

            
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
    
}
