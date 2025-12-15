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
    
    init(){
        setupObserver()
        fetchTimerState()
    }

    private func fetchTimerState() {
        APIService.shared.getTimerState { [weak self] timerState in
            guard let self = self, let timerState = timerState else { return }
            DispatchQueue.main.async {
                if timerState.is_running {
                    self.timerState = .running
                } else if timerState.was_abandoned {
                    self.showAbandonedTimerDialog = true
                    self.timerState = .idle
                    if let fish = FishManager.shared.selectedFish {
                        FishManager.shared.resetFishProgress(fishId: fish.id)
                    }
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
                if let self = self {
                    self.handleSessionCompletion()
                }
            }
            .store(in: &subscriptions)
    }
    
    func startTimer(){
        if timerState == .idle {
            timerService.startTimer(duration: Int64(selectedDuration) * 60 * 1000)
            timerState = .running
            let timerStateModel = TimerStateModel(id: 1, is_running: true, was_abandoned: false)
            APIService.shared.updateTimerState(timerStateModel) { _ in }
        }
    }
    
    func pauseTimer(){
        if(timerState == .running){
            timerService.pauseTimer()
            timerState = .paused
            let timerStateModel = TimerStateModel(id: 1, is_running: false, was_abandoned: false)
            APIService.shared.updateTimerState(timerStateModel) { _ in }
        }
    }
    
    func resumeTimer(){
        if(timerState == .paused){
            timerService.resumeTimer()
            timerState = .running
            let timerStateModel = TimerStateModel(id: 1, is_running: true, was_abandoned: false)
            APIService.shared.updateTimerState(timerStateModel) { _ in }
        }
    }
    
    func stopTimer(){
        timerService.stopTimer()
        timerState = .idle
        remainingTimeText = formatMillis(millis: Int64(selectedDuration) * 60 * 1000)
        sessionCompleted = false
        let timerStateModel = TimerStateModel(id: 1, is_running: false, was_abandoned: false)
        APIService.shared.updateTimerState(timerStateModel) { _ in }
    }
    
    func setDuration(_ minutes: Int) {
        guard timerState == .idle else { return }
        selectedDuration = minutes
        remainingTimeText = formatMillis(millis: Int64(minutes) * 60 * 1000)
    }
    
    private func handleSessionCompletion() {
            sessionCompleted = true
            fishWasFullyGrown = false
            timerService.resetSessionCompletion()
    }
    
    private func formatMillis(millis: Int64) -> String {
        let totalSeconds = millis / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
