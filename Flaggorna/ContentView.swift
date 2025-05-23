
import SwiftUI
import Starscream
import CoreData

struct ContentView: View {
    @State var currentScene = "Start"
    @State var countries: [Country] = []
    @State var score = 0
    @State var rounds = 0
    @State var multiplayer: Bool = false
    @State var currentCountry: String = ""
    
    @State var numberOfRounds = 10 //Number of rounds in a game - could be set by a user later
    @State var roundsArray: [RoundStatus] = []
    @State var selectedContinents: [String] = []

    @EnvironmentObject var socketManager: SocketManager

    var body: some View {
        ZStack {
            Color(UIColor(red: 0.11, green: 0.11, blue: 0.15, alpha: 1.00))
                    .edgesIgnoringSafeArea(.all)
            
            if multiplayer {
                switch SocketManager.shared.currentScene {
                case "JoinMultiplayerPeer":
                    JoinMultiplayerPeerView(currentScene: $currentScene, countries: $countries, rounds: $rounds, multiplayer: $multiplayer, numberOfRounds: $numberOfRounds, roundsArray: $roundsArray, selectedContinents: $selectedContinents)
                case "GetReadyMultiplayer":
                    GetReadyMultiplayerView(currentScene: $currentScene, rounds: $rounds, numberOfRounds: $numberOfRounds)
                case "MainMultiplayer":
                    MainGameMultiplayerView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds)
                case "RightMultiplayer":
                    RightAnswerMultiplayerView(currentScene: $currentScene, score: $score, rounds: $rounds, numberOfRounds: $numberOfRounds, countries: $countries, selectedContinents: $selectedContinents)
                case "WrongMultiplayer":
                    WrongAnswerMultiplayerView(currentScene: $currentScene, rounds: $rounds, numberOfRounds: $numberOfRounds, countries: $countries, selectedContinents: $selectedContinents)
                case "GameOverMultiplayer":
                    GameOverMultiplayerView(currentScene: $currentScene, score: $score, rounds: $rounds, multiplayer: $multiplayer, selectedContinents: $selectedContinents)
                default:
                    JoinMultiplayerPeerView(currentScene: $currentScene, countries: $countries, rounds: $rounds, multiplayer: $multiplayer, numberOfRounds: $numberOfRounds, roundsArray: $roundsArray, selectedContinents: $selectedContinents)
                }
                
                
            } else {
                switch currentScene {
                case "Start":
                    StartGameView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds, multiplayer: $multiplayer, numberOfRounds: $numberOfRounds, roundsArray: $roundsArray, selectedContinents: $selectedContinents)
                case "GameModeView":
                    GameModeView(currentScene: $currentScene, countries: $countries, multiplayer: $multiplayer, selectedContinents: $selectedContinents)
                case "GetReady":
                    GetReadyView(currentScene: $currentScene)
                case "Main":
                    MainGameView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds, currentCountry: $currentCountry, roundsArray: $roundsArray)
                case "Right":
                    RightAnswerView(currentScene: $currentScene, score: $score, rounds: $rounds, roundsArray: $roundsArray)
                case "Wrong":
                    WrongAnswerView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds, currentCountry: $currentCountry, numberOfRounds: $numberOfRounds, roundsArray: $roundsArray, selectedContinents: $selectedContinents)
                case "GameOver":
                    GameOverView(currentScene: $currentScene, score: $score, rounds: $rounds, countries: $countries, numberOfRounds: $numberOfRounds, roundsArray: $roundsArray, selectedContinents: $selectedContinents)
                default:
                    StartGameView(currentScene: $currentScene, countries: $countries, score: $score, rounds: $rounds, multiplayer: $multiplayer, numberOfRounds: $numberOfRounds, roundsArray: $roundsArray, selectedContinents: $selectedContinents)
                }
            }
        }
    }
}

struct Round {
    var status: RoundStatus = .notAnswered
    var timeTaken: TimeInterval = 0
}

enum RoundStatus {
    case notAnswered
    case correct
    case incorrect
}
    
struct FlagQuestion: Codable {
    let flag: String
    let answerOptions: [String]
    let correctAnswer: String

    init(flag: String, answerOptions: [String], correctAnswer: String) {
        self.flag = flag
        var shuffledAnswerOptions = answerOptions
        shuffledAnswerOptions.shuffle()
        self.answerOptions = shuffledAnswerOptions
        self.correctAnswer = correctAnswer
    }
}

struct StartMessage: Codable {
    let type: String
    let gameCode: String
    let question: FlagQuestion
    let selectedContinents: [String]
}

struct ResetMessage: Codable {
    let type: String
    let gameCode: String
    
}

struct Country: Codable, Hashable {
    var name: String
    var flag: String
    var level: String
    var continent: String
}

class User: ObservableObject, Hashable, Identifiable {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    @Published var id: UUID
    @Published var name: String
    @Published var color: Color
    @Published var flag: String
    @Published var score: Int
    @Published var currentRound: Int
    
    init(id: UUID = UUID(), name: String, color: Color, flag: String = "", score: Int = 0, currentRound: Int = 0, wifiName: String = "") {
        self.id = id
        self.name = name
        self.color = color
        self.flag = flag
        self.score = score
        self.currentRound = currentRound
    }
}

//Calculates scores based on how much time it takes to answer them
func calculateScore(timeTaken: TimeInterval) -> Int {
    let maxScore = 10
    let minScore = 1
    let maxTime = 4.0
    let minTime = 0.0
    
    if timeTaken <= minTime {
        return maxScore
    } else if timeTaken >= maxTime {
        return minScore
    } else {
        let slope = Double(minScore - maxScore) / (maxTime - minTime)
        let intercept = Double(maxScore) - slope * minTime
        let score = Int(slope * timeTaken + intercept)
        return max(min(score, maxScore), minScore)
    }
}




