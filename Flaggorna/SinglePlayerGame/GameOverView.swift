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

    @State var highestScore = UserDefaults.standard.integer(forKey: "highScore")

    
    
    var body: some View {
        

        
        VStack (spacing: 16) {
            Spacer()
            if score > highestScore {
                Text("NEW HIGH SCORE!")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                Text("\(score)")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                        .modifier(ParticlesModifier())
                        .offset(x: -100, y : -50)
                            
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .modifier(ParticlesModifier())
                        .offset(x: 60, y : 70)
                }
                
            } else {
                Text("Current high score: \(highestScore)")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                Text("Your score: \(score)")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                
            }
            

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
        .onAppear() {
            if score > highestScore {
                UserDefaults.standard.set(score, forKey: "highScore")
                UserDefaults.standard.synchronize()
            }
            withAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    //what?
                }
            }
        }
        
    }
    private func loadData() {
        let file = Bundle.main.path(forResource: "countries", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: file))
        let decoder = JSONDecoder()
        self.countries = try! decoder.decode([Country].self, from: data)
    }
    
}
