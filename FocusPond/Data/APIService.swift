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
    private let defaultTimeout: TimeInterval = 10
    
    private enum ContentType {
        static let json = "application/json"
    }
    
    private var currentUserId: Int? {
        return AuthService.shared.currentUser?.id
    }
    
    init() {}
    
    // MARK: - Currency
    func getCurrency(completion: @escaping (Currency?) -> Void) {
        guard let userId = currentUserId else {
            completion(nil)
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/currency"
        guard let url = URL(string: urlString) else { completion(nil); return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            Task { @MainActor in
                guard let data = data, error == nil else {
                    completion(nil)
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(Currency.self, from: data)
                    completion(decoded)
                } catch {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    func updateCurrency(amount: Int, completion: @escaping (Bool) -> Void) {
        guard let userId = currentUserId else {
            completion(false)
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/currency"
        guard let url = URL(string: urlString) else { completion(false); return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(ContentType.json, forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = defaultTimeout
        let body = ["amount": amount]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            Task { @MainActor in
                completion(data != nil && error == nil)
            }
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
        request.setValue(ContentType.json, forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = defaultTimeout
        do {
            let data = try JSONEncoder().encode(timerState)
            request.httpBody = data
        } catch {
            completion(false)
            return
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
            Task { @MainActor in
                completion(data != nil && error == nil)
            }
        }.resume()
    }
    
    // MARK: - Owned Fish
    func getOwnedFish(completion: @escaping ([OwnedFish]?) -> Void) {
        guard let userId = currentUserId else {
            completion(nil)
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/owned-fish"
        guard let url = URL(string: urlString) else { completion(nil); return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            Task { @MainActor in
                guard let data = data, error == nil else {
                    completion(nil)
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode([OwnedFish].self, from: data)
                    completion(decoded)
                } catch {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    func addOwnedFish(fishId: Int, completion: @escaping (Bool) -> Void) {
        guard let userId = currentUserId else {
            completion(false)
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/owned-fish"
        guard let url = URL(string: urlString) else { completion(false); return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(ContentType.json, forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = defaultTimeout
        let body = ["fish_id": fishId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            Task { @MainActor in
                completion(data != nil && error == nil)
            }
        }.resume()
    }
    
    func addStudyTime(fishId: Int, minutes: Int, completion: @escaping (Bool) -> Void) {
        guard let userId = currentUserId else {
            completion(false)
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/owned-fish/\(fishId)/study-time"
        guard let url = URL(string: urlString) else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(ContentType.json, forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = defaultTimeout
        let body = ["minutes": minutes]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            Task { @MainActor in
                completion(data != nil && error == nil)
            }
        }.resume()
    }
    
    func resetFishProgress(fishId: Int, completion: @escaping (Bool) -> Void) {
        guard let userId = currentUserId else {
            completion(false)
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/owned-fish/\(fishId)"
        guard let url = URL(string: urlString) else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = defaultTimeout
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            Task { @MainActor in
                completion(data != nil && error == nil)
            }
        }.resume()
    }
    
    // MARK: - Pond Fish
    func getPondFish(completion: @escaping ([PondFish]?) -> Void) {
        guard let userId = currentUserId else {
            completion(nil)
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/pond-fish"
        guard let url = URL(string: urlString) else { completion(nil); return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            Task { @MainActor in
                guard let data = data, error == nil else {
                    completion(nil)
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode([PondFish].self, from: data)
                    completion(decoded)
                } catch {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    func addFishToPond(fishId: Int, completion: @escaping (Bool) -> Void) {
        guard let userId = currentUserId else {
            completion(false)
            return
        }
        let urlString = "\(baseURL)/api/\(userId)/pond-fish"
        guard let url = URL(string: urlString) else { completion(false); return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(ContentType.json, forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = defaultTimeout
        let body = ["fish_id": fishId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            Task { @MainActor in
                completion(data != nil && error == nil)
            }
        }.resume()
    }
    
    // MARK: - Fish Images
    func getFishImages(completion: @escaping ([FishImage]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/fish-images") else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            Task { @MainActor in
                guard let data = data, error == nil else {
                    completion(nil)
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode([FishImage].self, from: data)
                    completion(decoded)
                } catch {
                    completion(nil)
                }
            }
        }.resume()
    }

    // MARK: - Auth
struct LoginResponse: Codable {
    let status: String
    let message: String
    let user_id: Int
}

func register(username: String, password: String, email: String, completion: @escaping (Bool, String?) -> Void) {
    let urlString = "\(baseURL)/api/register"
    guard let url = URL(string: urlString) else { 
        completion(false, "Invalid URL")
        return 
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(ContentType.json, forHTTPHeaderField: "Content-Type")
    let body = ["username": username, "password": password, "email": email]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        Task { @MainActor in
            guard let data = data, error == nil else {
                completion(false, "Network error: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 201 || httpResponse.statusCode == 200 {
                    completion(true, nil)
                    return
                }
                
                // Try to parse error message from backend
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Check for "detail" key (Django REST Framework format)
                    if let errorMsg = json["detail"] as? String {
                        completion(false, errorMsg)
                        return
                    }
                    // Check for "error" key
                    if let errorMsg = json["error"] as? String {
                        completion(false, errorMsg)
                        return
                    }
                }
                
                // Fallback to generic error
                completion(false, "Registration failed (Status: \(httpResponse.statusCode))")
            } else {
                completion(false, "Registration failed")
            }
        }
    }.resume()
}

func login(username: String, password: String, completion: @escaping (LoginResponse?) -> Void) {
    let urlString = "\(baseURL)/api/login"
    guard let url = URL(string: urlString) else { completion(nil); return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(ContentType.json, forHTTPHeaderField: "Content-Type")
    let body = ["username": username, "password": password]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    URLSession.shared.dataTask(with: request) { data, _, error in
        Task { @MainActor in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            do {
                let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
                completion(decoded)
            } catch {
                completion(nil)
            }
        }
    }.resume()
}
}
