//
//  StartGameView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-18.
//

import SwiftUI

struct StartGameView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int
    
    @State private var offset = CGSize.zero
    
    var body: some View {
        VStack {
            Button(action: {
                loadData()
                score = 0
                rounds = 3
                currentScene = "GetReadyMultiplayer"
                
            }){
                Text("PARTY GAME")
            }
            .buttonStyle(OrdinaryButtonStyle())
            .padding()
            
            Button(action: {
                loadData()
                score = 0
                rounds = 3
                currentScene = "GetReady"
            }){
                Text("SINGLE GAME")
            }
            .buttonStyle(OrdinaryButtonStyle())
            .padding()
        }
        
        .background(
            Image("background")
                .resizable()
                .scaledToFill()
                //.aspectRatio(contentMode: .fill)
                .offset(x: offset.width, y: offset.height)
                .frame(width: UIScreen.main.bounds.width)

                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 5)
                            .repeatForever(autoreverses: true)
                    ) {
                        self.offset.height = -100
                    }
                }
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    private func loadData() {
        let file = Bundle.main.path(forResource: "countries", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: file))
        let decoder = JSONDecoder()
        self.countries = try! decoder.decode([Country].self, from: data)
    }
}
