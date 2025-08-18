//
//  ContentView.swift
//  HopeSwap
//
//  Created by Jimmy Lam on 8/16/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingPostOptions = false
    @State private var selectedPostType: PostType? = nil
    
    enum PostType: Identifiable {
        case itemForSale
        case itemForTrade
        case freebies
        case needHelp
        case events
        
        var id: String {
            switch self {
            case .itemForSale: return "itemForSale"
            case .itemForTrade: return "itemForTrade"
            case .freebies: return "freebies"
            case .needHelp: return "needHelp"
            case .events: return "events"
            }
        }
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                DiscoverView()
                    .tabItem {
                        Label("Discover", systemImage: "magnifyingglass")
                    }
                    .tag(0)
                
                SwipeView()
                    .tabItem {
                        Label("Browse", systemImage: "square.stack")
                    }
                    .tag(1)
                
                Text("")
                    .tabItem {
                        Label("Post", systemImage: "plus.circle.fill")
                    }
                    .tag(2)
                    .onAppear {
                        if selectedTab == 2 {
                            showingPostOptions = true
                            selectedTab = 0
                        }
                    }
                
                FavoritesView()
                    .tabItem {
                        Label("Favorites", systemImage: "heart.fill")
                    }
                    .tag(3)
                
                DonationView()
                    .tabItem {
                        Label("Donation", systemImage: "gift.fill")
                    }
                    .tag(4)
                
                ProfileView()
                    .tabItem {
                        Label("Me", systemImage: "person.fill")
                    }
                    .tag(5)
            }
            .accentColor(Color.hopeOrange)
        }
        .sheet(isPresented: $showingPostOptions) {
            PostOptionsSheet(
                selectedPostType: $selectedPostType,
                showingPostOptions: $showingPostOptions
            )
            .presentationDetents([.height(400)])
            .presentationDragIndicator(.visible)
            .presentationBackground(.black.opacity(0.9))
        }
        .fullScreenCover(item: $selectedPostType) { postType in
            if postType == .itemForSale || postType == .itemForTrade {
                PostItemFlow(
                    selectedTab: $selectedTab,
                    isTradeItem: postType == .itemForTrade
                )
                .environmentObject(DataManager.shared)
            }
        }
    }
}

#Preview {
    ContentView()
}
