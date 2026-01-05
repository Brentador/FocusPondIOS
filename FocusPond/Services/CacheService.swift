import Foundation
import Network
import Combine

@MainActor
class CacheService: ObservableObject {
    static let shared = CacheService()
    
    @Published var isOnline: Bool = true
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var cancellables = Set<AnyCancellable>()
    
    // Cache for pending operations
    private let pendingOperationsKey = "pendingOperations"
    private var pendingOperations: [[String: Any]] = []
    private var isSyncing = false
    
    // Polling timer to check backend
    private var backendCheckTimer: Timer?
    private var wasBackendOffline = false
    
    private init() {
        loadCachedOperations()
        startMonitoring()
        startBackendPolling()
    }

    private func userKey(for key: String) -> String {
        if let userId = AuthService.shared.currentUser?.id {
            return "\(key)_user\(userId)"
        }
        return key
    }
    
    // Start monitoring network status
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let newStatus = path.status == .satisfied
                self.isOnline = newStatus
                
                if newStatus {
                    print("Network connected")
                    // Sync pending operations when network comes back
                    if !self.pendingOperations.isEmpty {
                        Task {
                            await self.syncCachedOperations()
                        }
                    }
                } else {
                    print("Network disconnected")
                    self.wasBackendOffline = true
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    // Poll backend every 5 seconds
    private func startBackendPolling() {
        backendCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkBackendStatus()
            }
        }
    }
    
    // Check if backend is reachable
    private func checkBackendStatus() async {
        let reachable = await isBackendReachable()
        
        if reachable && wasBackendOffline {
            // Backend came back online!
            print("Backend is back online!")
            wasBackendOffline = false
            await syncCachedOperations()
        } else if !reachable {
            wasBackendOffline = true
        }
    }
    
    func isBackendReachable() async -> Bool {
        guard let url = URL(string: "http://localhost:8000/api/fish-images") else { return false }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
    
    // Cache an operation
    func cacheOperation(_ operation: [String: Any]) {
        pendingOperations.append(operation)
        saveCachedOperations()
        print("Cached operation: \(operation["type"] ?? "unknown") - Total pending: \(pendingOperations.count)")
    }
    
    // Get count of pending operations
    var pendingOperationsCount: Int {
        return pendingOperations.count
    }
    
    // Sync cached operations when online
    func syncCachedOperations() async {
        guard !isSyncing else {
            print("Sync already in progress")
            return
        }
        guard !pendingOperations.isEmpty else {
            print("No pending operations to sync")
            return
        }
        
        isSyncing = true
        print("Starting sync of \(pendingOperations.count) operations")
        
        var successfulOperations: [Int] = []
        
        for (index, operation) in pendingOperations.enumerated() {
            let success = await processCachedOperation(operation)
            if success {
                successfulOperations.append(index)
            } else {
                print("Failed to sync operation: \(operation["type"] ?? "unknown")")
            }
        }
        
        for index in successfulOperations.reversed() {
            pendingOperations.remove(at: index)
        }
        
        saveCachedOperations()
        isSyncing = false
        
        print("Sync complete. \(successfulOperations.count) operations synced, \(pendingOperations.count) remaining")
        
        // After sync reload data from server
        if successfulOperations.count > 0 {
            print("Reloading data from server...")
            // Give server a moment to process
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            FishManager.shared.loadData()
        }
    }
    
    // MARK: - Public Orchestration Methods
    
    func getCurrency(completion: @escaping (Currency?) -> Void) {
        APIService.shared.getCurrency { currency in
            if let currency = currency {
                LocalDataCache.shared.cacheCurrency(currency)
                completion(currency)
            } else {
                // Offline - use cache
                completion(LocalDataCache.shared.getCachedCurrency())
            }
        }
    }
    
    func updateCurrency(amount: Int, completion: @escaping (Bool) -> Void) {
        APIService.shared.updateCurrency(amount: amount) { success in
            LocalDataCache.shared.updateCurrencyInCache(newAmount: amount)
            if !success {
                // Offline - queue for sync
                self.cacheOperation(["type": "updateCurrency", "amount": amount])
            }
            completion(true)
        }
    }
    
    func getOwnedFish(completion: @escaping ([OwnedFish]?) -> Void) {
        APIService.shared.getOwnedFish { fish in
            if let fish = fish {
                LocalDataCache.shared.cacheOwnedFish(fish)
                completion(fish)
            } else {
                // Offline - use cache
                completion(LocalDataCache.shared.getCachedOwnedFish())
            }
        }
    }
    
    func addOwnedFish(fishId: Int, completion: @escaping (Bool) -> Void) {
        APIService.shared.addOwnedFish(fishId: fishId) { success in
            LocalDataCache.shared.addOwnedFishToCache(fishId: fishId)
            if !success {
                // Offline - queue for sync
                self.cacheOperation(["type": "addOwnedFish", "fishId": fishId])
            }
            completion(true)
        }
    }
    
    func addStudyTime(fishId: Int, minutes: Int, completion: @escaping (Bool) -> Void) {
        APIService.shared.addStudyTime(fishId: fishId, minutes: minutes) { success in
            LocalDataCache.shared.updateStudyTimeInCache(fishId: fishId, additionalMinutes: minutes)
            if !success {
                // Offline - queue for sync
                self.cacheOperation(["type": "addStudyTime", "fishId": fishId, "minutes": minutes])
            }
            completion(true)
        }
    }
    
    func resetFishProgress(fishId: Int, completion: @escaping (Bool) -> Void) {
        APIService.shared.resetFishProgress(fishId: fishId) { success in
            LocalDataCache.shared.removeFishFromCache(fishId: fishId)
            if !success {
                // Offline - queue for sync
                self.cacheOperation(["type": "resetFishProgress", "fishId": fishId])
            }
            completion(true)
        }
    }
    
    func getPondFish(completion: @escaping ([PondFish]?) -> Void) {
        APIService.shared.getPondFish { fish in
            if let fish = fish {
                LocalDataCache.shared.cachePondFish(fish)
                completion(fish)
            } else {
                // Offline - use cache
                completion(LocalDataCache.shared.getCachedPondFish())
            }
        }
    }
    
    func addFishToPond(fishId: Int, completion: @escaping (Bool) -> Void) {
        APIService.shared.addFishToPond(fishId: fishId) { success in
            LocalDataCache.shared.addFishToPondCache(fishId: fishId)
            if !success {
                // Offline - queue for sync
                self.cacheOperation(["type": "addFishToPond", "fishId": fishId])
            }
            completion(true)
        }
    }
    
    func getFishImages(completion: @escaping ([FishImage]?) -> Void) {
        APIService.shared.getFishImages { images in
            if let images = images {
                LocalDataCache.shared.cacheFishImages(images)
                completion(images)
            } else {
                // Offline - use cache
                completion(LocalDataCache.shared.getCachedFishImages())
            }
        }
    }
    
    // Process a cached operation
    private func processCachedOperation(_ operation: [String: Any]) async -> Bool {
        guard let type = operation["type"] as? String else { return false }
        
        return await withCheckedContinuation { continuation in
            switch type {
            case "addOwnedFish":
                guard let fishId = operation["fishId"] as? Int else {
                    continuation.resume(returning: false)
                    return
                }
                APIService.shared.addOwnedFish(fishId: fishId) { success in
                    print(success ? "Synced addOwnedFish for fishId: \(fishId)" : "Failed to sync addOwnedFish")
                    continuation.resume(returning: success)
                }
                
            case "updateCurrency":
                guard let amount = operation["amount"] as? Int else {
                    continuation.resume(returning: false)
                    return
                }
                APIService.shared.updateCurrency(amount: amount) { success in
                    print(success ? "Synced updateCurrency for amount: \(amount)" : "Failed to sync updateCurrency")
                    continuation.resume(returning: success)
                }
                
            case "addStudyTime":
                guard let fishId = operation["fishId"] as? Int,
                      let minutes = operation["minutes"] as? Int else {
                    continuation.resume(returning: false)
                    return
                }
                APIService.shared.addStudyTime(fishId: fishId, minutes: minutes) { success in
                    print(success ? "Synced addStudyTime for fishId: \(fishId)" : "Failed to sync addStudyTime")
                    continuation.resume(returning: success)
                }
                
            case "addFishToPond":
                guard let fishId = operation["fishId"] as? Int else {
                    continuation.resume(returning: false)
                    return
                }
                APIService.shared.addFishToPond(fishId: fishId) { success in
                    print(success ? "Synced addFishToPond for fishId: \(fishId)" : "Failed to sync addFishToPond")
                    continuation.resume(returning: success)
                }
                
            case "resetFishProgress":
                guard let fishId = operation["fishId"] as? Int else {
                    continuation.resume(returning: false)
                    return
                }
                APIService.shared.resetFishProgress(fishId: fishId) { success in
                    print(success ? "Synced resetFishProgress for fishId: \(fishId)" : "Failed to sync resetFishProgress")
                    continuation.resume(returning: success)
                }
                
            default:
                print("Unknown operation type: \(type)")
                continuation.resume(returning: false)
            }
        }
    }
    
    // Load cached operations from UserDefaults
    private func loadCachedOperations() {
        let key = userKey(for: pendingOperationsKey)
        if let data = UserDefaults.standard.data(forKey: key),
           let operations = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            pendingOperations = operations
            print("Loaded \(operations.count) cached operations for user")
            if operations.count > 0 {
                wasBackendOffline = true
            }
        } else {
            pendingOperations = []
        }
    }
    
    // Save cached operations to UserDefaults
    private func saveCachedOperations() {
        let key = userKey(for: pendingOperationsKey)
        if let data = try? JSONSerialization.data(withJSONObject: pendingOperations) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    // testing/debugging
    func clearCache() {
        let key = userKey(for: pendingOperationsKey)
        UserDefaults.standard.removeObject(forKey: key)
        pendingOperations.removeAll()
        print("Cache cleared for user")
    }
    
    deinit {
        backendCheckTimer?.invalidate()
    }
    
    @MainActor
    func manualFetchAndReload(completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        group.enter()
        self.getOwnedFish { _ in
            group.leave()
        }
        
        group.enter()
        self.getPondFish { _ in
            group.leave()
        }
        
        group.enter()
        self.getCurrency { _ in
            group.leave()
        }
        
        group.enter()
        self.getFishImages { _ in
            group.leave()
        }
        
        group.notify(queue: .main) {
            print("Manual cache update complete")
            FishManager.shared.loadData()
            completion()
        }
    }
}
