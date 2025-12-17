import SwiftUI
import Kingfisher

struct PondView: View {
    @StateObject private var viewModel = PondViewModel()
    @StateObject private var weatherService = WeatherService()
    @State private var pondSize: CGSize? = nil
    let fishSize: CGFloat = 150

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Image(backgroundImageName(for: weatherService.currentWeather))
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .clipped()

                ForEach(viewModel.fishPositions) { fishPos in
                    FloatingFish(fishPosition: fishPos, fishSize: fishSize)
                }
                // test the background changes based on weather (change the lat and long with locations with the correct weather condition
                /*.overlay(
                    HStack {
                        Button("Sunny") {
                            weatherService.fetchWeather(lat: 30.0444, lon: 31.2357) // Cairo
                        }
                        Button("Rainy") {
                            weatherService.fetchWeather(lat: 51.5074, lon: -0.1278) // London
                        }
                        Button("Snowy") {
                            weatherService.fetchWeather(lat: 56.2526, lon: -120.8460) // Helsinki
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .padding(.bottom, 20),
                    alignment: .bottom
                )*/
            }
            .onAppear {
                weatherService.start()
                pondSize = geometry.size
                viewModel.fetchAndInitializeFish(
                    screenWidth: geometry.size.width,
                    screenHeight: geometry.size.height,
                    fishSize: fishSize
                )
            }
            .onChange(of: geometry.size) { newSize in
                guard newSize.width > 0 && newSize.height > 0 else { return }
                if pondSize != newSize {
                    pondSize = newSize
                    viewModel.fetchAndInitializeFish(
                        screenWidth: newSize.width,
                        screenHeight: newSize.height,
                        fishSize: fishSize
                    )
                }
            }
            
        }
    }
    private func backgroundImageName(for condition: WeatherCondition) -> String {
        switch condition {
            case .sunny, .unknown:
                return "sun_pond"
            case .rainy:
                return "rain_pond"
            case .snowy:
                return "snow_pond"
        }
    }
}

struct FloatingFish: View {
    let fishPosition: FishPosition
    let fishSize: CGFloat
    @State private var animX: CGFloat = 0
    @State private var animY: CGFloat = 0

    var body: some View {
        let scaleX: CGFloat = fishPosition.facingLeft ? -1 : 1
        KFImage(URL(string: fishPosition.fish.adultSprite ?? ""))
            .placeholder {
                Image(systemName: "fish")
                    .resizable()
                    .scaledToFit()
                    .frame(width: fishSize, height: fishSize)
            }
            .resizable()
            .scaledToFit()
            .frame(width: fishSize, height: fishSize)
            .scaleEffect(x: scaleX, y: 1, anchor: .center)
            .offset(x: fishPosition.targetX, y: fishPosition.targetY)
            .animation(
                .linear(duration: fishPosition.animationDuration),
                value: fishPosition.targetX + fishPosition.targetY
            )
    }
}
