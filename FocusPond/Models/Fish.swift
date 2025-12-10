import Foundation

enum Rarity: String, Codable {
    case common
    case rare
    case epic
    case legendary
}

struct Fish: Identifiable, Codable {
    let id: Int
    let name: String
    let rarity: Rarity
    var quantity: Int = 0
    var timeStudied: Int = 0
    let totalTimeNeeded: Int
    let cost: Int
    
    let eggSprite: String
    let frySprite: String
    let adultSprite: String
    
    var growthPercentage: Float {
        guard totalTimeNeeded > 0 else { return 0 }
        return (Float(timeStudied) / Float(totalTimeNeeded)) * 100
    }
    
    var growthStage: Int {
        let progress = growthPercentage
        switch progress {
        case 67...:
            return 2
        case 34..<67:
            return 1
        default:
            return 0
        }
    }
    
    var isFullyGrown: Bool {
        return timeStudied >= totalTimeNeeded
    }
}
