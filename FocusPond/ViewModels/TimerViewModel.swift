import SwiftUI
import Combine
import Foundation

enum TimerViewModelState {
    case idle
    case running
    case paused
}

class TimerViewModel: ObservableObject {
    @Published var timerState: TimerViewModelState = .idle
    @Published var selectedDuration: Int = 30
    @Published var remainingTimeText: String = "30:00"
    @Published var sessionCompleted: Bool = false
    @Published var fishWasFullyGrown: Bool = false
    @Published var showAbandonedTimerDialog: Bool = false
    
    private let timerService = TimerService.shared
    private var subscriptions = Set<AnyCancellable>()
    private var hasFetchedState = false
    
    func shouldFetchState() -> Bool {
        return !hasFetchedState
    }
    
    func markStateFetched() {
        hasFetchedState = true
    }
    
    init(){
        setupObserver()
    }

    func fetchTimerState() {
        APIService.shared.getTimerState { [weak self] timerState in
            guard let self = self, let timerState = timerState else { return }
            DispatchQueue.main.async {
                print("Debug: Fetched timer state - is_running: \(timerState.is_running), was_abandoned: \(timerState.was_abandoned)")  // Add for debugging
                if timerState.is_running != 0 {  // Treat non-zero as true
                    self.showAbandonedTimerDialog = true
                    self.timerState = .idle
                    if let fish = FishManager.shared.selectedFish {
                        FishManager.shared.resetFishProgress(fishId: fish.id)
                    }
                    let resetModel = TimerStateModel(id: 1, is_running: 0, was_abandoned: 0)  // Use 0 for false
                    APIService.shared.updateTimerState(resetModel) { _ in }
                } else if timerState.was_abandoned != 0 {  // Treat non-zero as true
                    self.showAbandonedTimerDialog = true
                    self.timerState = .idle
                    if let fish = FishManager.shared.selectedFish {
                        FishManager.shared.resetFishProgress(fishId: fish.id)
                    }
                    let resetModel = TimerStateModel(id: 1, is_running: 0, was_abandoned: 0)
                    APIService.shared.updateTimerState(resetModel) { _ in }
                } else {
                    self.timerState = .idle
                }
            }
        }
    }

    
    private func setupObserver() {
        timerService.$remainingTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] millis in
                if let self = self {
                    self.remainingTimeText = self.formatMillis(millis: millis)
                }
            }
            .store(in: &subscriptions)
        
        timerService.$state
            .receive(on: DispatchQueue.main)
            .sink {[weak self] state in
                if let self = self {
                    switch state {
                    case .idle: self.timerState = .idle
                    case .running: self.timerState = .running
                    case .paused: self.timerState = .paused
                    }
                }
            }
            .store(in: &subscriptions)
        
        timerService.$sessionCompleted
            .receive(on: DispatchQueue.main)
            .sink {[weak self] completed in
                if let self = self, completed {
                    self.handleSessionCompletion()
                }
            }
            .store(in: &subscriptions)
    }
    
    func startTimer(){
        if timerState == .idle {
            timerService.startTimer(duration: Int64(selectedDuration) * 60 * 1000)
            timerState = .running
            let timerStateModel = TimerStateModel(id: 1, is_running: 1, was_abandoned: 0)  // Use 1 for true
            APIService.shared.updateTimerState(timerStateModel) { _ in }
        }
    }
    
    func pauseTimer(){
        if(timerState == .running){
            timerService.pauseTimer()
            timerState = .paused
            let timerStateModel = TimerStateModel(id: 1, is_running: 0, was_abandoned: 0)  // Use 0 for false
            APIService.shared.updateTimerState(timerStateModel) { _ in }
        }
    }
    
    func resumeTimer(){
        if(timerState == .paused){
            timerService.resumeTimer()
            timerState = .running
            let timerStateModel = TimerStateModel(id: 1, is_running: 1, was_abandoned: 0)
            APIService.shared.updateTimerState(timerStateModel) { _ in }
        }
    }
    
    func stopTimer(){
        timerService.stopTimer()
        timerState = .idle
        remainingTimeText = formatMillis(millis: Int64(selectedDuration) * 60 * 1000)
        sessionCompleted = false
        let timerStateModel = TimerStateModel(id: 1, is_running: 0, was_abandoned: 0)
        APIService.shared.updateTimerState(timerStateModel) { _ in }
    }
    
    func setDuration(_ minutes: Int) {
        guard timerState == .idle else { return }
        selectedDuration = minutes
        remainingTimeText = formatMillis(millis: Int64(minutes) * 60 * 1000)
    }
    
    private func handleSessionCompletion() {
        guard let fish = FishManager.shared.selectedFish else { return }
        
        // Calculate minutes studied
        let minutesStudied = Int(timerService.activeDuration / 1000 / 60)
        
        // Add study time to the fish
        FishManager.shared.addStudyTime(fishId: fish.id, minutes: minutesStudied)
        
        // Check if fish is now fully grown
        let newTimeStudied = fish.timeStudied + minutesStudied
        if newTimeStudied >= fish.totalTimeNeeded {
            fishWasFullyGrown = true
            // Add fish to pond
            FishManager.shared.addFishToPond(fish: fish)
            // Give currency reward
            FishManager.shared.addCurrency(amount: 100)
            // Reset fish progress
            FishManager.shared.resetFishProgress(fishId: fish.id)
            // Clear the selected fish to show placeholder
            FishManager.shared.selectedFish = nil
        } else {
            fishWasFullyGrown = false
        }
        
        sessionCompleted = true
        timerService.resetSessionCompletion()
        
        // Update timer state to not running
        let timerStateModel = TimerStateModel(id: 1, is_running: 0, was_abandoned: 0)
        APIService.shared.updateTimerState(timerStateModel) { _ in }
    }
    
    private func formatMillis(millis: Int64) -> String {
        let totalSeconds = millis / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
