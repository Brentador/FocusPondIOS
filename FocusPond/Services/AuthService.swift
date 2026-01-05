import Foundation
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    private let userDefaults = UserDefaults.standard
    private let userIdKey = "currentUserId"
    private let usernameKey = "currentUsername"

    @Published var currentUser: User? = nil {
        didSet {
            if let user = currentUser {
                print("[AuthService] Current user changed to: ID=\(user.id), Username=\(user.username)")
            } else {
                print("[AuthService] Current user cleared (logged out)")
            }
        }
    }

    private init() {
        print("[AuthService] Initializing...")
        if let id = userDefaults.value(forKey: userIdKey) as? Int,
           let username = userDefaults.value(forKey: usernameKey) as? String {
            currentUser = User(id: id, username: username)
            print("   Restored user from UserDefaults: ID=\(id), Username=\(username)")
        } else {
            print("   No saved user found")
        }
    }
    
    
    func login(userId: Int, username: String) {
        print("[AuthService] LOGIN INITIATED")
        print("   New User ID: \(userId)")
        print("   New Username: \(username)")
        
        // Check if switching users
        if let oldUser = currentUser {
            print("   Switching from user \(oldUser.id) (\(oldUser.username)) to user \(userId) (\(username))")
        }
        
        // ✅ FIX: Clear cache and reset state BEFORE setting new user
        print("   Clearing old cache data...")
        LocalDataCache.shared.clearUserCache()
        
        // ✅ FIX: Reset FishManager immediately (check if already on main thread)
        if Thread.isMainThread {
            FishManager.shared.resetState()
        } else {
            DispatchQueue.main.sync {
                FishManager.shared.resetState()
            }
        }
        
        currentUser = User(id: userId, username: username)
        userDefaults.set(userId, forKey: userIdKey)
        userDefaults.set(username, forKey: usernameKey)
        
        print("   User data saved to UserDefaults")
        print("   Current user is now: \(currentUser?.id ?? -1)")
        
        // ✅ FIX: Fetch fresh data for new user
        print("   Fetching fresh data for new user...")
        Task { @MainActor in
            CacheService.shared.manualFetchAndReload {
                print("   Fresh data loaded for user \(userId)")
            }
        }
    }
    
    func logout() {
        print("[AuthService] LOGOUT INITIATED")
        
        if let user = currentUser {
            print("   Logging out user: ID=\(user.id), Username=\(user.username)")
            
            // Clear timer UserDefaults for this user
            let timerKey = "timerWasRunning_user\(user.id)"
            userDefaults.removeObject(forKey: timerKey)
            print("   Cleared timer state for user \(user.id)")
        } else {
            print("   No user to log out")
        }
        
        currentUser = nil
        userDefaults.removeObject(forKey: userIdKey)
        userDefaults.removeObject(forKey: usernameKey)
        
        print("   Clearing CacheService...")
        CacheService.shared.clearCache()
        
        print("   Clearing LocalDataCache...")
        LocalDataCache.shared.clearUserCache()
        
        print("   Stopping TimerService...")
        TimerService.shared.stopTimer()
        
        print("   Logout complete")
    }
}
