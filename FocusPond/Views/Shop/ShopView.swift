import SwiftUI

struct ShopView: View {
    @ObservedObject var fishManager = FishManager.shared
    @State private var purchaseMessage: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            // Top row: title + currency
            HStack {
                Text("Shop")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Text("\(fishManager.currency) coins")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)

            // Purchase message
            if let message = purchaseMessage {
                Text(message)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(message.contains("Not enough") ? Color.red.opacity(0.3) : Color.green.opacity(0.3))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(FishData.fishList) { fish in
                        // Move these out of the view builder
                        let isOwned = fishManager.ownedFish.contains(where: { $0.id == fish.id })
                        let canAfford = fishManager.currency >= fish.cost
                        let buttonDisabled = isOwned || !canAfford
                        let buttonText: String = {
                            if isOwned { return "Owned" }
                            if !canAfford { return "Can't Afford" }
                            return "Buy"
                        }()

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fish.name)
                                    .font(.headline)
                                Text(fish.cost == 0 ? "FREE" : "\(fish.cost) coins")
                                    .foregroundColor(canAfford || fish.cost == 0 ? .blue : .red)
                                Text("\(fish.totalTimeNeeded) min to grow")
                                    .font(.caption)
                            }

                            Spacer()

                            Button(action: {
                                guard !isOwned else { return }

                                if fishManager.deductCurrency(amount: fish.cost) {
                                    fishManager.addFishToInventory(fishId: fish.id)
                                    purchaseMessage = "You bought a \(fish.name)!"
                                } else {
                                    purchaseMessage = "Not enough coins! Need \(fish.cost) coins."
                                }

                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    purchaseMessage = nil
                                }
                            }) {
                                Text(buttonText)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(buttonDisabled ? Color.gray.opacity(0.5) : Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .disabled(buttonDisabled)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.top)
        .background(Color.green.opacity(0.1).edgesIgnoringSafeArea(.all))
    }
}
