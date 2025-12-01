import Combine
import UIKit

enum TimerState {
    case idle
    case paused
    case running
    case completed
    case failed
}

final class TimerService : ObservableObject {
    @Published private(set) var remainingTime: TimeInterval = 0
    @Published private(set) var activeDuration: TimeInterval = 0
    @Published private(set) var sessionCompleted: Bool = false
    
    private var timer: Timer?
    private var isRunning: Bool = false
    private let tickInterval: TimeInterval = 0.1
 
    
    func startTimer(duration: TimeInterval) {
        timer?.invalidate()
        sessionCompleted = false
        
        if !isRunning && remainingTime == 0 {
            activeDuration = duration
        }
        
        remainingTime = duration
        isRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { _ in
            self.tick()
        }
        
    }
    
    func pauseTimer() {
        if (isRunning == true){
            timer?.invalidate()
            timer = nil
            isRunning = false
        } else { return }
    }
    
    
    func resumeTimer() {
        if (isRunning == false && remainingTime > 0){
            startTimer(duration: remainingTime)
        } else {
            return
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        remainingTime = 0
        activeDuration = 0
        sessionCompleted = false
    }
    
    func resetSessionCompletion(){
        
    }
    
    private func tick() {
        remainingTime -= tickInterval
        
        if remainingTime <= 0 {
            remainingTime = 0
            timer?.invalidate()
            timer = nil
            isRunning = false
            sessionCompleted = true
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
}
