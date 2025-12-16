import Foundation
import CoreLocation
import Combine

enum WeatherCondition {
    case sunny
    case snowy
    case rainy
    case unknown
}

@MainActor
final class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentWeather: WeatherCondition = .sunny
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func start() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        manager.stopUpdatingLocation()
        fetchWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        currentWeather = .unknown
    }

    private func fetchWeather(lat: Double, lon: Double) {
        let urlString =
            "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=weathercode"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }

            do {
                let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
                let condition = self.weatherCondition(from: decoded.current.weathercode)
                self.currentWeather = condition
            } catch {
                print("Weather decode error:", error)
                self.currentWeather = .unknown
            }
        }.resume()
    }

    private func weatherCondition(from code: Int) -> WeatherCondition {
        if code >= 71 && code <= 77 {
            return .snowy
        }
        if code == 0 || code == 1 || code == 2 {
            return .sunny
        }
        return .rainy
    }
}

struct OpenMeteoResponse: Codable {
    let current: CurrentWeather
}

struct CurrentWeather: Codable {
    let weathercode: Int
}