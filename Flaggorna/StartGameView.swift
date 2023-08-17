//
//  StartGameView.swift
//  Flaggorna
//
//  Created by Mikael Mattsson on 2023-02-18.
//

import SwiftUI
import CoreData
import UIKit

struct StartGameView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int
    @Binding var multiplayer: Bool
    @Binding var numberOfRounds: Int
    @Binding var roundsArray: [RoundStatus]
    
    @State private var offset = CGSize.zero
    @State private var isSettingsViewActive = false
    
    @State private var playButtonScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color(UIColor(red: 0.11, green: 0.11, blue: 0.15, alpha: 1.00))
                .edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    
                        #if FLAGGORNA
                    Button(action: {
                        let appURL = URL(string: "https://apple.co/3LfGM7G")!
                            let appName = "Flag Party Quiz App - Flaggorna"
                            let appIcon = UIImage(named: "AppIcon")! // Replace "AppIcon" with the name of your app icon image asset
                            
                            let activityViewController = UIActivityViewController(activityItems: [appIcon, "I challenge you on a flag quiz! Download the app to get started", appURL], applicationActivities: nil)
                            UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
                        
                    }) {
                            Image(systemName: "square.and.arrow.up")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                            
                        }
                        .buttonStyle(OrdinaryButtonStyle())
                        .padding()
                        #elseif TEAM_LOGO_QUIZ
//                        let appURL = URL(string: "https://apple.co/3LfGM7G")!
//                            let appName = "Soccer Team Logo Quiz App"
//                            let appIcon = UIImage(named: "AppIcon 2")! // Replace "AppIcon" with the name of your app icon image asset
//
//                            let activityViewController = UIActivityViewController(activityItems: [appIcon, "I challenge you on a soccer team-logo quiz! Download the app to get started", appURL], applicationActivities: nil)
//                            UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
                        
                        #endif
                        

                    Spacer()
                    Button(action: {
                        isSettingsViewActive = true
                        
                    }){
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                        
                    }
                    .buttonStyle(OrdinaryButtonStyle())
                    .padding()
                    .sheet(isPresented: $isSettingsViewActive) {
                        FlagStatisticsView(flagData: fetchFlagData())
                    }
                    
                    
                }
                
                Spacer()
                Spacer()
                
                Button(action: {
                    score = 0
                    rounds = numberOfRounds
                    multiplayer = true
                    SocketManager.shared.currentScene = "JoinMultiplayerPeer"
                    
                }){
                    VStack {
                        Image("party_quiz_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 300)
                            .foregroundColor(.white)
                        
                        Image("play_button")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 140)
                            .scaleEffect(playButtonScale)
                            .animation(.spring())
                            .padding(8)
                    }
                    
                    
                }
                
                Spacer()
                Spacer()
                
                //            Button(action: {
                //                loadData()
                //                score = 0
                //                rounds = numberOfRounds
                //                self.roundsArray = Array(repeating: .notAnswered, count: numberOfRounds)
                //                currentScene = "GetReady"
                //            }){
                //                Text("SINGLE PLAYER")
                //            }
                //            .buttonStyle(OrdinaryButtonStyle())
                //            .padding()
                
                Spacer()
                
            }
            
            .background(
                FlagBackgroundView()
                    .frame(
                        width: UIScreen.main.bounds.width + 2 * abs(offset.width),
                        height: UIScreen.main.bounds.height + 2 * abs(offset.height)
                    )
                    .offset(x: offset.width, y: offset.height)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: 10)
                                .repeatForever(autoreverses: true)
                        ) {
                            self.offset.height = -200
                            self.offset.width = UIScreen.main.bounds.width / 2
                        }
                    }
            )
            
            //.edgesIgnoringSafeArea(.all)
            .onAppear {
                SocketManager.shared.loadData()
                animatePlayButton()
            }
        }
    }
    
    private func animatePlayButton() {
        withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 100, damping: 10, initialVelocity: 0)) {
            playButtonScale = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 100, damping: 10, initialVelocity: 0)) {
                playButtonScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                animatePlayButton() // Recursively call the function to create a loop
            }
        }
    }
    
    
    
    private func loadData() {
        #if FLAGGORNA
        let file = Bundle.main.path(forResource: "countries", ofType: "json")!
        #elseif TEAM_LOGO_QUIZ
        let file = Bundle.main.path(forResource: "teams", ofType: "json")!
        #endif
        
        let data = try! Data(contentsOf: URL(fileURLWithPath: file))
        let decoder = JSONDecoder()
        self.countries = try! decoder.decode([Country].self, from: data)
        
        // Update Core Data with flag data
        updateFlagData()
    }
    
    private func updateFlagData() {
        let managedObjectContext = PersistenceController.shared.container.viewContext
        
        // Fetch existing flag data
        let fetchRequest: NSFetchRequest<FlagData> = FlagData.fetchRequest()
        var existingFlagData: [FlagData] = []
        
        do {
            existingFlagData = try managedObjectContext.fetch(fetchRequest)
        } catch {
            // Handle Core Data fetch error
            print("Error fetching flag data: \(error)")
        }
        
        // Create a dictionary of existing flag data by country name
        var existingFlagDataDict: [String: FlagData] = [:]
        for flagData in existingFlagData {
            if let countryName = flagData.country_name {
                existingFlagDataDict[countryName] = flagData
            }
        }
        
        // Update or create flag data for each country
        for country in countries {
            if let existingFlagData = existingFlagDataDict[country.name] {
                // Update existing flag data
                existingFlagData.flag = country.flag
                
            } else {
                // Create new flag data
                let flagData = FlagData(context: managedObjectContext)
                flagData.country_name = country.name
                flagData.flag = country.flag
                flagData.impressions = 0
                flagData.right_answers = 0
            }
        }
        
        // Save the changes to Core Data
        do {
            try managedObjectContext.save()
        } catch {
            // Handle Core Data saving error
            print("Error saving flag entities: \(error)")
        }
    }
    
    private func fetchFlagData() -> [FlagData] {
        let managedObjectContext = PersistenceController.shared.container.viewContext
        
        let fetchRequest: NSFetchRequest<FlagData> = FlagData.fetchRequest()
        
        do {
            let flagData = try managedObjectContext.fetch(fetchRequest)
            return flagData
        } catch {
            // Handle Core Data fetch error
            print("Error fetching flag data: \(error)")
            return []
        }
    }
}

