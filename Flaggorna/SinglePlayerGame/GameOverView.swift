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

    
    var body: some View {
        VStack {
            Spacer()
            Text("Your score: \(score) of 10")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            Button(action: {
                loadData()
                score = 0
                rounds = 10
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
                Text("EXIT")
            }
            .buttonStyle(OrdinaryButtonStyle())
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
