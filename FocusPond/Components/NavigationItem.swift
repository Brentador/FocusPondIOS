import SwiftUI

struct NavigationItem: Identifiable {
    let id = UUID()
    let title: String
    let view: AnyView
}
