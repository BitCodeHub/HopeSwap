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
            return dataManager.items.filter { types.contains($0.listingType) }
        } else {
            return dataManager.items
        }
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Items grid
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
            .background(Color.hopeDarkBg)
            .navigationTitle(categoryTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            ListingDetailView(item: item)
                .environmentObject(dataManager)
        }
    }
}