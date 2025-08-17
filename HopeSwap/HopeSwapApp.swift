//
//  HopeSwapApp.swift
//  HopeSwap
//
//  Created by Jimmy Lam on 8/16/25.
//

import SwiftUI

@main
struct HopeSwapApp: App {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}
