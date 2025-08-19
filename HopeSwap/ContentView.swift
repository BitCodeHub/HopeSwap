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
        case carpool
        case workoutBuddy
        case walkingBuddy
        case lunchBuddy
        
        var id: String {
            switch self {
            case .itemForSale: return "itemForSale"
            case .itemForTrade: return "itemForTrade"
            case .freebies: return "freebies"
            case .needHelp: return "needHelp"
            case .events: return "events"
            case .carpool: return "carpool"
            case .workoutBuddy: return "workoutBuddy"
            case .walkingBuddy: return "walkingBuddy"
            case .lunchBuddy: return "lunchBuddy"
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
                
                // Placeholder view for Post tab
                ZStack {
                    Color.hopeDarkBg
                        .ignoresSafeArea()
                    
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color.hopeOrange)
                        Text("Post an Item")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .tabItem {
                    Label("Post", systemImage: "plus.circle.fill")
                }
                .tag(2)
                
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
            .onChange(of: selectedTab) { _, newValue in
                if newValue == 2 {
                    // Show post options when Post tab is selected
                    showingPostOptions = true
                    // Reset to previous tab to prevent showing the placeholder
                    DispatchQueue.main.async {
                        selectedTab = 0
                    }
                }
            }
        }
        .sheet(isPresented: $showingPostOptions) {
            PostOptionsSheet(
                selectedPostType: $selectedPostType,
                showingPostOptions: $showingPostOptions
            )
            .presentationDetents([.height(550)])
            .presentationDragIndicator(.visible)
            .presentationBackground(.black.opacity(0.9))
        }
        .fullScreenCover(item: $selectedPostType) { postType in
            switch postType {
            case .itemForSale, .itemForTrade:
                PostItemFlow(
                    selectedTab: $selectedTab,
                    isTradeItem: postType == .itemForTrade
                )
                .environmentObject(DataManager.shared)
            case .freebies:
                FreebiesFlow(selectedTab: $selectedTab)
                    .environmentObject(DataManager.shared)
            case .needHelp:
                NeedHelpFlow(selectedTab: $selectedTab)
                    .environmentObject(DataManager.shared)
            default:
                EmptyView()
            }
        }
    }
}

#Preview {
    ContentView()
}
