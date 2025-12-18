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
        if let cachedOwnedFish = LocalDataCache.shared.getCachedOwnedFish(),
               let cachedImages = LocalDataCache.shared.getCachedFishImages() {
                let imageDict = Dictionary(uniqueKeysWithValues: cachedImages.map { ($0.id, $0) })
                print("Debug: Loading from cache - \(cachedOwnedFish.count) owned fish, \(cachedImages.count) images")
                self.ownedFish = cachedOwnedFish.compactMap { owned in
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
                
                // Load currency from cache
                if let cachedCurrency = LocalDataCache.shared.getCachedCurrency() {
                    self.currency = cachedCurrency.amount
                }
                
                if let cachedPondFish = LocalDataCache.shared.getCachedPondFish() {
                    self.pondFish = cachedPondFish.filter { pond in
                        FishData.fishList.contains { $0.id == pond.fish_id }
                    }.map { pond in
                        let masterFish = FishData.fishList.first { $0.id == pond.fish_id }!
                        let images = imageDict[pond.fish_id]
                        return Fish(
                            id: masterFish.id,
                            name: masterFish.name,
                            rarity: masterFish.rarity,
                            quantity: 1,
                            timeStudied: 0,
                            totalTimeNeeded: masterFish.totalTimeNeeded,
                            cost: masterFish.cost,
                            eggSprite: images?.egg_url,
                            frySprite: images?.fry_url,
                            adultSprite: images?.fish_url
                        )
                    }
                }
            } else {
                print("Debug: No cached data available")
            }
    }
    

    func addFishToInventory(fishId: Int) {
        APIService.shared.addOwnedFish(fishId: fishId) {  success in
            if success {
                CacheService.shared.manualFetchAndReload {}
            }
        }
    }
    

    func addStudyTime(fishId: Int, minutes: Int) {
        APIService.shared.addStudyTime(fishId: fishId, minutes: minutes) { success in
            if success {
                CacheService.shared.manualFetchAndReload {}
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
        APIService.shared.addFishToPond(fishId: fish.id) { success in
            if success {
                CacheService.shared.manualFetchAndReload {}
            }
        }
    }
    

    func addCurrency(amount: Int) {
        let newAmount = currency + amount
        APIService.shared.updateCurrency(amount: newAmount) { success in
            if success {
                CacheService.shared.manualFetchAndReload {}
            }
        }
    }
    
    func deductCurrency(amount: Int) -> Bool {
        guard currency >= amount else { return false }
        addCurrency(amount: -amount)
        return true
    }
    

    func resetFishProgress(fishId: Int) {
        APIService.shared.resetFishProgress(fishId: fishId) { success in
            if success {
                CacheService.shared.manualFetchAndReload {}
            }
        }
    }
}
