import SwiftUI

struct MyListingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedItem: Item? = nil
    @State private var showDeleteAlert = false
    @State private var itemToDelete: Item? = nil
    
    var userListings: [Item] {
        dataManager.getCurrentUserItems()
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                if userListings.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "tag.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No listings yet")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Start listing items to help your community")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { dismiss() }) {
                            Text("Post Your First Item")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.hopeBlue)
                                .cornerRadius(12)
                        }
                        .padding(.top)
                    }
                    .padding()
                } else {
                    // Listings grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(userListings) { item in
                                MyListingCard(item: item)
                                    .onTapGesture {
                                        selectedItem = item
                                    }
                                    .contextMenu {
                                        Button(action: {}) {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        
                                        Button(action: {}) {
                                            Label("Mark as Sold", systemImage: "checkmark.circle")
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            itemToDelete = item
                                            showDeleteAlert = true
                                        }) {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("My Listings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(userListings.count) items")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            ListingDetailView(item: item)
        }
        .alert("Delete Listing", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    Task {
                        await dataManager.deleteItem(item)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this listing? This action cannot be undone.")
        }
    }
}

struct MyListingCard: View {
    let item: Item
    
    var priceText: String {
        if let price = item.price {
            return price == 0 ? "Free" : "$\(Int(price))"
        } else {
            return "Trade"
        }
    }
    
    var statusColor: Color {
        switch item.status {
        case .available:
            return Color.hopeGreen
        case .pending:
            return Color.hopeOrange
        case .traded, .sold:
            return Color.gray
        }
    }
    
    var imagePlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image with status overlay
            GeometryReader { geometry in
                ZStack {
                    // Background image
                    Group {
                        if let firstImage = item.images.first {
                            if firstImage.starts(with: "data:image") {
                                // Handle base64 images
                                if let data = Data(base64Encoded: String(firstImage.dropFirst("data:image/jpeg;base64,".count))),
                                   let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width, height: geometry.size.width)
                                } else {
                                    imagePlaceholder
                                        .frame(width: geometry.size.width, height: geometry.size.width)
                                }
                            } else {
                                // Handle URL images
                                AsyncImage(url: URL(string: firstImage)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width, height: geometry.size.width)
                                } placeholder: {
                                    imagePlaceholder
                                        .frame(width: geometry.size.width, height: geometry.size.width)
                                }
                            }
                        } else {
                            imagePlaceholder
                                .frame(width: geometry.size.width, height: geometry.size.width)
                        }
                    }
                    .clipped()
                    
                    // Status badge overlay
                    VStack {
                        HStack {
                            Spacer()
                            Text(item.status.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor)
                                .cornerRadius(8)
                                .padding(8)
                        }
                        Spacer()
                    }
                    
                    // Listing type badge
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: item.listingType.icon)
                                    .font(.caption2)
                                Text(item.listingType.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(item.listingType.color.opacity(0.9))
                            )
                            .padding(8)
                            Spacer()
                        }
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipped()
            .cornerRadius(12)
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(priceText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Views count
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                            .font(.caption2)
                        Text("\(Int.random(in: 10...200))")
                            .font(.caption2)
                    }
                    .foregroundColor(.gray)
                }
                
                Text(item.title)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                // Posted date
                Text(timeAgoString(from: item.postedDate))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    func timeAgoString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "Posted \(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "Posted \(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "Posted \(minutes)m ago"
        } else {
            return "Posted just now"
        }
    }
}