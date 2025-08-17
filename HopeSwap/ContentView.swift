//
//  ContentView.swift
//  HopeSwap
//
//  Created by Jimmy Lam on 8/16/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingPostFlow = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SwipeView()
                .tabItem {
                    Label("Browse", systemImage: "square.stack")
                }
                .tag(0)
            
            Text("")
                .tabItem {
                    Label("Post", systemImage: "plus.circle.fill")
                }
                .tag(1)
                .onAppear {
                    if selectedTab == 1 {
                        showingPostFlow = true
                        selectedTab = 0
                    }
                }
            
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
        .fullScreenCover(isPresented: $showingPostFlow) {
            PostItemFlow(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    ContentView()
}
