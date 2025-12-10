import SwiftUI

struct PondView: View {
    var body: some View {
        ZStack {
            Color.blue.opacity(0.2).edgesIgnoringSafeArea(.all)
            Text("Pond Screen")
                .font(.largeTitle)
                .foregroundColor(.blue)
        }
    }
}
