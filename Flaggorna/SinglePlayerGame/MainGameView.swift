//
//  MainGameView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-18.
//

import SwiftUI

struct MainGameView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int
    @Binding var currentCountry: String
    
    @State private var timeRemaining = 4 // 4 seconds timer
    @State private var answered = false
    
    @State private var randomCountry: Country?
    @State private var randomCountryNames: [String] = []
    //@State private var currentCountry = ""
    
    var timer: Timer?

    var body: some View {

  
        VStack {
            ProgressView(value: Double(timeRemaining), total: 4) {
                
            }
            .frame(height: 10)
            .progressViewStyle(MyProgressViewStyle())
            .animation(.linear(duration: 1), value: timeRemaining) // Add an animation modifier with a linear timing curve

            HStack{
                Text("Score: \(score)")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                Spacer()
                Text("Round: \(rounds)")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
            }
            .padding()


            Spacer()

            if let randomCountry = randomCountry {
                
            
                
            Image(randomCountry.flag)
                    .resizable()
                    .border(.gray, width: 1)
                    
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.width * 0.8)
                
                Spacer()
                VStack(spacing: 24){
                    ForEach(randomCountryNames, id: \.self) { countryName in
                        Button(action: {
                            if strcmp(currentCountry, countryName) == 0 {
                                self.score += 1
                                if self.rounds > 0 {
                                    self.rounds -= 1
                                }
                                self.countries.removeAll { $0.name == currentCountry }
                                self.currentScene = "Right"

                                
                            } else {
                                if self.rounds > 0 {
                                    self.rounds -= 1
                                }
                                self.countries.removeAll { $0.name == currentCountry }
                                self.currentScene = "Wrong"
                                
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
                        //self.countries.removeAll { $0.name == self.currentCountry }
                        self.currentScene = "Wrong"

                    }
                }
                
            }
        }
    }
}
