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
    
    
    var body: some View {
        VStack {
            Spacer()
            Text("Wrong answer")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            Text("Your score: \(score)")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)

            Spacer()
            
        }
        .onAppear {
            withAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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
