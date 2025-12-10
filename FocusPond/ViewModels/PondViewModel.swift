import Foundation
import SwiftUI
import Combine

struct FishPosition: Identifiable {
    let id = UUID()
    let fish: Fish
    var targetX: CGFloat
    var targetY: CGFloat
    var animationDuration: TimeInterval
    var facingLeft: Bool = false
}

@MainActor
class PondViewModel: ObservableObject {
    @Published var fishPositions: [FishPosition] = []
    
    private var movementTasks: [Task<Void, Never>] = []

    func initializeFish(screenWidth: CGFloat, screenHeight: CGFloat, fishSize: CGFloat) {
        movementTasks.forEach { $0.cancel() }
        movementTasks.removeAll()
        fishPositions.removeAll()
        
        for fish in FishManager.shared.pondFish {
            var pos = FishPosition(
                fish: fish,
                targetX: CGFloat.random(in: 0...(screenWidth - fishSize)),
                targetY: CGFloat.random(in: 0...(screenHeight - fishSize)),
                animationDuration: TimeInterval.random(in: 3...5)
            )
            fishPositions.append(pos)
            
            let index = fishPositions.count - 1
            let task = startMovement(index: index, screenWidth: screenWidth, screenHeight: screenHeight, fishSize: fishSize)
            movementTasks.append(task)
        }
    }

    private func startMovement(index: Int, screenWidth: CGFloat, screenHeight: CGFloat, fishSize: CGFloat) -> Task<Void, Never> {
        return Task {
            while !Task.isCancelled {
                guard index < fishPositions.count else { break }
                let duration = fishPositions[index].animationDuration
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                updateTargetPosition(index: index, screenWidth: screenWidth, screenHeight: screenHeight, fishSize: fishSize)
            }
        }
    }

    func updateTargetPosition(index: Int, screenWidth: CGFloat, screenHeight: CGFloat, fishSize: CGFloat) {
        guard index < fishPositions.count else { return }
        var currentPos = fishPositions[index]
        
        let newTargetX = CGFloat.random(in: 0...(screenWidth - fishSize))
        let newTargetY = CGFloat.random(in: 0...(screenHeight - fishSize))
        let newDuration = TimeInterval.random(in: 3...5)
        
        currentPos.targetX = newTargetX
        currentPos.targetY = newTargetY
        currentPos.animationDuration = newDuration
        currentPos.facingLeft = newTargetX < currentPos.targetX
        
        fishPositions[index] = currentPos
    }

    deinit {
        movementTasks.forEach { $0.cancel() }
    }
}
