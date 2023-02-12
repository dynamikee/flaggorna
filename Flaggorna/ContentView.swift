
import SwiftUI
import Combine

struct ContentView: View {
    @State var currentScene = "Start"
    @State var countries: [Country] = []
    
    
    var body: some View {
        
        switch currentScene {
        case "Start":
            StartGameView(currentScene: $currentScene, countries: $countries)
        case "GetReady":
            GetReadyView(currentScene: $currentScene)
        case "Main":
            MainGameView(currentScene: $currentScene, countries: $countries)
        case "Right":
            RightAnswerView(currentScene: $currentScene)
        case "Wrong":
            WrongAnswerView(currentScene: $currentScene)
        case "GameOver":
            GameOverView(currentScene: $currentScene)
        default:
            StartGameView(currentScene: $currentScene, countries: $countries)
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
    //var loadData: () -> ()
    
    var body: some View {
        Button(action: {
            loadData()
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
        print(countries)
    }
    
}

struct GetReadyView: View {
    
    @Binding var currentScene: String
    
    var body: some View {
        Button(action: {
            currentScene = "Main"
        }){
            Text("Ok I am ready..")
        }
        .padding()
    }
    
}

struct MainGameView: View {
    @Binding var currentScene: String
    @Binding var countries: [Country]

    var body: some View {
        let randomCountry = countries.randomElement()!
        let currentCountry = randomCountry.name
        let countryAlternatives = countries.filter { $0.name != currentCountry }
        var randomCountryNames = countryAlternatives.map { $0.name }.shuffled().prefix(3)
        randomCountryNames.append(currentCountry)
        randomCountryNames.shuffle()

        return VStack {
            Image(randomCountry.flag)
            ForEach(randomCountryNames, id: \.self) { countryName in
                Button(action: {
                    if strcmp(currentCountry, countryName) == 0 {
                        self.currentScene = "Right"
                    } else {
                        self.currentScene = "Wrong"
                    }
                }) {
                    Text(countryName)
                }
            }
        }
    }
}

struct RightAnswerView: View {
    @Binding var currentScene: String

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
                    self.currentScene = "Main"
                }
            }
        }
    }
}





struct WrongAnswerView: View {
    
    @Binding var currentScene: String
    
    var body: some View {
        VStack {
            Spacer()
            Text("YOU ARE WRONG!")

            Spacer()
            
        }
        .onAppear {
            withAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.currentScene = "Main"
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


