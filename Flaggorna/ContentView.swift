
import SwiftUI

struct ContentView: View {
    @State var currentScene = "Start"
    @State var countries: [Country] = []
    
    var body: some View {
        
        switch currentScene {
        case "Start":
            StartGameView(currentScene: $currentScene, loadData: loadData)
        case "GetReady":
            GetReadyView(currentScene: $currentScene)
        case "Main":
            MainGameView(currentScene: $currentScene)
        case "Right":
            RightAnswerView(currentScene: $currentScene)
        case "Wrong":
            WrongAnswerView(currentScene: $currentScene)
        case "GameOver":
            GameOverView(currentScene: $currentScene)
        default:
            StartGameView(currentScene: $currentScene, loadData: loadData)
        }
    }
    
    private func loadData() {
            let file = Bundle.main.path(forResource: "countries", ofType: "json")!
            let data = try! Data(contentsOf: URL(fileURLWithPath: file))
            let decoder = JSONDecoder()
            self.countries = try! decoder.decode([Country].self, from: data)
    }
    
}

struct Country: Codable, Hashable {
    var name: String
    var flag: String
}

struct StartGameView: View {
    
    @Binding var currentScene: String
    var loadData: () -> ()
    
    var body: some View {
        Button(action: {
            loadData()
            currentScene = "GetReady"
        }){
            Text("Start game")
        }
        .padding()
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


