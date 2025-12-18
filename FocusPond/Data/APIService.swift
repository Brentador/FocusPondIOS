import Foundation

struct FishImage: Decodable, Encodable {
    let id: Int
    let egg_url: String
    let fry_url: String
    let fish_url: String
}

class APIService {
    static let shared = APIService()
    private let baseURL = "http://localhost:8000"
    private var currentUserId: Int? {
        return AuthService.shared.currentUser?.id
    }
    
    init() {}
    
    // MARK: - Currency
    func getCurrency(completion: @escaping (Currency?) -> Void) {
        guard let userId = currentUserId else {
            print("User not logged in, using cached data")
            completion(LocalDataCache.shared.getCachedCurrency()) 
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/currency"
        guard let url = URL(string: urlString) else { completion(nil); return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            Task { @MainActor in
                guard let data = data, error == nil else {
                    print("getCurrency failed, using cached data")
                    completion(LocalDataCache.shared.getCachedCurrency())
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(Currency.self, from: data)
                    LocalDataCache.shared.cacheCurrency(decoded)
                    completion(decoded)
                } catch {
                    print("Currency decode error:", error)
                    completion(LocalDataCache.shared.getCachedCurrency())
                }
            }
        }.resume()
    }
    
    func updateCurrency(amount: Int, completion: @escaping (Bool) -> Void) {
        performUpdateCurrency(amount: amount) { success in
            if !success {
                // Failed
                LocalDataCache.shared.updateCurrencyInCache(newAmount: amount)
                Task { @MainActor in
                    CacheService.shared.cacheOperation(["type": "updateCurrency", "amount": amount])
                }
                completion(true)
            } else {
                // Success
                LocalDataCache.shared.updateCurrencyInCache(newAmount: amount)
                completion(true)
            }
        }
    }
    
    func performUpdateCurrency(amount: Int, completion: @escaping (Bool) -> Void) {
        guard let userId = currentUserId else {
            print("User not logged in, using cached data")
                LocalDataCache.shared.updateCurrencyInCache(newAmount: amount)
            Task { @MainActor in
                CacheService.shared.cacheOperation(["type": "updateCurrency", "amount": amount])
            }
            completion(true)
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/currency"
        guard let url = URL(string: urlString) else { completion(false); return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        let body = ["amount": amount]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard data != nil, error == nil else {
                print("updateCurrency failed: \(error?.localizedDescription ?? "unknown")")
                completion(false)
                return
            }
            completion(true)
        }.resume()
    }
    
    // MARK: - Timer State
    func getTimerState(completion: @escaping (TimerStateModel?) -> Void) {
        guard let userId = currentUserId else {
            print("User not logged in, no timer state")
            completion(nil)
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/timer-state"
        guard let url = URL(string: urlString) else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            Task { @MainActor in
                guard let data = data, error == nil else {
                    print("getTimerState failed")
                    completion(nil)
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(TimerStateModel.self, from: data)
                    completion(decoded)
                } catch {
                    print("Timer state decode error:", error)
                    completion(nil)
                }
            }
        }.resume()
    }

    func updateTimerState(_ timerState: TimerStateModel, completion: @escaping (Bool) -> Void) {
        guard let userId = currentUserId else {
            print("User not logged in, cannot update timer state")
            completion(false)
            return
        }

        let urlString = "\(baseURL)/api/\(userId)/timer-state"
        guard let url = URL(string: urlString) else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        do {
            let data = try JSONEncoder().encode(timerState)
            request.httpBody = data
        } catch {
            print("Timer state encode error:", error)
            completion(false)
            return
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
            Task { @MainActor in
                guard data != nil, error == nil else { completion(false); return }
                completion(true)
            }
        }.resume()
    }
    
    // MARK: - Owned Fish
    func getOwnedFish(completion: @escaping ([OwnedFish]?) -> Void) {
        guard let userId = currentUserId else {
            print("User not logged in, using cached data")
            completion(LocalDataCache.shared.getCachedOwnedFish())
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/owned-fish"
        guard let url = URL(string: urlString) else { completion(nil); return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            Task { @MainActor in
                guard let data = data, error == nil else {
                    print("getOwnedFish failed, using cached data")
                    completion(LocalDataCache.shared.getCachedOwnedFish())
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode([OwnedFish].self, from: data)
                    LocalDataCache.shared.cacheOwnedFish(decoded)
                    completion(decoded)
                } catch {
                    print("Owned fish decode error:", error)
                    completion(LocalDataCache.shared.getCachedOwnedFish())
                }
            }
        }.resume()
    }
    
    func addOwnedFish(fishId: Int, completion: @escaping (Bool) -> Void) {
        performAddOwnedFish(fishId: fishId) { success in
            if !success {
                LocalDataCache.shared.addOwnedFishToCache(fishId: fishId)
                Task { @MainActor in
                    CacheService.shared.cacheOperation(["type": "addOwnedFish", "fishId": fishId])
                }
                completion(true)
            } else {
                completion(true)
            }
        }
    }
    
    func performAddOwnedFish(fishId: Int, completion: @escaping (Bool) -> Void) {
        guard let userId = currentUserId else {
            print("User not logged in, using cached data")
            LocalDataCache.shared.addOwnedFishToCache(fishId: fishId)
            Task { @MainActor in
                CacheService.shared.cacheOperation(["type": "addOwnedFish", "fishId": fishId])
            }
            completion(true)
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/owned-fish"
        guard let url = URL(string: urlString) else { completion(false); return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        let body = ["fish_id": fishId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard data != nil, error == nil else {
                print("addOwnedFish failed: \(error?.localizedDescription ?? "unknown")")
                completion(false)
                return
            }
            completion(true)
        }.resume()
    }
    
    func addStudyTime(fishId: Int, minutes: Int, completion: @escaping (Bool) -> Void) {
        performAddStudyTime(fishId: fishId, minutes: minutes) { success in
            if !success {
                LocalDataCache.shared.updateStudyTimeInCache(fishId: fishId, additionalMinutes: minutes)
                Task { @MainActor in
                    CacheService.shared.cacheOperation([
                        "type": "addStudyTime",
                        "fishId": fishId,
                        "minutes": minutes
                    ])
                }
                completion(true)
            } else {
                completion(true)
            }
        }
    }
    
    func performAddStudyTime(fishId: Int, minutes: Int, completion: @escaping (Bool) -> Void) {
        guard let userId = currentUserId else {
            print("User not logged in, using cached data")
            LocalDataCache.shared.updateStudyTimeInCache(fishId: fishId, additionalMinutes: minutes)
            Task { @MainActor in
                CacheService.shared.cacheOperation(["type": "addStudyTime", "fishId": fishId, "minutes": minutes])
            }
            completion(true)
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/owned-fish/\(fishId)/study-time"
        guard let url = URL(string: urlString) else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        let body = ["minutes": minutes]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard data != nil, error == nil else {
                print("addStudyTime failed: \(error?.localizedDescription ?? "unknown")")
                completion(false)
                return
            }
            completion(true)
        }.resume()
    }
    
    func resetFishProgress(fishId: Int, completion: @escaping (Bool) -> Void) {
        performResetFishProgress(fishId: fishId) { success in
            if !success {
                // Failed - update cache optimistically and queue operation
                LocalDataCache.shared.removeFishFromCache(fishId: fishId)
                Task { @MainActor in
                    CacheService.shared.cacheOperation([
                        "type": "resetFishProgress",
                        "fishId": fishId
                    ])
                }
                completion(true)
            } else {
                completion(true)
            }
        }
    }
    
    func performResetFishProgress(fishId: Int, completion: @escaping (Bool) -> Void) {
        guard let userId = currentUserId else {
            print("User not logged in, using cached data")
            LocalDataCache.shared.removeFishFromCache(fishId: fishId)
            Task { @MainActor in
                CacheService.shared.cacheOperation(["type": "resetFishProgress", "fishId": fishId])
            }
            completion(true)
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/owned-fish/\(fishId)"
        guard let url = URL(string: urlString) else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard data != nil, error == nil else {
                print("resetFishProgress failed: \(error?.localizedDescription ?? "unknown")")
                completion(false)
                return
            }
            completion(true)
        }.resume()
    }
    
    // MARK: - Pond Fish
    func getPondFish(completion: @escaping ([PondFish]?) -> Void) {
        guard let userId = currentUserId else {
            print("User not logged in, using cached data")
            completion(LocalDataCache.shared.getCachedPondFish())
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/pond-fish"
        guard let url = URL(string: urlString) else { completion(nil); return }
    
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            Task { @MainActor in
                guard let data = data, error == nil else {
                    print("getPondFish failed, using cached data")
                    completion(LocalDataCache.shared.getCachedPondFish())
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode([PondFish].self, from: data)
                    LocalDataCache.shared.cachePondFish(decoded)
                    completion(decoded)
                } catch {
                    print("Pond fish decode error:", error)
                    completion(LocalDataCache.shared.getCachedPondFish())
                }
            }
        }.resume()
    }
    
    func addFishToPond(fishId: Int, completion: @escaping (Bool) -> Void) {
        performAddFishToPond(fishId: fishId) { success in
            if !success {
                // Failed - update cache optimistically and queue operation
                LocalDataCache.shared.addFishToPondCache(fishId: fishId)
                Task { @MainActor in
                    CacheService.shared.cacheOperation([
                        "type": "addFishToPond",
                        "fishId": fishId
                    ])
                }
                completion(true)
            } else {
                completion(true)
            }
        }
    }
    
    func performAddFishToPond(fishId: Int, completion: @escaping (Bool) -> Void) {
        guard let userId = currentUserId else {
            print("User not logged in, using cached data")
            LocalDataCache.shared.addFishToPondCache(fishId: fishId)
            Task { @MainActor in
                CacheService.shared.cacheOperation(["type": "addFishToPond", "fishId": fishId])
            }
            completion(true)
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/pond-fish"
        guard let url = URL(string: urlString) else { completion(false); return }
    
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        let body = ["fish_id": fishId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard data != nil, error == nil else {
                print("addFishToPond failed: \(error?.localizedDescription ?? "unknown")")
                completion(false)
                return
            }
            completion(true)
        }.resume()
    }
    
    // MARK: - Fish Images
    func getFishImages(completion: @escaping ([FishImage]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/fish-images") else {
            completion(LocalDataCache.shared.getCachedFishImages())
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            Task { @MainActor in
                guard let data = data, error == nil else {
                    print("getFishImages failed, using cached data")
                    completion(LocalDataCache.shared.getCachedFishImages())
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode([FishImage].self, from: data)
                    LocalDataCache.shared.cacheFishImages(decoded)
                    completion(decoded)
                } catch {
                    print("Fish images decode error:", error)
                    completion(LocalDataCache.shared.getCachedFishImages())
                }
            }
        }.resume()
    }

    // MARK: - Auth
struct LoginResponse: Codable {
    let user_id: Int
}

func register(username: String, password: String, email: String, completion: @escaping (Bool) -> Void) {
    let urlString = "\(baseURL)/api/register"
    guard let url = URL(string: urlString) else { completion(false); return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body = ["username": username, "password": password, "email": email]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    URLSession.shared.dataTask(with: request) { data, _, error in
        guard data != nil, error == nil else {
            print("Register failed: \(error?.localizedDescription ?? "unknown")")
            completion(false)
            return
        }
        completion(true)
    }.resume()
}

func login(username: String, password: String, completion: @escaping (LoginResponse?) -> Void) {
    let urlString = "\(baseURL)/api/login"
    guard let url = URL(string: urlString) else { completion(nil); return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body = ["username": username, "password": password]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    URLSession.shared.dataTask(with: request) { data, _, error in
        Task { @MainActor in
            guard let data = data, error == nil else {
                print("Login failed: \(error?.localizedDescription ?? "unknown")")
                completion(nil)
                return
            }
            do {
                let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
                completion(decoded)
            } catch {
                print("Login decode error:", error)
                completion(nil)
            }
        }
    }.resume()
}
}
