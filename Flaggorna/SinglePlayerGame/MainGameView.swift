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

    var body: some View {
        let randomCountry = countries.randomElement()!
        let currentCountry = randomCountry.name
        let countryAlternatives = countries.filter { $0.name != currentCountry }
        var randomCountryNames = countryAlternatives.map { $0.name }.shuffled().prefix(3)
        randomCountryNames.append(currentCountry)
        randomCountryNames.shuffle()
  
        return VStack {
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
            .padding(24)

            Spacer()
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
                    }) {
                        Text(countryName)
                    }
                    .buttonStyle(CountryButtonStyle())
                    
                }
            }
            .padding(8)
        }
    }
}
