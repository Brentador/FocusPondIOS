import Foundation

struct OwnedFish: Codable, Identifiable {
    let fish_id: Int
    var quantity: Int
    var time_studied: Int
    var total_time_needed: Int
    
    var id: Int { fish_id }
}
