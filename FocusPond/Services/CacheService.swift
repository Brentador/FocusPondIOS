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
        guard let url = URL(string: "http://localhost:8000/api/owned-fish") else { return false }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200 || httpResponse.statusCode == 404
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
                APIService.shared.performAddOwnedFish(fishId: fishId) { success in
                    print(success ? "Synced addOwnedFish for fishId: \(fishId)" : "Failed to sync addOwnedFish")
                    continuation.resume(returning: success)
                }
                
            case "updateCurrency":
                guard let amount = operation["amount"] as? Int else {
                    continuation.resume(returning: false)
                    return
                }
                APIService.shared.performUpdateCurrency(amount: amount) { success in
                    print(success ? "Synced updateCurrency for amount: \(amount)" : "Failed to sync updateCurrency")
                    continuation.resume(returning: success)
                }
                
            case "addStudyTime":
                guard let fishId = operation["fishId"] as? Int,
                      let minutes = operation["minutes"] as? Int else {
                    continuation.resume(returning: false)
                    return
                }
                APIService.shared.performAddStudyTime(fishId: fishId, minutes: minutes) { success in
                    print(success ? "Synced addStudyTime for fishId: \(fishId)" : "Failed to sync addStudyTime")
                    continuation.resume(returning: success)
                }
                
            case "addFishToPond":
                guard let fishId = operation["fishId"] as? Int else {
                    continuation.resume(returning: false)
                    return
                }
                APIService.shared.performAddFishToPond(fishId: fishId) { success in
                    print(success ? "Synced addFishToPond for fishId: \(fishId)" : "Failed to sync addFishToPond")
                    continuation.resume(returning: success)
                }
                
            case "resetFishProgress":
                guard let fishId = operation["fishId"] as? Int else {
                    continuation.resume(returning: false)
                    return
                }
                APIService.shared.performResetFishProgress(fishId: fishId) { success in
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
        if let data = UserDefaults.standard.data(forKey: pendingOperationsKey),
           let operations = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            pendingOperations = operations
            print("Loaded \(operations.count) cached operations")
            if operations.count > 0 {
                wasBackendOffline = true
            }
        }
    }
    
    // Save cached operations to UserDefaults
    private func saveCachedOperations() {
        if let data = try? JSONSerialization.data(withJSONObject: pendingOperations) {
            UserDefaults.standard.set(data, forKey: pendingOperationsKey)
        }
    }
    
    // testing/debugging
    func clearCache() {
        pendingOperations.removeAll()
        saveCachedOperations()
        print("Cache cleared")
    }
    
    deinit {
        backendCheckTimer?.invalidate()
    }
    
    @MainActor
    func manualFetchAndReload(completion: @escaping () -> Void) {
        let apiService = APIService()
        
        let group = DispatchGroup()
        
        group.enter()
        apiService.getOwnedFish { fish in
            if let fish = fish {
                LocalDataCache.shared.cacheOwnedFish(fish)
            }
            group.leave()
        }
        
        group.enter()
        apiService.getPondFish { fish in
            if let fish = fish {
                LocalDataCache.shared.cachePondFish(fish)
            }
            group.leave()
        }
        
        group.enter()
        apiService.getCurrency { currency in
            if let currency = currency {
                LocalDataCache.shared.cacheCurrency(currency)
            }
            group.leave()
        }
        
        group.enter()
        apiService.getFishImages { images in
            if let images = images {
                LocalDataCache.shared.cacheFishImages(images)
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            print("Manual cache update complete")
            FishManager.shared.loadData()  // Reload UI from cache
            completion()
        }
    }
}
