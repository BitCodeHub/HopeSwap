//
//  HopeSwapApp.swift
//  HopeSwap
//
//  Created by Jimmy Lam on 8/16/25.
//

import SwiftUI
import Firebase

@main
struct HopeSwapApp: App {
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        setupAppearance()
    }
    
    private func setupAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.039, green: 0.098, blue: 0.161, alpha: 1.0) // hopeDarkBg color
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0) // hopeOrange color
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(red: 0.039, green: 0.098, blue: 0.161, alpha: 1.0) // hopeDarkBg color
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0) // hopeOrange color
    }
    
    var body: some Scene {
        WindowGroup {
            SimpleLaunchView()
                .preferredColorScheme(.dark)
        }
    }
}
