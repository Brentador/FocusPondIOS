import Foundation
import Combine

class TimerViewModel: ObservableObject {
    @Published var timerState: TimerState = .idle
    @Published var selectedDuration: TimeInterval = 30 * 60
    
    private let timerService = TimerService()
    private var subscriptions = Set<AnyCancellable>()
    
    var remainingTime: TimeInterval {
        timerService.remainingTime
    }
    
    var activeDuration: TimeInterval {
        timerService.activeDuration
    }
    
    init() {
        
    }
    
    private func setupObserver() {
        timerService.$remainingTime
            .sink { value in
                self.objectWillChange.send()
            }
            .store(in: &subscriptions)
    }
    
    func startTimer(){
        if(timerState == .idle){
            timerService.startTimer(duration: selectedDuration)
            timerState = .paused
        }
    }
    
    func pauseTimer(){
        if(timerState == .running){
            timerService.pauseTimer()
            timerState = .paused
        }
    }
    
    func resumeTimer(){
        if(timerState == .paused){
            timerService.resumeTimer()
            timerState = .running
        }
    }
    
    func stopTimer(){
            timerService.stopTimer()
            timerState = .idle
    }
    
    func failTimer(){
        timerService.stopTimer()
        timerState = .failed
    }
    
    func setDuration(seconds: TimeInterval) {
        if(timerState == .idle){
            selectedDuration = seconds
        }
    }
    
    func formatTime() -> String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var isActive: Bool {
        if(timerState == .running){
            return timerState == .running
        } else {
            return timerState == .paused
        }
        
    }
}
