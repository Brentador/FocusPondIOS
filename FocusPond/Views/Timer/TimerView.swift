import SwiftUI
import Kingfisher

struct TimerView: View {
    @StateObject var timerViewModel = TimerViewModel()
    @ObservedObject var fishManager = FishManager.shared
    @State private var dropdownExpanded = false
    
    var body: some View {
        let selectedFish = fishManager.selectedFish

        VStack(spacing: 16) {
            Text(selectedFish?.name ?? "Select Fish")
                .font(.title)
                .bold()
            
            if let fish = selectedFish {
                VStack(spacing: 4) {
                    ProgressView(value: Float(fish.timeStudied) / Float(fish.totalTimeNeeded))
                        .frame(height: 8)
                        .padding(.horizontal, 32)
                    Text("\(fish.timeStudied) / \(fish.totalTimeNeeded) minutes")
                        .font(.body)
                    Text(fish.name)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if let fish = selectedFish {
                KFImage(fish.getCurrentImageURL())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .animation(.default, value: fish.timeStudied)
            } else {
                Image(systemName: "fish")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
            }
                        
                        Text(timerViewModel.remainingTimeText)
                            .font(.system(size: 40))
                            .bold()
                        
                        Slider(
                            value: Binding(
                                get: { Double(timerViewModel.selectedDuration) },
                                set: { timerViewModel.setDuration(Int($0)) }
                            ),
                            in: 5...120,
                            step: 5
                        )
                        .disabled(timerViewModel.timerState != .idle)
                        .padding(.horizontal, 32)
                        
                        HStack {
                            Button(action: {
                                switch timerViewModel.timerState {
                                case .idle: timerViewModel.startTimer()
                                case .running: timerViewModel.pauseTimer()
                                case .paused: timerViewModel.resumeTimer()
                                }
                            }) {
                                Text(timerViewModel.timerState.buttonTitle())
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .background(timerViewModel.timerState.buttonColor())
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            if timerViewModel.timerState == .paused {
                                Button(action: { timerViewModel.stopTimer() }) {
                                    Text("Stop")
                                        .frame(maxWidth: .infinity, minHeight: 50)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
            
            if timerViewModel.timerState == .idle {
                Menu {
                    ForEach(fishManager.ownedFish, id: \.id) { fish in
                        Button(fish.name) {
                            fishManager.selectFish(fish: fish)
                        }
                    }
                } label: {
                    Text(selectedFish?.name ?? "Inventory")
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                        }
                    }
                    .padding()
                    .alert(isPresented: $timerViewModel.sessionCompleted) {
                        Alert(
                            title: Text(timerViewModel.fishWasFullyGrown ? "Fish Fully Grown!" : "Session Complete!"),
                            message: Text(alertMessage()),
                            dismissButton: .default(Text("OK")) { }
                        )
                    }
                    .alert(isPresented: $timerViewModel.showAbandonedTimerDialog) {
                        Alert(
                            title: Text("Fish Died!"),
                            message: Text("You left the app during your focus session. Stay focused next time!"),
                            dismissButton: .default(Text("OK")) { }
                        )
                    }
                }
                .onAppear {
                    fishManager.loadData()
                }
    
    private func alertMessage() -> String {
            guard let fish = fishManager.selectedFish else { return "" }
            if timerViewModel.fishWasFullyGrown {
                return "Your fish is fully grown and added to your pond!\nYou earned 100 coins!"
            } else {
                return "Great job! Your fish grew a bit.\nProgress: \(fish.timeStudied)/\(fish.totalTimeNeeded) minutes\nKeep studying to fully grow your fish!"
            }
        }
    }

extension TimerViewModelState {
    func buttonTitle() -> String {
        switch self {
        case .idle: return "Start"
        case .running: return "Pause"
        case .paused: return "Resume"
        }
    }
    
    func buttonColor() -> Color {
        switch self {
        case .running: return Color.blue.opacity(0.8)
        default: return Color.green
        }
    }
}

extension Fish {
    func getGrowthStageName() -> String {
        switch growthStage {
        case 0: return "Egg Stage"
        case 1: return "Fry Stage"
        default: return "Adult Stage"
        }
    }
    
    func getCurrentImageURL() -> URL? {
        let urlString: String?
        switch growthStage {
        case 0: urlString = eggSprite
        case 1: urlString = frySprite
        default: urlString = adultSprite
        }
        if let urlString = urlString {
            return URL(string: urlString)
        }
        return nil
    }
}

