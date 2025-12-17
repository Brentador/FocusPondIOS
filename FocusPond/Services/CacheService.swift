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
    
    // Track if we're currently syncing to avoid duplicate syncs
    private var isSyncing = false
    
    private init() {
        loadCachedOperations()
        startMonitoring()
    }
    
    // Start monitoring network status
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasOffline = self?.isOnline == false
                self?.isOnline = path.status == .satisfied
                
                // Only sync when transitioning from offline to online
                if wasOffline && self?.isOnline == true {
                    print("Back online - syncing cached operations")
                    await self?.syncCachedOperations()
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    // Check if backend is reachable
    func isBackendReachable() async -> Bool {
        guard let url = URL(string: "http://localhost:8000/api/health") else { return false }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            print("Backend not reachable: \(error.localizedDescription)")
            return false
        }
    }
    
    // Cache an operation
    func cacheOperation(_ operation: [String: Any]) {
        pendingOperations.append(operation)
        saveCachedOperations()
        print("Cached operation: \(operation["type"] ?? "unknown")")
    }
    
    // Get count of pending operations
    var pendingOperationsCount: Int {
        return pendingOperations.count
    }
    
    // Sync cached operations when online
    func syncCachedOperations() async {
        guard isOnline && !isSyncing else { return }
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
        
        // Remove successfully synced operations (in reverse order to maintain indices)
        for index in successfulOperations.reversed() {
            pendingOperations.remove(at: index)
        }
        
        saveCachedOperations()
        isSyncing = false
        
        print("✅ Sync complete. \(successfulOperations.count) operations synced, \(pendingOperations.count) remaining")
    }
    
    // Process a cached operation with async/await
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
                    print(success ? "Synced addOwnedFish for fishId: \(fishId)" : "❌ Failed to sync addOwnedFish")
                    continuation.resume(returning: success)
                }
                
            case "updateCurrency":
                guard let amount = operation["amount"] as? Int else {
                    continuation.resume(returning: false)
                    return
                }
                APIService.shared.performUpdateCurrency(amount: amount) { success in
                    print(success ? "Synced updateCurrency for amount: \(amount)" : "❌ Failed to sync updateCurrency")
                    continuation.resume(returning: success)
                }
                
            case "addStudyTime":
                guard let fishId = operation["fishId"] as? Int,
                      let minutes = operation["minutes"] as? Int else {
                    continuation.resume(returning: false)
                    return
                }
                // FIX: Call performAddStudyTime instead of addStudyTime
                APIService.shared.performAddStudyTime(fishId: fishId, minutes: minutes) { success in
                    print(success ? "Synced addStudyTime for fishId: \(fishId)" : "❌ Failed to sync addStudyTime")
                    continuation.resume(returning: success)
                }
                
            case "addFishToPond":
                guard let fishId = operation["fishId"] as? Int else {
                    continuation.resume(returning: false)
                    return
                }
                // FIX: Call performAddFishToPond instead of addFishToPond
                APIService.shared.performAddFishToPond(fishId: fishId) { success in
                    print(success ? "Synced addFishToPond for fishId: \(fishId)" : "❌ Failed to sync addFishToPond")
                    continuation.resume(returning: success)
                }
                
            case "resetFishProgress":
                guard let fishId = operation["fishId"] as? Int else {
                    continuation.resume(returning: false)
                    return
                }
                // FIX: Call performResetFishProgress instead of resetFishProgress
                APIService.shared.performResetFishProgress(fishId: fishId) { success in
                    print(success ? "Synced resetFishProgress for fishId: \(fishId)" : "❌ Failed to sync resetFishProgress")
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
        }
    }
    
    // Save cached operations to UserDefaults
    private func saveCachedOperations() {
        if let data = try? JSONSerialization.data(withJSONObject: pendingOperations) {
            UserDefaults.standard.set(data, forKey: pendingOperationsKey)
        }
    }
    
    // Clear all cached operations (for testing/debugging)
    func clearCache() {
        pendingOperations.removeAll()
        saveCachedOperations()
        print("Cache cleared")
    }
}