//
//  GameOverView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-18.
//

import SwiftUI

struct GameOverView: View {
    
    @Binding var currentScene: String
    @Binding var score: Int
    @Binding var rounds: Int
    @Binding var countries: [Country]
    @Binding var numberOfRounds: Int
    @Binding var roundsArray: [RoundStatus]

    
    var body: some View {
        VStack {
            Spacer()
            Text("Your score: \(score) of \(numberOfRounds)")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            Button(action: {
                loadData()
                score = 0
                rounds = 10
                self.roundsArray = Array(repeating: .notAnswered, count: numberOfRounds)
                currentScene = "GetReady"
            }){
                Text("PLAY AGAIN")
            }
            .buttonStyle(OrdinaryButtonStyle())
            .padding()
            
            Spacer()
            
            Button(action: {
                currentScene = "Start"
            }){
                Text(Image(systemName: "xmark"))
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
            }
            .padding()
        }
        
    }
    private func loadData() {
        let file = Bundle.main.path(forResource: "countries", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: file))
        let decoder = JSONDecoder()
        self.countries = try! decoder.decode([Country].self, from: data)
    }
    
}
