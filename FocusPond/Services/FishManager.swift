import Foundation
import Combine

class FishManager: ObservableObject {
    static let shared = FishManager()
    
    @Published var ownedFish: [Fish] = []
    @Published var pondFish: [Fish] = []
    @Published var selectedFish: Fish? = nil
    @Published var currency: Int = 0
    
    private init() {}
    

    @MainActor
    func loadData() {
        APIService.shared.getOwnedFish { [weak self] fishList in
            DispatchQueue.main.async {
                guard let self = self, let fishList = fishList else { return }
                
                self.ownedFish = fishList.compactMap { owned in
                    guard let masterFish = FishData.fishList.first(where: { $0.id == owned.fish_id }) else { return nil }
                    return Fish(
                        id: masterFish.id,
                        name: masterFish.name,
                        rarity: masterFish.rarity,
                        quantity: owned.quantity,
                        timeStudied: owned.time_studied,
                        totalTimeNeeded: masterFish.totalTimeNeeded,
                        cost: masterFish.cost,
                        eggSprite: masterFish.eggSprite,
                        frySprite: masterFish.frySprite,
                        adultSprite: masterFish.adultSprite
                    )
                }
            }
        }
    }
    

    func addFishToInventory(fishId: Int) {
        APIService.shared.addOwnedFish(fishId: fishId) { [weak self] success in
            if success {
                self?.loadData()
            }
        }
    }
    

    func addStudyTime(fishId: Int, minutes: Int) {
        APIService.shared.addStudyTime(fishId: fishId, minutes: minutes) { [weak self] success in
            if success {
                self?.loadData()
            }
        }
    }
    

    func selectFish(fish: Fish?) {
        selectedFish = fish
    }
    
    func clearSelection() {
        selectedFish = nil
    }
    

    func addFishToPond(fish: Fish) {
        APIService.shared.addFishToPond(fishId: fish.id) { [weak self] success in
            if success {
                self?.loadData() // Reload pond fish
            }
        }
    }
    

    func addCurrency(amount: Int) {
        let newAmount = currency + amount
        APIService.shared.updateCurrency(amount: newAmount) { [weak self] success in
            if success {
                DispatchQueue.main.async {
                    self?.currency = newAmount
                }
            }
        }
    }
    
    func deductCurrency(amount: Int) -> Bool {
        guard currency >= amount else { return false }
        addCurrency(amount: -amount)
        return true
    }
    

    func resetFishProgress(fishId: Int) {
        APIService.shared.resetFishProgress(fishId: fishId) { [weak self] success in
            if success {
                self?.loadData()
            }
        }
    }
}