struct FlagStatisticsView: View {
    
    let flagData: [FlagData]
    
    var sortedFlagData: [FlagData] {
        flagData.sorted { $0.country_name ?? "" < $1.country_name ?? "" }
    }
    
    let userName = UserDefaults.standard.string(forKey: "userName") ?? "Not played yet"

    
    var body: some View {
        ZStack {
            Color(UIColor(red: 0.11, green: 0.11, blue: 0.15, alpha: 1.00))
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                
                Text(userName)
                    .font(.largeTitle)
                    .fontWeight(.black)
                                        .padding()
                                        .padding(.top, 32)
                
                Text("FLAG NERD SCORE")
                                        .font(.headline)
                                        .fontWeight(.black)
                                        .padding()
                
                if let userAccuracy = flagData.first?.user_accuracy {
                    HStack {
                        Text("Accuracy: \(userAccuracy, specifier: "%.2f")")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    ProgressBar(value: Int(userAccuracy), color: .green)
                        .frame(height: 20)
                        .padding()
                }

                if let userSpeed = flagData.first?.user_speed {
                    let invertedSpeed = 100 - Int((userSpeed / 4) * 100) // Inverting the speed value
                    
                    HStack {
                        Text("Reaction: \(userSpeed, specifier: "%.2f") seconds")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    ProgressBar(value: Int(invertedSpeed), color: .blue)
                        .frame(height: 20)
                        .padding()
                }
                
                if let userConsistency = flagData.first?.user_consistency {
                    let procentConsistency = userConsistency * 100
                    HStack {
                        Text("Consistency: \(procentConsistency, specifier: "%.2f")")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    ProgressBar(value: Int(procentConsistency), color: .red)
                        .frame(height: 20)
                        .padding()
                }
                
                Text("FLAG STATISTICS")
                    .font(.headline)
                    .fontWeight(.black)
                    .padding(.top, 24)
                
                VStack {
                    ForEach(sortedFlagData, id: \.self) { data in
                        HStack {
                            Image(data.flag ?? "")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 64)
                            #if FLAGGORNA
                                .border(Color.gray, width: 1)
                            #elseif TEAM_LOGO_QUIZ
                            //
                            #endif
                                .padding(.trailing, 8)
                            Text(data.country_name ?? "")
                                .font(.body)
                                .fontWeight(.bold)
                            Spacer()
                            Text("Correct: \(data.right_answers) of \(data.impressions)")
                                .font(.footnote)
                            CircleIndicatorView(data: data)
                                .padding(8)
                        }
                        .padding(4)
                    }
                    
                    VStack {
                        Button(action: {
                            // Open Terms of Use (EULA)
                            openTermsOfUse()
                        }) {
                            Text("Terms of Use")
                        }
                        .buttonStyle(LowKeyButtonStyle())
                        .padding(24)
                        
                        Button(action: {
                            // Open Privacy Policy
                            openPrivacyPolicy()
                        }) {
                            Text("Privacy Policy")
                        }
                        .buttonStyle(LowKeyButtonStyle())
                        .padding(24)
                    }
                    .padding(24)
                    
                }
                .padding()
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private func openTermsOfUse() {
        guard let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") else {
            return // Invalid URL, handle the error gracefully
        }
        
        let options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:]
        
        UIApplication.shared.open(termsOfUseURL, options: options) { success in
            if !success {
                // Failed to open the Terms of Use document, handle the error gracefully
            }
        }
    }
    
    private func openPrivacyPolicy() {
        guard let termsOfUseURL = URL(string: "https://bangahantverk.com/pages/flag-party-quiz-privacy-policy") else {
            return // Invalid URL, handle the error gracefully
        }
        
        let options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:]
        
        UIApplication.shared.open(termsOfUseURL, options: options) { success in
            if !success {
                // Failed to open the Terms of Use document, handle the error gracefully
            }
        }
    }
    
}


struct ProgressBar: View {
    var value: Int
    var color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)

