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
    //let continentList = ["Africa", "Asia", "Europe", "North_America", "Oceania", "South_America"]

    struct ContinentInfo {
        let name: String  // Internal name with underscores
        let displayName: String  // Display name with spaces
    }

    enum Continents {
        static let list: [ContinentInfo] = [
            ContinentInfo(name: "Africa", displayName: "Africa"),
            ContinentInfo(name: "Asia", displayName: "Asia"),
            ContinentInfo(name: "Europe", displayName: "Europe"),
            ContinentInfo(name: "North_America", displayName: "North America"),
            ContinentInfo(name: "Oceania", displayName: "Oceania"),
            ContinentInfo(name: "South_America", displayName: "South America")
        ]
    }

    
    
    var body: some View {
        VStack {
            Text("Choose continent")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            ScrollView {
                VStack (alignment: .leading) {
                    ForEach(Continents.list, id: \.name) { continent in
                        Button(action: {
                            if selectedContinents.contains(continent.name) {
                                selectedContinents.removeAll(where: { $0 == continent.name })
                            } else {
                                selectedContinents.append(continent.name)
                            }
                        }) {
                            HStack {
                                Image(systemName: selectedContinents.contains(continent.name) ? "checkmark.square.fill" : "square")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(selectedContinents.contains(continent.name) ? .white : .white)
                                    .fontWeight(.bold)
                                
                                Text(continent.displayName)
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
                
                if !selectedContinents.isEmpty {
                    multiplayer = true
                    currentScene = "JoinMultiplayerPeerView"
                    
                    
                    let filteredCountries = countries.filter { selectedContinents.contains($0.continent) }
                    self.countries = filteredCountries
                    self.socketManager.selectedContinents = selectedContinents
                    self.socketManager.countries = filteredCountries
                } else {
                    return
                }
                
                

            }) {
                Text("DONE")
                    
            }
            .buttonStyle(OrdinaryButtonStyle())
            .padding()
        }
        .padding()
        .onAppear() {

            //selectedContinents = continentList
            
        }
    }
}

