import Foundation

class LocalDataCache {
    static let shared = LocalDataCache()
    
    private let ownedFishKey = "cached_owned_fish"
    private let pondFishKey = "cached_pond_fish"
    private let currencyKey = "cached_currency"
    private let fishImagesKey = "cached_fish_images"
    
    private let ownedFishTimestampKey = "cached_owned_fish_timestamp"
    private let pondFishTimestampKey = "cached_pond_fish_timestamp"
    private let currencyTimestampKey = "cached_currency_timestamp"
    private let fishImagesTimestampKey = "cached_fish_images_timestamp"
    
    private init() {}
    
    // MARK: - Owned Fish
    func cacheOwnedFish(_ fish: [OwnedFish]) {
        if let data = try? JSONEncoder().encode(fish) {
            UserDefaults.standard.set(data, forKey: ownedFishKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: ownedFishTimestampKey)
            print("Cached \(fish.count) owned fish")
        }
    }
    
    func getCachedOwnedFish() -> [OwnedFish]? {
        guard let data = UserDefaults.standard.data(forKey: ownedFishKey),
              let fish = try? JSONDecoder().decode([OwnedFish].self, from: data) else {
            return nil
        }
        print("Retrieved \(fish.count) cached owned fish")
        return fish
    }
    
    func getOwnedFishLastUpdated() -> Date? {
          let timestamp = UserDefaults.standard.double(forKey: ownedFishTimestampKey)
          return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
      }
    
    // Add a new owned fish to cache
    func addOwnedFishToCache(fishId: Int) {
        var cached = getCachedOwnedFish() ?? []
        
        // Check if already exists
        if let index = cached.firstIndex(where: { $0.fish_id == fishId }) {
            cached[index].quantity += 1
        } else {
            let newFish = OwnedFish(fish_id: fishId, quantity: 1, time_studied: 0, total_time_needed: 60)
            cached.append(newFish)
        }
        
        cacheOwnedFish(cached)
        print("Optimistically added fish \(fishId) to cache")
    }
    
    // Update study time in cache
    func updateStudyTimeInCache(fishId: Int, additionalMinutes: Int) {
        guard var cached = getCachedOwnedFish() else { return }
        
        if let index = cached.firstIndex(where: { $0.fish_id == fishId }) {
            cached[index].time_studied += additionalMinutes
            cacheOwnedFish(cached)
            print("Optimistically updated study time for fish \(fishId)")
        }
    }
    
    // Remove fish from cache
    func removeFishFromCache(fishId: Int) {
        guard var cached = getCachedOwnedFish() else { return }
        cached.removeAll { $0.fish_id == fishId }
        cacheOwnedFish(cached)
        print("Optimistically removed fish \(fishId) from cache")
    }
    
    // MARK: - Pond Fish
    func cachePondFish(_ fish: [PondFish]) {
        if let data = try? JSONEncoder().encode(fish) {
            UserDefaults.standard.set(data, forKey: pondFishKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: pondFishTimestampKey)
            print("Cached \(fish.count) pond fish")
        }
    }
    
    func getCachedPondFish() -> [PondFish]? {
        guard let data = UserDefaults.standard.data(forKey: pondFishKey),
              let fish = try? JSONDecoder().decode([PondFish].self, from: data) else {
            return nil
        }
        print("Retrieved \(fish.count) cached pond fish")
        return fish
    }
    
    func getPondFishLastUpdated() -> Date? {
        let timestamp = UserDefaults.standard.double(forKey: pondFishTimestampKey)
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }
    
    // Add fish to pond cache
    func addFishToPondCache(fishId: Int) {
        var cached = getCachedPondFish() ?? []
        
        // Generate new ID
        let newId = (cached.map { $0.id }.max() ?? 0) + 1
        let newPondFish = PondFish(id: newId, fish_id: fishId)
        cached.append(newPondFish)
        
        cachePondFish(cached)
        print("Optimistically added fish \(fishId) to pond cache")
    }
    
    // MARK: - Currency
    func cacheCurrency(_ currency: Currency) {
        if let data = try? JSONEncoder().encode(currency) {
            UserDefaults.standard.set(data, forKey: currencyKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: currencyTimestampKey)
            print("Cached currency: \(currency.amount)")
        }
    }
    
    func getCachedCurrency() -> Currency? {
        guard let data = UserDefaults.standard.data(forKey: currencyKey),
              let currency = try? JSONDecoder().decode(Currency.self, from: data) else {
            return nil
        }
        print("Retrieved cached currency: \(currency.amount)")
        return currency
    }
    
    func getCurrencyLastUpdated() -> Date? {
        let timestamp = UserDefaults.standard.double(forKey: currencyTimestampKey)
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }
    
    // Update currency in cache
    func updateCurrencyInCache(newAmount: Int) {
        let currency = Currency(id: 1, amount: newAmount)
        cacheCurrency(currency)
        print("Updated currency to \(newAmount)")
    }
    
    // MARK: - Fish Images
    func cacheFishImages(_ images: [FishImage]) {
        if let data = try? JSONEncoder().encode(images) {
            UserDefaults.standard.set(data, forKey: fishImagesKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: fishImagesTimestampKey)
            print("Cached \(images.count) fish images")
        }
    }
    
    func getCachedFishImages() -> [FishImage]? {
        guard let data = UserDefaults.standard.data(forKey: fishImagesKey),
              let images = try? JSONDecoder().decode([FishImage].self, from: data) else {
            return nil
        }
        print("Retrieved \(images.count) cached fish images")
        return images
    }
    
    func getFishImagesLastUpdated() -> Date? {
        let timestamp = UserDefaults.standard.double(forKey: fishImagesTimestampKey)
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }
    
    // MARK: - Clear Cache
    func clearAllCache() {
        UserDefaults.standard.removeObject(forKey: ownedFishKey)
        UserDefaults.standard.removeObject(forKey: pondFishKey)
        UserDefaults.standard.removeObject(forKey: currencyKey)
        UserDefaults.standard.removeObject(forKey: fishImagesKey)
        print("All data cache cleared")
    }
}
