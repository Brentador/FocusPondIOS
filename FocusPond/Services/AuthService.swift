import Foundation

class AuthService {
    static let shared = AuthService()
    
    private let userDefaults = UserDefaults.standard
    private let userIdKey = "currentUserId"
    private let usernameKey = "currentUsername"
    
    var currentUser: User? {
        guard let id = userDefaults.value(forKey: userIdKey) as? Int,
              let username = userDefaults.value(forKey: usernameKey) as? String else {
            return nil
        }
        return User(id: id, username: username)
    }
    
    func login(userId: Int, username: String) {
        userDefaults.set(userId, forKey: userIdKey)
        userDefaults.set(username, forKey: usernameKey)
    }
    
    func logout() {
        userDefaults.removeObject(forKey: userIdKey)
        userDefaults.removeObject(forKey: usernameKey)
        CacheService.shared.clearCache()
        LocalDataCache.shared.clearUserCache()
    }
}