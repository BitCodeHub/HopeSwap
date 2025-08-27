import SwiftUI

struct MarketplaceInsightsView: View {
    let item: Item
    @Environment(\.dismiss) var dismiss
    @State private var currentItem: Item?
    @State private var isLoading = true
    
    var displayItem: Item {
        currentItem ?? item
    }
    
    var body: some View {
        ZStack {
            Color.hopeDarkBg
                .ignoresSafeArea()
            
            if isLoading {
                // Loading state
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Loading insights...")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Marketplace insights")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Last 7 days")
                                .font(.title3)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button(action: { 
                                Task {
                                    isLoading = true
                                    await loadLatestAnalytics()
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: { dismiss() }) {
                                Image(systemName: "info.circle")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    .padding(.top)
                    
                    // Insights
                    VStack(spacing: 32) {
                    // Clicks on listing
                    InsightRow(
                        icon: "eye",
                        value: displayItem.clickCount,
                        label: "clicks on listing"
                    )
                    
                    // Video plays
                    InsightRow(
                        icon: "play.fill",
                        value: displayItem.videoPlays,
                        label: "3-second video plays"
                    )
                    
                    // Listing saves
                    InsightRow(
                        icon: "bookmark",
                        value: displayItem.saveCount,
                        label: "listing saves"
                    )
                    
                    // Listing shares
                    InsightRow(
                        icon: "square.and.arrow.up",
                        value: displayItem.shareCount,
                        label: "listing shares"
                    )
                }
                .padding(.horizontal)
                .padding(.top, 40)
                
                Spacer()
                
                // Close button
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.hopeBlue)
                        .cornerRadius(12)
                }
                .padding()
                .padding(.bottom)
                }
            }
        }
        .onAppear {
            Task {
                await loadLatestAnalytics()
            }
        }
    }
    
    private func loadLatestAnalytics() async {
        do {
            print("📊 Loading analytics for item: \(item.title) (ID: \(item.id.uuidString))")
            
            // Initialize analytics fields if they don't exist
            try await FirestoreManager.shared.initializeAnalyticsFields(itemId: item.id.uuidString)
            print("✅ Analytics fields initialized")
            
            // Fetch the latest item data
            if let latestItem = try await FirestoreManager.shared.fetchItem(itemId: item.id.uuidString) {
                print("📊 Fetched latest data - Clicks: \(latestItem.clickCount), Saves: \(latestItem.saveCount), Shares: \(latestItem.shareCount), Video Plays: \(latestItem.videoPlays)")
                await MainActor.run {
                    self.currentItem = latestItem
                    self.isLoading = false
                }
            } else {
                print("⚠️ Could not fetch item from Firestore, using local data")
                // If we can't fetch the item, just show the original
                await MainActor.run {
                    self.isLoading = false
                }
            }
        } catch {
            print("❌ Error loading analytics: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

struct InsightRow: View {
    let icon: String
    let value: Int
    let label: String
    
    var body: some View {
        HStack(spacing: 24) {
            // Icon in circle
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // Value and label
            HStack(spacing: 8) {
                Text("\(value)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
}