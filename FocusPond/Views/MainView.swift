import SwiftUI

struct MainView: View {
    let items: [NavigationItem] = [
        NavigationItem(title: "Pond", view: AnyView(PondView())),
        NavigationItem(title: "Shop", view: AnyView(ShopView())),
        NavigationItem(title: "Timer", view: AnyView(TimerView()))
    ]
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                NavigationStack {
                    item.view
                        .navigationTitle(item.title)
                }
                .tabItem {
                    Text(item.title)
                }
                .tag(index)
            }
        }
    }
}
