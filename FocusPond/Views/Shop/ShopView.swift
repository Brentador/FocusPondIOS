import SwiftUI

struct ShopView: View {
    var body: some View {
        ZStack {
            Color.green.opacity(0.2).edgesIgnoringSafeArea(.all)
            Text("Shop Screen")
                .font(.largeTitle)
                .foregroundColor(.green)
        }
    }
}
