//
//  FocusPondApp.swift
//  FocusPond
//
//  Created by studentehb on 01/12/2025.
//

import SwiftUI

@main
struct FocusPondApp: App {
    init() {
        _ = CacheService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            if AuthService.shared.currentUser != nil {
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



