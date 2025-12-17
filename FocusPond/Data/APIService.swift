import Foundation

struct FishImage: Decodable {
    let id: Int
    let egg_url: String
    let fry_url: String
    let fish_url: String
}

class APIService {
            // Fetch timer state
    func getTimerState(completion: @escaping (TimerStateModel?) -> Void) {
        guard let url = URL(string: "\(baseURL)/timer-state") else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { completion(nil); return }
            do {
                let decoded = try JSONDecoder().decode(TimerStateModel.self, from: data)
                completion(decoded)
            } catch {
                print(error)
                completion(nil)
            }
        }.resume()
    }

            // Update timer state
    func updateTimerState(_ timerState: TimerStateModel, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/timer-state") else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
            let data = try JSONEncoder().encode(timerState)
            request.httpBody = data
        } catch {
            print(error)
            completion(false)
            return
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
        guard data != nil, error == nil else { completion(false); return }
            completion(true)
        }.resume()
    }
    func getPondFish(completion: @escaping ([PondFish]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/pond-fish") else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { completion(nil); return }
            do {
                let decoded = try JSONDecoder().decode([PondFish].self, from: data)
                completion(decoded)
            } catch {
                print(error)
                completion(nil)
            }
        }.resume()
    }
    static let shared = APIService()
    private let baseURL = "http://localhost:8000/api"
    
    private init() {}
    
    func getOwnedFish(completion: @escaping ([OwnedFish]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/owned-fish") else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { completion(nil); return }
            do {
                let decoded = try JSONDecoder().decode([OwnedFish].self, from: data)
                completion(decoded)
            } catch {
                print(error)
                completion(nil)
            }
        }.resume()
    }
    
    func getFishImages(completion: @escaping ([FishImage]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/fish-images") else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { completion(nil); return }
            do {
                let decoded = try JSONDecoder().decode([FishImage].self, from: data)
                completion(decoded)
            } catch {
                print(error)
                completion(nil)
            }
        }.resume()
    }
    
    func addOwnedFish(fishId: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/owned-fish") else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["fish_id": fishId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard data != nil, error == nil else { completion(false); return }
            completion(true)
        }.resume()
    }
    
    func addFishToPond(fishId: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/pond-fish") else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["fish_id": fishId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard data != nil, error == nil else { completion(false); return }
            completion(true)
        }.resume()
    }
    
    func addStudyTime(fishId: Int, minutes: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/owned-fish/\(fishId)/study-time") else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["minutes": minutes]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard data != nil, error == nil else { completion(false); return }
            completion(true)
        }.resume()
    }
    
    func getCurrency(completion: @escaping (Int?) -> Void) {
        guard let url = URL(string: "\(baseURL)/currency") else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { completion(nil); return }
            do {
                let decoded = try JSONDecoder().decode([String: Int].self, from: data)
                completion(decoded["amount"])
            } catch {
                print(error)
                completion(nil)
            }
        }.resume()
    }
    
    func updateCurrency(amount: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/currency") else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["amount": amount]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard data != nil, error == nil else { completion(false); return }
            completion(true)
        }.resume()
    }
    
    func resetFishProgress(fishId: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/owned-fish/\(fishId)") else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard data != nil, error == nil else { completion(false); return }
            completion(true)
        }.resume()
    }
}