                Rectangle()
                    .frame(width: min(CGFloat(self.value) / 100 * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(self.color)
                    .animation(.linear)
            }
        }
    }
}

struct CircleIndicatorView: View {
    let data: FlagData
    
    private let greenThreshold: Double = 0.75
    private let redThreshold: Double = 0.35
    
    var body: some View {
        let correctRatio = data.impressions > 0 ? Double(data.right_answers) / Double(data.impressions) : 0
        let symbolName: String
        let color: Color
        
        if data.impressions == 0 {
            symbolName = "circle.dotted"
            color = .gray
        } else if correctRatio >= greenThreshold {
            symbolName = "circle.fill"
            color = .green
        } else if correctRatio <= redThreshold {
            symbolName = "circle.slash"
            color = .red
        } else {
            symbolName = "circle.bottomhalf.filled"
            color = .yellow
        }
        
        return Image(systemName: symbolName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
            .foregroundColor(color)
    }
}


struct FlagBackgroundView: View {
    let columns = 6
    let rows = 20
    #if FLAGGORNA
    let flagImageNames = [
        "afghanistan", "aland", "albania", "algeria", "american_samoa", "andorra", "angola", "anguilla",
        "antarctica", "antilles", "argentina", "armenia", "aruba", "australia", "austria", "azerbaijan",
        "bahamas", "bahrain", "bangladesh", "barbados", "barbuda_antigua", "belgium", "belize", "benin",
        "bermuda", "bhutan", "bolivia", "bonaire", "bosnia_herzegovina", "botswana", "brazil", "british_indian_ocean",
        "british_virgin_islands", "brunei", "bulgaria", "burkina_faso", "burundi", "cabo_verde", "cambodia",
        "cameroon", "canada", "catalonia", "cayman_islands", "central_africa", "chad", "chile", "china",
        "christmas_islands", "colombia", "comoros", "congo",
        "cook_islands",
        "costa_rica",
        "croatia",
        "cuba",
        "curacao",
        "cyprus",
        "czech_republic",
        "democratic_congo",
        "denmark",
        "djibouti",
        "dominica",
        "dominican_republic",
        "dubai",
        "east_timor",
        "ecuador",
        "egypt",
        "el_salvador",
        "england",
        "equatorial_guinea",
        "eritrea",
        "estonia",
        "eswatini",
        "ethiopia",
        "european_union",
        "falkland_islands",
        "faroe_islands",
        "fiji",
        "finland",
        "france",
        "french_guiana",
        "gabon",
        "gambia",
        "georgia",
        "germany",
        "ghana",
        "gibraltar",
        "great_britain",
        "greece",
        "greenland",
        "grenada",
        "guadeloupe",
        "guam",
        "guatemala",
        "guernsey",
        "guinea_bissau",
        "guinea",
        "guyana",
        "haiti",
        "honduras",
        "hong_kong",
        "hungary",
        "iceland",
        "india",
        "indonesia",
        "iran",
        "iraq",
        "ireland",
        "isle_of_man",
        "israel",
        "italy",
        "ivoire_coast",
        "jamaica",
        "japan",
        "jersey",
        "jordan",
        "kashmir",
        "kazakhstan",
        "kenya",
        "kiribati",
        "kosovo",
        "kurdistan",
        "kuwait",
        "kyrgyz_republic",
        "laos",
        "latvia",
        "lebanon",
        "lesotho",
        "liberia",
        "libya",
        "liechtenstein",
        "lithuania",
        "luxembourg",
        "macao",
        "macedonia",
        "madagascar",
        "malawi",
        "malaysia",
        "maldives",
        "mali",
        "malta",
        "marshall_islands",
        "martinique",
        "mauritania",
        "mauritius",
        "mexico",
        "micronesia",
        "moldova",
        "monaco",
        "mongolia",
        "montenegro",
        "montserrat",
        "morocco",
        "mozambique",
        "myanmar",
        "namibia",
        "nauru",
        "nepal",
        "netherlands",
        "new_caledonia",
        "new_zealand",
        "nicaragua",
        "niger",
        "nigeria",
        "niue",
        "north_korea",
        "northern_ireland",
        "northern_mariana_islands",
        "norway",
        "oman",
        "pakistan",
        "palau",
        "palestine",
        "panama",
        "papua_new_guinea",
        "paraguay",
        "peru",
        "philippines",
        "pitcairn",
        "poland",
        "portugal",
        "puerto_rico",
        "qatar",
        "reunion",
        "romania",
        "rwanda",
        "saarc",
        "saint_helena",
        "saint_lucia",
        "saint_martin",
        "samoa",
        "san_marino",
        "sao_tome_principe",
        "saudi_arabia",
        "scotland",
        "senegal",
        "serbia",
        "seychelles",
        "sierra_leone",
        "singapore",
        "slovakia",
        "slovenia",
        "solomon_islands",
        "somalia",
        "south_africa",
        "south_korea",
        "south_sudan",
        "spain",
        "sri_lanka",
        "st_kitts_and_nevis",
        "st_vincent_grenadines",
        "sudan",
        "suriname",
        "sweden",
        "switzerland",
        "syria",
        "tahiti",
        "taiwan",
        "tajikistan",
        "tamil_eelam",
        "tanzania",
        "thailand",
        "togo",
        "tonga",
        "treaty_antarctica",
        "trinidad_tobago",
        "tunisia",
        "turkey",
        "turkmenistan",
        "uae",
        "uganda",
        "ukraine",
        "uruguay",
        "usa",
        "uzbekistan",
        "vanuatu",
        "vatican_city",
        "venezuela",
        "vietnam",
        "virgin_islands_us",
        "wales",
        "western_sahara",
        "yemen",
        "zambia",
        "zanzibar",
        "zimbabwe"
    ]
    #elseif TEAM_LOGO_QUIZ
    let flagImageNames = [
        "ACM", "AJA", "AJACCIO", "ALM", "ALV", "AMA", "ANGERS", "ARM", "ARS",
        "ATA", "AUG", "AUXERRE", "AVL", "BAY", "BEN", "BES", "BHA",
        "BIL", "BOC", "BOLOGNA", "BOU", "BRE", "BRESTOIS", "BRU", "BUR", "CAD",
        "CEL", "CEV", "CHE", "CAGLIARI", "CRY", "DAR", "CLERMONT", "DKI", "DROIT", "DOR", "ELC", "ESP", "EMPOLI", "ESTAC",
        "EVE", "FCB", "FCK", "FLORENTINA", "FROSINONE", "FRE", "FUL",
        "GENOA", "GET", "GIR", "GRA", "GRE", "HELLAS_VERONA", "HEI", "HER", "HOF", "INT",
        "JUV", "KOL", "LAP", "LAZIO", "LECCE", "LEE",
        "LEI", "LENS", "LEV", "LIL", "LIV", "LORIENT", "LUT", "LYO", "MAI", "MAL", "MAR",
        "MCI", "MFF", "MHA", "MONACO", "MONTPELLIER", "MON", "MONZA", "MUN", "NANTES", "NAP",
        "NEW", "NIC", "NOF", "NOR", "OSA", "PLZ", "POR", "PSG",
        "RAN", "RAY", "RBE", "RBL", "RBS", "REIMS", "REN",
        "RMA", "ROM", "RSO", "RVA", "SALERNITANA", "SAMPDORIA", "SASSUOLO", "SCH", "SEV", "SHA", "SHE", "SHU",
        "SOU", "SPO", "STRASBOURG", "STU", "TORINO", "TOT", "TOULOUSE", "UDINESE",
        "UNI", "VAL", "VENEZIA", "VIL", "WAT", "WBU", "WER", "WHU", "WOL",
        "YOU", "ZAG", "ZEN"
      ]
    #endif
    
    @State private var randomFlagIndices: [Int] = []
    
    var body: some View {
        VStack {
            LazyVGrid(columns: createGridItems(), spacing: 10) {
                ForEach(randomFlagIndices, id: \.self) { index in
                        Image(flagImageNames[index])
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 100) // Adjust the height as needed
                }
            }
        }
        .frame(width: UIScreen.main.bounds.width*2)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            randomFlagIndices = (0..<flagImageNames.count).shuffled()
        }
        
    }
    
    private func createGridItems() -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: columns)
    }
}

