
import SwiftUI
import Combine

struct ContentView: View {
    @State var currentScene = "Start"
    @State var countries: [Country] = []
    @State var score = 0
    @State var rounds = 3
    
    var body: some View {
        
        switch currentScene {
        case "Start":
            StartGameView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds)
        case "GetReady":
            GetReadyView(currentScene: $currentScene)
        case "Main":
            MainGameView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds)
        case "Right":
            RightAnswerView(currentScene: $currentScene, rounds: $rounds)
        case "Wrong":
            WrongAnswerView(currentScene: $currentScene, rounds: $rounds)
        case "GameOver":
            GameOverView(currentScene: $currentScene)
        default:
            StartGameView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds)
        }
    }
}

struct Country: Codable, Hashable {
    var name: String
    var flag: String
}

struct StartGameView: View {
    
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int
    
    
    var body: some View {
        Button(action: {
            loadData()
            score = 0
            rounds = 3
            currentScene = "GetReady"
        }){
            Text("Start game")
        }
        .padding()
    }
    
    private func loadData() {
            let file = Bundle.main.path(forResource: "countries", ofType: "json")!
            let data = try! Data(contentsOf: URL(fileURLWithPath: file))
            let decoder = JSONDecoder()
            self.countries = try! decoder.decode([Country].self, from: data)
    }
    
}

struct GetReadyView: View {
    
    @Binding var currentScene: String
    @State private var count = 3
    
    var body: some View {
        VStack {
            Text("Get ready! \(count)")
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if self.count > 0 {
                    self.count -= 1
                } else {
                    timer.invalidate()
                    self.currentScene = "Main"
                }
            }
        }
    }
}



struct MainGameView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]
    @Binding var score: Int
    @Binding var rounds: Int

    var body: some View {
        let randomCountry = countries.randomElement()!
        let currentCountry = randomCountry.name
        let countryAlternatives = countries.filter { $0.name != currentCountry }
        var randomCountryNames = countryAlternatives.map { $0.name }.shuffled().prefix(3)
        randomCountryNames.append(currentCountry)
        randomCountryNames.shuffle()

        return VStack {
            Text("Score: \(score)")
            Text("Round: \(rounds)")
            Spacer()
            Image(randomCountry.flag)
                .border(.gray, width: 1)
            Spacer()
            ForEach(randomCountryNames, id: \.self) { countryName in
                Button(action: {
                    if strcmp(currentCountry, countryName) == 0 {
                        self.score += 1
                        if self.rounds > 0 {
                            self.rounds -= 1
                        }
                        self.currentScene = "Right"

                        
                    } else {
                        if self.rounds > 0 {
                            self.rounds -= 1
                        }
                        self.currentScene = "Wrong"
                        
                    }
                }) {
                    Text(countryName)
                }
                .buttonStyle(CountryButtonStyle())
            }
            
        }
    }
}

struct RightAnswerView: View {
    @Binding var currentScene: String
    @Binding var rounds: Int

    var body: some View {
        VStack {
            Spacer()
            Text("YOU ARE RIGHT!")
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                    .modifier(ParticlesModifier())
                    .offset(x: -100, y : -50)
                        
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .modifier(ParticlesModifier())
                    .offset(x: 60, y : 70)
            }
            Spacer()
            
        }
        .onAppear {
            withAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
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





struct WrongAnswerView: View {
    
    @Binding var currentScene: String
    @Binding var rounds: Int
    
    var body: some View {
        VStack {
            Spacer()
            Text("YOU ARE WRONG!")

            Spacer()
            
        }
        .onAppear {
            withAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
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


struct CountryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
            configuration.label
        
                .padding(15)
                .background(Color.gray)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 5)
                )
                .font(.largeTitle)
                .foregroundColor(.black)
                
        }
}


struct FireworkParticlesGeometryEffect : GeometryEffect {
    var time : Double
    var speed = Double.random(in: 20 ... 200)
    var direction = Double.random(in: -Double.pi ...  Double.pi)
    
    var animatableData: Double {
        get { time }
        set { time = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        let xTranslation = speed * cos(direction) * time
        let yTranslation = speed * sin(direction) * time
        let affineTranslation =  CGAffineTransform(translationX: xTranslation, y: yTranslation)
        return ProjectionTransform(affineTranslation)
    }
}

struct ParticlesModifier: ViewModifier {
    @State var time = 0.0
    @State var scale = 0.1
    let duration = 3.0
    
    func body(content: Content) -> some View {
        ZStack {
            ForEach(0..<80, id: \.self) { index in
                content
                    .hueRotation(Angle(degrees: time * 80))
                    .scaleEffect(scale)
                    .modifier(FireworkParticlesGeometryEffect(time: time))
                    .opacity(((duration-time) / duration))
            }
        }
        .onAppear {
            withAnimation (.easeOut(duration: duration)) {
                self.time = duration
                self.scale = 1.0
            }
        }
    }
}


