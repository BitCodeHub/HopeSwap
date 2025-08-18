import SwiftUI

struct ListingDetailView: View {
    let item: Item
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedImageIndex = 0
    @State private var showingAllImages = false
    
    var priceText: String {
        if let price = item.price {
            return price == 0 ? "Free" : "$\(String(format: "%.2f", price))"
        } else {
            return "Trade Item"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Image carousel
                        if !item.images.isEmpty {
                            TabView(selection: $selectedImageIndex) {
                                ForEach(Array(item.images.enumerated()), id: \.offset) { index, imageUrl in
                                    AsyncImage(url: URL(string: imageUrl)) { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 400)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(height: 400)
                                            .overlay(
                                                ProgressView()
                                            )
                                    }
                                    .tag(index)
                                }
                            }
                            .frame(height: 400)
                            .tabViewStyle(PageTabViewStyle())
                            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 400)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            // Price and title
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(priceText)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    if item.priceIsFirm && item.price != nil {
                                        Text("FIRM")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.hopeBlue)
                                            )
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        dataManager.toggleFavorite(item.id)
                                    }) {
                                        Image(systemName: dataManager.favorites.contains(item.id) ? "heart.fill" : "heart")
                                            .font(.title2)
                                            .foregroundColor(Color.hopePink)
                                    }
                                }
                                
                                Text(item.title)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            
                            // Location and time
                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Image(systemName: "location")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(item.location)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(timeAgoString(from: item.postedDate))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            // Details section
                            VStack(alignment: .leading, spacing: 12) {
                                DetailRow(label: "Category", value: item.category.rawValue, color: categoryColor(for: item.category))
                                DetailRow(label: "Condition", value: item.condition.rawValue, color: conditionColor(for: item.condition))
                                
                                if !item.description.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Description")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(item.description)
                                            .font(.body)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                // Trade preferences if applicable
                                if item.isTradeItem {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Trade Preferences")
                                            .font(.headline)
                                            .foregroundColor(Color.hopeGreen)
                                        
                                        if let lookingFor = item.lookingFor, !lookingFor.isEmpty {
                                            TradePreferenceRow(icon: "magnifyingglass", label: "Looking for", value: lookingFor)
                                        }
                                        
                                        if let acceptableItems = item.acceptableItems, !acceptableItems.isEmpty {
                                            TradePreferenceRow(icon: "checkmark.circle", label: "Will accept", value: acceptableItems)
                                        }
                                        
                                        if let tradeSuggestions = item.tradeSuggestions, !tradeSuggestions.isEmpty {
                                            TradePreferenceRow(icon: "lightbulb", label: "Trade ideas", value: tradeSuggestions)
                                        }
                                        
                                        if item.openToOffers {
                                            HStack {
                                                Image(systemName: "hands.sparkles")
                                                    .foregroundColor(Color.hopeGreen)
                                                Text("Open to all offers")
                                                    .font(.subheadline)
                                                    .foregroundColor(.white)
                                            }
                                            .padding(12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.hopeGreen.opacity(0.1))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.hopeGreen.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                        }
                                    }
                                }
                            }
                            
                            // Action buttons
                            HStack(spacing: 12) {
                                if item.isTradeItem {
                                    Button(action: {}) {
                                        Label("Make Offer", systemImage: "arrow.left.arrow.right")
                                            .font(.headline)
                                            .foregroundColor(Color.hopeDarkBg)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.hopeGreen)
                                            .cornerRadius(12)
                                    }
                                } else {
                                    Button(action: {}) {
                                        Label("Buy Now", systemImage: "cart.fill")
                                            .font(.headline)
                                            .foregroundColor(Color.hopeDarkBg)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.hopeOrange)
                                            .cornerRadius(12)
                                    }
                                }
                                
                                Button(action: {}) {
                                    Image(systemName: "message.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 60, height: 50)
                                        .background(Color.hopeBlue)
                                        .cornerRadius(12)
                                }
                            }
                            
                            // Donation info
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "heart.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(Color.hopePink)
                                    Text("100% of proceeds support pediatric cancer research")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.hopePink.opacity(0.1))
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    func timeAgoString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
    
    func categoryColor(for category: Category) -> Color {
        switch category {
        case .electronics: return Color.hopeBlue
        case .clothing: return Color.hopePink
        case .books: return Color.hopePurple
        case .toys: return Color.hopeOrange
        case .home: return Color.hopeGreen
        case .sports: return Color.hopeTeal
        case .other: return Color.hopeYellow
        }
    }
    
    func conditionColor(for condition: Condition) -> Color {
        switch condition {
        case .new: return Color.hopeGreen
        case .likeNew: return Color.hopeBlue
        case .good: return Color.hopeOrange
        case .fair: return Color.hopeYellow
        case .poor: return Color.hopeError
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct TradePreferenceRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Color.hopeGreen)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}