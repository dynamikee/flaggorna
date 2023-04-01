//
//  RightAnswerView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-18.
//

import SwiftUI

struct RightAnswerView: View {
    @Binding var currentScene: String
    @Binding var score: Int
    @Binding var rounds: Int
    @Binding var roundsArray: [RoundStatus]
   

    var body: some View {
        VStack {
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
                Text("Score: \(score)")
            }
            .padding()
            .foregroundColor(.white)
            .fontWeight(.bold)
            
            Spacer()
            Text("Right answer!")
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
            Spacer()
            
        }
        .onAppear {
            withAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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
