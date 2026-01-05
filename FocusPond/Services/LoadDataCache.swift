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

    private func userKey(for key: String) -> String {
        if let userId = AuthService.shared.currentUser?.id {
            let userSpecificKey = "\(key)_user\(userId)"
            print("[LocalDataCache] Generated key: '\(userSpecificKey)' for user \(userId)")
            return userSpecificKey
        }
        print("No user logged in, using generic key: '\(key)'")
        return key
    }
    
    // MARK: - Owned Fish
    func cacheOwnedFish(_ fish: [OwnedFish]) {
        let currentUserId = AuthService.shared.currentUser?.id
        print("[LocalDataCache] CACHING OWNED FISH for user \(currentUserId ?? -1): \(fish.count) fish")
        print("   Fish IDs: \(fish.map { $0.fish_id })")
        
        if let data = try? JSONEncoder().encode(fish) {
            let key = userKey(for: ownedFishKey)
            UserDefaults.standard.set(data, forKey: key)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: userKey(for: ownedFishTimestampKey))
            print("   Successfully cached to key: '\(key)'")
        } else {
            print("   Failed to encode fish data")
        }
    }
    
    func getCachedOwnedFish() -> [OwnedFish]? {
        let currentUserId = AuthService.shared.currentUser?.id
        let key = userKey(for: ownedFishKey)
        
        print("[LocalDataCache] READING OWNED FISH for user \(currentUserId ?? -1) from key: '\(key)'")
        
        guard let data = UserDefaults.standard.data(forKey: key),
            let fish = try? JSONDecoder().decode([OwnedFish].self, from: data) else {
            print("   No cached data found or decode failed")
            return nil
        }
        print("   Retrieved \(fish.count) fish with IDs: \(fish.map { $0.fish_id })")
        return fish
    }
    
    func getOwnedFishLastUpdated() -> Date? {
        let timestamp = UserDefaults.standard.double(forKey: userKey(for: ownedFishTimestampKey))
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }
    
    // Add a new owned fish to cache
    func addOwnedFishToCache(fishId: Int) {
        let currentUserId = AuthService.shared.currentUser?.id
        print("[LocalDataCache] ADDING FISH \(fishId) to cache for user \(currentUserId ?? -1)")
        
        var cached = getCachedOwnedFish() ?? []
        
        // Check if already exists
        if let index = cached.firstIndex(where: { $0.fish_id == fishId }) {
            cached[index].quantity += 1
            print("   Fish already exists, incrementing quantity to \(cached[index].quantity)")
        } else {
            let newFish = OwnedFish(fish_id: fishId, quantity: 1, time_studied: 0, total_time_needed: 60)
            cached.append(newFish)
            print("   Added new fish entry")
        }
        
        cacheOwnedFish(cached)
    }
    
    // Update study time in cache
    func updateStudyTimeInCache(fishId: Int, additionalMinutes: Int) {
        let currentUserId = AuthService.shared.currentUser?.id
        print("[LocalDataCache] UPDATING STUDY TIME for fish \(fishId), user \(currentUserId ?? -1)")
        
        guard var cached = getCachedOwnedFish() else {
            print("   No cached fish found")
            return
        }
        
        if let index = cached.firstIndex(where: { $0.fish_id == fishId }) {
            let oldTime = cached[index].time_studied
            cached[index].time_studied += additionalMinutes
            print("   Updated time from \(oldTime) to \(cached[index].time_studied)")
            cacheOwnedFish(cached)
        } else {
            print("   Fish \(fishId) not found in cache")
        }
    }
    
    // Remove fish from cache
    func removeFishFromCache(fishId: Int) {
        let currentUserId = AuthService.shared.currentUser?.id
        print("[LocalDataCache] REMOVING FISH \(fishId) from cache for user \(currentUserId ?? -1)")
        
        guard var cached = getCachedOwnedFish() else {
            print("No cached fish found")
            return
        }
        
        let beforeCount = cached.count
        cached.removeAll { $0.fish_id == fishId }
        print("   Removed \(beforeCount - cached.count) fish")
        cacheOwnedFish(cached)
    }
    
    // MARK: - Pond Fish
    func cachePondFish(_ fish: [PondFish]) {
        let currentUserId = AuthService.shared.currentUser?.id
        print("[LocalDataCache] CACHING POND FISH for user \(currentUserId ?? -1): \(fish.count) fish")
        print("Fish IDs: \(fish.map { $0.fish_id })")
        
        if let data = try? JSONEncoder().encode(fish) {
            let key = userKey(for: pondFishKey)
            UserDefaults.standard.set(data, forKey: key)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: userKey(for: pondFishTimestampKey))
            print("   Successfully cached to key: '\(key)'")
        } else {
            print("   Failed to encode pond fish data")
        }
    }
    
    func getCachedPondFish() -> [PondFish]? {
        let currentUserId = AuthService.shared.currentUser?.id
        let key = userKey(for: pondFishKey)
        
        print("[LocalDataCache] READING POND FISH for user \(currentUserId ?? -1) from key: '\(key)'")
        
        guard let data = UserDefaults.standard.data(forKey: key),
            let fish = try? JSONDecoder().decode([PondFish].self, from: data) else {
            print("   No cached data found or decode failed")
            return nil
        }
        print("   Retrieved \(fish.count) pond fish with IDs: \(fish.map { $0.fish_id })")
        return fish
    }
    
    func getPondFishLastUpdated() -> Date? {
        let timestamp = UserDefaults.standard.double(forKey: userKey(for: pondFishTimestampKey))
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }
    
    // Add fish to pond cache
    func addFishToPondCache(fishId: Int) {
        let currentUserId = AuthService.shared.currentUser?.id
        print("[LocalDataCache] ADDING FISH \(fishId) TO POND for user \(currentUserId ?? -1)")
        
        var cached = getCachedPondFish() ?? []
        
        // Generate new ID
        let newId = (cached.map { $0.id }.max() ?? 0) + 1
        let newPondFish = PondFish(id: newId, fish_id: fishId)
        cached.append(newPondFish)
        
        print("   Added with pond ID: \(newId)")
        cachePondFish(cached)
    }
    
    // MARK: - Currency
    func cacheCurrency(_ currency: Currency) {
        let currentUserId = AuthService.shared.currentUser?.id
        print("💾 [LocalDataCache] CACHING CURRENCY for user \(currentUserId ?? -1): \(currency.amount)")
        
        if let data = try? JSONEncoder().encode(currency) {
            let key = userKey(for: currencyKey)
            UserDefaults.standard.set(data, forKey: key)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: userKey(for: currencyTimestampKey))
            print("   Successfully cached to key: '\(key)'")
        } else {
            print("   Failed to encode currency data")
        }
    }
    
    func getCachedCurrency() -> Currency? {
        let currentUserId = AuthService.shared.currentUser?.id
        let key = userKey(for: currencyKey)
        
        print("[LocalDataCache] READING CURRENCY for user \(currentUserId ?? -1) from key: '\(key)'")
        
        guard let data = UserDefaults.standard.data(forKey: key),
            let currency = try? JSONDecoder().decode(Currency.self, from: data) else {
            print("   No cached currency found or decode failed")
            return nil
        }
        print("   Retrieved currency: \(currency.amount)")
        return currency
    }
    
    func getCurrencyLastUpdated() -> Date? {
        let timestamp = UserDefaults.standard.double(forKey: userKey(for: currencyTimestampKey))
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }
    
    // Update currency in cache
    func updateCurrencyInCache(newAmount: Int) {
        let currentUserId = AuthService.shared.currentUser?.id
        print("[LocalDataCache] UPDATING CURRENCY for user \(currentUserId ?? -1) to \(newAmount)")
        
        let currency = Currency(id: 1, amount: newAmount)
        cacheCurrency(currency)
    }
    
    // MARK: - Fish Images
    func cacheFishImages(_ images: [FishImage]) {
        print("[LocalDataCache] CACHING FISH IMAGES (global): \(images.count) images")
        print("   Image IDs: \(images.map { $0.id })")
        
        if let data = try? JSONEncoder().encode(images) {
            UserDefaults.standard.set(data, forKey: fishImagesKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: fishImagesTimestampKey)
            print("   Successfully cached")
        }
    }

    func getCachedFishImages() -> [FishImage]? {
        print("[LocalDataCache] READING FISH IMAGES (global)")
        
        guard let data = UserDefaults.standard.data(forKey: fishImagesKey),
            let images = try? JSONDecoder().decode([FishImage].self, from: data) else {
            print("   No cached images found")
            return nil
        }
        print("   Retrieved \(images.count) images")
        return images
    }

    func getFishImagesLastUpdated() -> Date? {
        let timestamp = UserDefaults.standard.double(forKey: fishImagesTimestampKey)
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }
    
    // MARK: - Clear Cache
    func clearUserCache() {
        let currentUserId = AuthService.shared.currentUser?.id
        print("[LocalDataCache] CLEARING CACHE for user \(currentUserId ?? -1)")
        
        let keys = [
            userKey(for: ownedFishKey),
            userKey(for: pondFishKey),
            userKey(for: currencyKey),
            userKey(for: ownedFishTimestampKey),
            userKey(for: pondFishTimestampKey),
            userKey(for: currencyTimestampKey)
        ]
        
        print("   Removing keys: \(keys)")
        
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        print("   User-specific cache cleared")
    }
}
