//
//  ContentView.swift
//  HopeSwap
//
//  Created by Jimmy Lam on 8/16/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SwipeView()
                .tabItem {
                    Label("Browse", systemImage: "square.stack")
                }
                .tag(0)
            
            PostItemView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Post", systemImage: "plus.circle.fill")
                }
                .tag(1)
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.pink)
    }
}

#Preview {
    ContentView()
}
