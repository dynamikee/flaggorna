//
//  ContentView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-12.
//

import SwiftUI

struct ContentView: View {
    @State var currentScene = "Start"
    
    var body: some View {
        
        switch currentScene {
        case "Start":
            StartGameView(currentScene: $currentScene)
        case "Main":
            MainGameView(currentScene: $currentScene)
        case "Right":
            RightAnswerView(currentScene: $currentScene)
        case "Wrong":
            WrongAnswerView(currentScene: $currentScene)
        case "GameOver":
            GameOverView(currentScene: $currentScene)
        default:
            StartGameView(currentScene: $currentScene)
        }
    }
}

struct StartGameView: View {
    
    @Binding var currentScene: String
    
    var body: some View {
        Button(action: {
            currentScene = "Main"
        }){
            Text("Start game")
        }
        .padding()
    }
}

struct MainGameView: View {
    
    @Binding var currentScene: String
    
    var body: some View {
        Button(action: {
            currentScene = "Right"
        }){
            Text("Right")
        }
        .padding()
        Button(action: {
            currentScene = "Wrong"
        }){
            Text("Wrong")
        }
        .padding()
    }
}

struct RightAnswerView: View {
    
    @Binding var currentScene: String
    
    var body: some View {
        Button(action: {
            currentScene = "Main"
        }){
            Text("Continue..")
        }
        .padding()
    }
    
}

struct WrongAnswerView: View {
    
    @Binding var currentScene: String
    
    var body: some View {
        Button(action: {
            currentScene = "GameOver"
        }){
            Text("Continue..")
        }
        .padding()
    }
    
}



struct GameOverView: View {
    
    @Binding var currentScene: String
    
    var body: some View {
        Button(action: {
            currentScene = "Start"
        }){
            Text("GAME OVER !")
        }
        .padding()
    }
}


