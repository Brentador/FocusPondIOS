//
//  FocusPondApp.swift
//  FocusPond
//
//  Created by studentehb on 01/12/2025.
//

import SwiftUI

@main
struct FocusPondApp: App {
    @StateObject private var authService = AuthService.shared
    
    init() {
        _ = CacheService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            if authService.currentUser != nil {
                MainView()
                    .toolbar {
                        Button("Logout") {
                            AuthService.shared.logout()
                        }
                    }
            } else {
                NavigationView {
                    LoginView()
                }
            }
        }
    }
}



