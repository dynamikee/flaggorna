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
    @State private var isShimmering = false

   

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
                ZStack {
                    Circle()
                        .foregroundColor(.yellow)
                        .frame(width: 32, height: 32)
                        .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.7), lineWidth: 2)
                                        .scaleEffect(isShimmering ? 1.2 : 1.0)
                                        .opacity(isShimmering ? 0.7 : 0.0)
                                        .animation(Animation.linear(duration: 1).repeatForever(autoreverses: true))
                        )
                    Text(String(score))
                        .foregroundColor(.black)
                }
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
                    .fill(Color.orange)
                    .frame(width: 12, height: 12)
                    .modifier(ParticlesModifier())
                    .offset(x: -100, y : -50)
                        
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .modifier(ParticlesModifier())
                    .offset(x: 60, y : 70)
                
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 12, height: 12)
                    .modifier(ParticlesModifier())
                    .offset(x: 0, y : 0)
            }
            Spacer()
            
        }
        .onAppear {
            isShimmering = true
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
