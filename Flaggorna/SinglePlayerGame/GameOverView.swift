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

    
    var body: some View {
        VStack {
            Text("Your score: \(score)")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            Button(action: {
                currentScene = "Start"
            }){
                Text("Continue")
            }
            .buttonStyle(OrdinaryButtonStyle())
            .padding()
        }
        
    }
}
