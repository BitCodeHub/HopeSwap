import SwiftUI

struct CategoryListingView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    let categoryTitle: String
    let listingTypes: [ListingType]?
    let filterByJustListed: Bool
    
    @State private var selectedItem: Item? = nil
    
    // Initialize for specific listing type
    init(categoryTitle: String, listingType: ListingType) {
        self.categoryTitle = categoryTitle
        self.listingTypes = [listingType]
        self.filterByJustListed = false
    }
    
    // Initialize for multiple listing types (like Find a Buddy)
    init(categoryTitle: String, listingTypes: [ListingType]) {
        self.categoryTitle = categoryTitle
        self.listingTypes = listingTypes
        self.filterByJustListed = false
    }
    
    // Initialize for special filters (like Newly listed)
    init(categoryTitle: String, filterByJustListed: Bool) {
        self.categoryTitle = categoryTitle
        self.listingTypes = nil
        self.filterByJustListed = filterByJustListed
    }
    
    var filteredItems: [Item] {
        if filterByJustListed {
            return dataManager.items.filter { $0.isJustListed }
        } else if let types = listingTypes {
            return dataManager.items.filter { item in
                types.contains(item.listingType)
            }
        } else {
            return dataManager.items
        }
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            Color.hopeDarkBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(categoryTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("\(filteredItems.count) items")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.2))
                    )
                }
                .padding()
                .padding(.top, 50)
                
                // Items grid
                if filteredItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No items found")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("Try adjusting your filters")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredItems) { item in
                                DiscoverItemCard(item: item, isCompact: false)
                                    .onTapGesture {
                                        selectedItem = item
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $selectedItem) { item in
            ListingDetailView(item: item)
                .environmentObject(dataManager)
        }
    }
}