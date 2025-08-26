import SwiftUI

struct MarketplaceInsightsView: View {
    let item: Item
    @Environment(\.dismiss) var dismiss
    
    // Mock data for insights - in a real app, these would come from analytics
    @State private var clickCount = 0
    @State private var videoPlays = 0
    @State private var saveCount = 0
    @State private var shareCount = 0
    
    var body: some View {
        ZStack {
            Color.hopeDarkBg
                .ignoresSafeArea()
            
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
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .padding(.top)
                
                // Insights
                VStack(spacing: 32) {
                    // Clicks on listing
                    InsightRow(
                        icon: "eye",
                        value: clickCount,
                        label: "clicks on listing"
                    )
                    
                    // Video plays
                    InsightRow(
                        icon: "play.fill",
                        value: videoPlays,
                        label: "3-second video plays"
                    )
                    
                    // Listing saves
                    InsightRow(
                        icon: "bookmark",
                        value: saveCount,
                        label: "listing saves"
                    )
                    
                    // Listing shares
                    InsightRow(
                        icon: "square.and.arrow.up",
                        value: shareCount,
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