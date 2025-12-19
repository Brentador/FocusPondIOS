import Combine
import UIKit
import Foundation

enum TimerState {
    case idle
    case paused
    case running
}

final class TimerService : ObservableObject {
    static let shared = TimerService()
    @Published var remainingTime: Int64 = 30 * 60 * 1000
    @Published var activeDuration: Int64 = 0
    @Published var state: TimerState = .idle
    @Published var sessionCompleted: Bool = false
    
    private var timer: Timer?
    private let defaultDuration: Int64 = 30 * 60 * 1000
    
    private init(){}
 
    
    func startTimer(duration: Int64) {
        timer?.invalidate()
        sessionCompleted = false
            
        if state == .idle {
            activeDuration = duration
        }
            
        remainingTime = duration
        state = .running
            
        startTicking()
    }
    
    private func startTicking() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    
    func pauseTimer() {
        if (state == .running){
            timer?.invalidate()
            timer = nil
            state = .paused
        }
    }
    
    
    func resumeTimer() {
        if (state == .paused && remainingTime > 0){
            state = .running
            startTicking()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        remainingTime = 0
        activeDuration = 0
        sessionCompleted = false
        state = .idle  // Ensure state is set to idle
    }
    
    func resetSessionCompletion(){
        sessionCompleted = false
    }
    
    private func tick() {
        remainingTime -= 1000
        
        if remainingTime <= 0 {
            timer?.invalidate()
            timer = nil
            remainingTime = 0
            state = .idle
            sessionCompleted = true
        }
    }
    
}
