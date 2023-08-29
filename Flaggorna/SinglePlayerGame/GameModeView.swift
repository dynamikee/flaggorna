//
//  GameModeView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-08-29.
//

import SwiftUI

struct GameModeView: View {
    
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var multiplayer: Bool
    @Binding var selectedContinents: [String]
    
    @EnvironmentObject var socketManager: SocketManager

    //@State private var selectedContinents: [String] = []
    @State private var continentList: [String] = []
    
    var body: some View {
        VStack {
            Text("Choose continent")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            ScrollView {
                VStack (alignment: .leading) {
                    ForEach(continentList.sorted(), id: \.self) { continent in
                                    Button(action: {
                                        if selectedContinents.contains(continent) {
                                            selectedContinents.removeAll(where: { $0 == continent })
                                            } else {
                                                selectedContinents.append   (continent)
                                            }
                                    }) {
                                        HStack {
                                            Image(systemName: selectedContinents.contains(continent) ? "checkmark.square.fill" : "square")
                                                .resizable()
                                                .frame(width: 32, height: 32)
                                                .foregroundColor(selectedContinents.contains(continent) ? .white : .white)
                                                .fontWeight(.bold)
                                            
                                            Text(continent)
                                                .font(.title)
                                                .fontWeight(.black)
                                                .foregroundColor(.white)
                                            Spacer()
                                            
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                    Spacer()
//                            Text("Choose level")
//                                .font(.title)
//                                .fontWeight(.black)
//                                .foregroundColor(.white)
//                            ForEach(levelList, id: \.self) { level in
//                                            Button(action: {
//                                                selectedLevel = level
//                                            }) {
//                                                HStack {
//                                                    Image(systemName: selectedLevel == level ? "largecircle.fill.circle" : "circle")
//                                                        .resizable()
//                                                        .frame(width: 24, height: 24)
//                                                        .foregroundColor(selectedLevel == level ? .white : .white)
//
//                                                    Text(level)
//                                                        .font(.title)
//                                                        .fontWeight(.black)
//                                                        .foregroundColor(.white)
//                                                }
//                                            }
//                                            .padding(.vertical, 8)
//                                        }
                    
                    
                }
                
                
            }
            
            
            Button(action: {
                
                //self.countries.removeAll { $0.name == "Åland" }
                
                multiplayer = true
                currentScene = "JoinMultiplayerPeerView"
                
                
                let filteredCountries = countries.filter { selectedContinents.contains($0.continent) }
                self.countries = filteredCountries
                self.socketManager.countries = filteredCountries

            }) {
                Text("DONE")
                    
            }
            .buttonStyle(OrdinaryButtonStyle())
            .padding()
        }
        .padding()
        .onAppear() {
            let uniqueContinents = Set(countries.map { $0.continent })
            continentList = Array(uniqueContinents)
            selectedContinents = continentList
            
        }
    }
}

