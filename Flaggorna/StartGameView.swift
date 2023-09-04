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
    @Binding var selectedContinents: [String]
    
    @State private var offset = CGSize.zero
    @State private var isSettingsViewActive = false
    
    @State private var playButtonScale: CGFloat = 1.0
    
    @State private var continentList: [String] = []
    
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
                    
                    if countries.isEmpty {
                        FlagDataManager.loadDataAndUpdateFlagData() { countries in
                            self.countries = countries
                        }
                    }
                    if SocketManager.shared.countries.isEmpty {
                        SocketManager.shared.loadData()
                    }
                    let uniqueContinents = Set(countries.map { $0.continent })
                    continentList = Array(uniqueContinents)
                    selectedContinents = continentList
                    
                    
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
                
                FlagDataManager.loadDataAndUpdateFlagData() { countries in
                    self.countries = countries
                }
                let uniqueContinents = Set(countries.map { $0.continent })
                continentList = Array(uniqueContinents)
                selectedContinents = continentList
                
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
    
    //Fetching the flags for the statistics view from core data
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
        
    @State private var showFlagSelection = false
    @State private var isEditingName = false
    @State private var userName = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var editedName = ""
    
    let flagData: [FlagData]
    
    var sortedFlagData: [FlagData] {
        flagData.sorted { $0.country_name ?? "" < $1.country_name ?? "" }
    }
        

    @State private var selectedUserFlag: String
    
    init(flagData: [FlagData]) {
        self.flagData = flagData

        let storedUserFlag = UserDefaults.standard.string(forKey: "userFlag")
        if let storedFlag = storedUserFlag, !storedFlag.isEmpty {
            self._selectedUserFlag = State(initialValue: storedFlag)
        } else {
            let randomFlagIndex = Int.random(in: 0..<flagData.count)
            self._selectedUserFlag = State(initialValue: flagData[randomFlagIndex].flag ?? "sweden")
            UserDefaults.standard.setValue(selectedUserFlag, forKey: "userFlag")
        }
    }

    
    var body: some View {
        
        ScrollViewReader { scrollViewProxy in
        
            ZStack {
                Color(UIColor(red: 0.11, green: 0.11, blue: 0.15, alpha: 1.00))
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    if showFlagSelection {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(sortedFlagData, id: \.self) { data in
                                Button(action: {
                                    selectedUserFlag = data.flag ?? "sweden"
                                    UserDefaults.standard.setValue(selectedUserFlag, forKey: "userFlag")
                                    showFlagSelection = false

                                }) {
                                    Image(data.flag ?? "")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 64)
                                        .clipShape(Circle())
                                    //.border(sortedFlagData == data ? Color.blue : Color.clear, width: 2)
                                        .padding(.trailing, 8)
                                }
                            }
                        }
                        .padding()
                    } else {
                        
                        VStack{
                            Image(selectedUserFlag) // Replace with the actual image name
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 64, height: 64) // Set the desired width and height
                                .clipShape(Circle()) // Mask the image to a circle shape
                                .overlay(
                                    Circle()
                                        .stroke(Color(UIColor(red: 0.22, green: 0.22, blue: 0.25, alpha: 1.00)), lineWidth: 1) // Set the border color and width
                                )
                                .padding(.top, 32)
                                .onTapGesture {
                                    showFlagSelection = true // Set the flag selection mode to true
                                }
                                .id(0)
                                
                            
                                
                            
                            if isEditingName {
                                HStack {
                                    TextField("Enter your name", text: $editedName, onCommit: {
                                        if editedName.isEmpty {
                                            //
                                        } else {
                                            let truncatedName = String(editedName.prefix(20)) // Limit to first 12 characters
                                            userName = truncatedName
                                            isEditingName = false
                                            UserDefaults.standard.set(truncatedName, forKey: "userName")
                                        }
                                        
                                    })
                                    .font(.largeTitle)
                                    .fontWeight(.black)
                                    .padding(4)
                                    .background(Color(UIColor(red: 0.22, green: 0.22, blue: 0.25, alpha: 1.0)))
                                    .foregroundColor(.white)
                                    Image(systemName: "checkmark")
                                        .font(.title)
                                        .foregroundColor(Color.white)
                                        .onTapGesture {
                                            let truncatedName = String(editedName.prefix(20)) // Limit to first 12 characters
                                            userName = truncatedName
                                            isEditingName = false
                                            UserDefaults.standard.set(truncatedName, forKey: "userName")
                                            
                                            
                                        }
                                        .disabled(editedName.isEmpty)

                                    
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal)
    
                            } else {
                                HStack {
                                    Image(systemName: "pencil")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(UIColor(red: 0.11, green: 0.11, blue: 0.15, alpha: 1.00)))
                                    Text(userName)
                                        .font(.largeTitle)
                                        .fontWeight(.black)
                                        .multilineTextAlignment(.center)
                                        .onTapGesture {
                                            isEditingName = true // Activate editing mode
                                            editedName = userName // Initialize the editedName with the current name
                                            
                                            
                                        }
                                    Image(systemName: "pencil")
                                        .font(.title)
                                        .foregroundColor(Color.white)
                                        .onTapGesture {
                                            isEditingName = true // Activate editing mode
                                            editedName = userName // Initialize the editedName with the current name
                                        }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        
                        let showHighscore = UserDefaults.standard.string(forKey: "highScore") ?? "-"
                        
                        HStack {
                            VStack (spacing: 10) {
                                Text("BEST SCORE")
                                    .font(.headline)
                                HStack{
                                    Text(showHighscore)
                                        .font(.largeTitle)
                                        .fontWeight(.black)
                                }
                                .padding(.bottom)
                            }
                            .padding()
                            .frame(maxWidth: .infinity) // Equal width for both columns
                            .background(Color(UIColor(red: 0.22, green: 0.22, blue: 0.25, alpha: 0.8)))
                            
                            VStack (spacing: 10) {
                                Text("GAMES PLAYED")
                                    .font(.headline)
                                HStack{
                                    Text("\(flagData.first?.user_games_played ?? 0)")
                                        .font(.largeTitle)
                                        .fontWeight(.black)
                                }
                                .padding(.bottom)
                            }
                            .padding()
                            .frame(maxWidth: .infinity) // Equal width for both columns
                            .background(Color(UIColor(red: 0.22, green: 0.22, blue: 0.25, alpha: 0.8)))
                        }
                        .padding()
                        
                        
                        
                        
                        VStack(spacing: 32) {
                            VStack (spacing: 16) {
                                if let userAccuracy = flagData.first?.user_accuracy {
                                    let userAccuracyRightScale = userAccuracy * 100
                                    HStack {
                                        Text("ACCURACY: \(userAccuracyRightScale, specifier: "%.0f") %")
                                            .font(.headline)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    ProgressBar(value: Int(userAccuracyRightScale), color: .white)
                                        .frame(height: 20)
                                        .cornerRadius(8)
                                    
                                        .padding(.horizontal)
                                }
                            }
                            VStack (spacing: 16) {
                                if let userSpeed = flagData.first?.user_speed {
                                    let invertedSpeed = 100 - Int((userSpeed / 4) * 100) // Inverting the speed value
                                    
                                    HStack {
                                        Text("REACTION: \(userSpeed, specifier: "%.2f") seconds")
                                            .font(.headline)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    ProgressBar(value: Int(invertedSpeed), color: .white)
                                        .frame(height: 20)
                                        .cornerRadius(8)
                                    
                                        .padding(.horizontal)
                                }
                            }
                            VStack (spacing: 16) {
                                if let userConsistency = flagData.first?.user_consistency {
                                    let userConsistencyRightScale = userConsistency * 100
                                    HStack {
                                        Text("PERFORMANCE: \(userConsistencyRightScale, specifier: "%.0f") %")
                                            .font(.headline)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    ProgressBar(value: Int(userConsistencyRightScale), color: .white)
                                        .frame(height: 20)
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                }
                            }
                            
                        }.padding(.vertical)
                        
                        HStack {
                            Text("FLAG STATISTICS")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top)
                            Spacer()
                        }
                        
                        
                        VStack {
                            ForEach(sortedFlagData, id: \.self) { data in
                                HStack {
                                    Image(data.flag ?? "")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 64)
#if FLAGGORNA
                                        .border(Color(UIColor(red: 0.22, green: 0.22, blue: 0.25, alpha: 1.00)), width: 1)
#elseif TEAM_LOGO_QUIZ
                                    //
#endif
                                        .padding(.trailing, 8)
                                    Text(data.country_name ?? "")
                                        .font(.body)
                                    //.fontWeight(.bold)
                                    Spacer()
                                    Text("Correct: \(data.right_answers) of \(data.impressions)  ")
                                        .font(.footnote)
                                    IndicatorView(data: data)
                                    //.padding(8)
                                }
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
                    
                    
                }
                .preferredColorScheme(.dark)
                .onChange(of: showFlagSelection) { newValue in
                            if !newValue {
                                
                                scrollViewProxy.scrollTo(0)
                                
                            }
                        }

            }
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
                    .foregroundColor(Color(UIColor(red: 0.22, green: 0.22, blue: 0.25, alpha: 1.0)))

                Rectangle()
                    .frame(width: min(CGFloat(self.value) / 100 * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(self.color)
                    .animation(.linear)
            }
        }
    }
}

struct IndicatorView: View {
    let data: FlagData
    
    private let greenThreshold: Double = 0.75
    private let redThreshold: Double = 0.35
    
    var body: some View {
        let correctRatio = data.impressions > 0 ? Double(data.right_answers) / Double(data.impressions) : 0
        let color: Color
        
        if data.impressions == 0 {
            color = .gray
        } else if correctRatio >= greenThreshold {
            color = .green
        } else if correctRatio <= redThreshold {
            color = .red
        } else {
            color = .yellow
        }
        
        return Rectangle()
            .frame(width: 8, height: 42)
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

