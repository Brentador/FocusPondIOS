import SwiftUI
import Kingfisher
import FocusPond.Services

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

                // Floating fish
                ForEach(viewModel.fishPositions) { fishPos in
                    FloatingFish(fishPosition: fishPos, fishSize: fishSize)
                }
            }
            .onAppear {
                weatherService.start()
                if pondSize == nil {
                    pondSize = geometry.size
                    viewModel.fetchAndInitializeFish(
                        screenWidth: geometry.size.width,
                        screenHeight: geometry.size.height,
                        fishSize: fishSize
                    )
                }
            }
            .onChange(of: geometry.size) { newSize in
                if pondSize == nil {
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
