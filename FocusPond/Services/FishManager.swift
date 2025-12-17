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
            guard let self = self, let fishList = fishList else {
                print("Debug: getOwnedFish failed or returned nil")
                return
            }
            print("Debug: getOwnedFish returned \(fishList.count) fish")
            APIService.shared.getFishImages { imageList in
                DispatchQueue.main.async {
                    let imageDict = Dictionary(uniqueKeysWithValues: (imageList ?? []).map { ($0.id, $0) })
                    print("Debug: getFishImages returned \(imageList?.count ?? 0) images")
                    self.ownedFish = fishList.compactMap { owned in
                        guard let masterFish = FishData.fishList.first(where: { $0.id == owned.fish_id }) else {
                            print("Debug: No master fish found for id \(owned.fish_id)")
                            return nil
                        }
                        let images = imageDict[owned.fish_id]
                        print("Debug: Creating fish \(owned.fish_id) with images: \(images != nil)")
                        return Fish(
                            id: masterFish.id,
                            name: masterFish.name,
                            rarity: masterFish.rarity,
                            quantity: owned.quantity,
                            timeStudied: owned.time_studied,
                            totalTimeNeeded: masterFish.totalTimeNeeded,
                            cost: masterFish.cost,
                            eggSprite: images?.egg_url,
                            frySprite: images?.fry_url,
                            adultSprite: images?.fish_url
                        )
                    }
                    print("Debug: ownedFish now has \(self.ownedFish.count) fish")
                    if let selected = self.selectedFish, let updatedFish = self.ownedFish.first(where: { $0.id == selected.id }) {
                                        self.selectedFish = updatedFish
                    }
                    
                    // Load currency
                    APIService.shared.getCurrency { amount in
                        if let amount = amount {
                            DispatchQueue.main.async {
                                self.currency = amount
                            }
                        }
                    }
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
