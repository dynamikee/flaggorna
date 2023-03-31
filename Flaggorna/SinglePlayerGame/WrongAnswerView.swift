//
//  WrongAnswerView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-18.
//

import SwiftUI

struct WrongAnswerView: View {
    
    @Binding var currentScene: String
    @Binding var score: Int
    @Binding var rounds: Int
    @Binding var currentCountry: String
    @Binding var roundsArray: [RoundStatus]
    
    
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
                            .foregroundColor(.gray)
                    case .incorrect:
                        Image(systemName: "circle.slash")
                            .foregroundColor(.gray)
                    }
                    
                }
            }
            Spacer()
            Text("Oh no!")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            Text("It was \(currentCountry)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Spacer()
            
            
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
