import SwiftUI

struct MainView: View {
    let items: [NavigationItem] = [
        NavigationItem(title: "Pond", view: AnyView(PondView())),
        NavigationItem(title: "Shop", view: AnyView(ShopView())),
        NavigationItem(title: "Timer", view: AnyView(TimerView()))
    ]
    
    @State private var selectedTab = 0
    @State private var showingLogoutAlert = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                NavigationStack {
                    item.view
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    showingLogoutAlert = true
                                } label: {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                }
                            }
                        }
                }
                .tabItem {
                    Text(item.title)
                }
                .tag(index)
            }
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                AuthService.shared.logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}
