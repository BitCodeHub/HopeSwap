import SwiftUI

struct CategoryListingView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    let categoryTitle: String
    let listingTypes: [ListingType]?
    let filterByJustListed: Bool
    let locationFilter: String?
    
    @State private var selectedItem: Item? = nil
    
    // Initialize for specific listing type
    init(categoryTitle: String, listingType: ListingType, locationFilter: String? = nil) {
        self.categoryTitle = categoryTitle
        self.listingTypes = [listingType]
        self.filterByJustListed = false
        self.locationFilter = locationFilter
    }
    
    // Initialize for multiple listing types (like Find a Buddy)
    init(categoryTitle: String, listingTypes: [ListingType], locationFilter: String? = nil) {
        self.categoryTitle = categoryTitle
        self.listingTypes = listingTypes
        self.filterByJustListed = false
        self.locationFilter = locationFilter
    }
    
    // Initialize for special filters (like Newly listed)
    init(categoryTitle: String, filterByJustListed: Bool, locationFilter: String? = nil) {
        self.categoryTitle = categoryTitle
        self.listingTypes = nil
        self.filterByJustListed = filterByJustListed
        self.locationFilter = locationFilter
    }
    
    var filteredItems: [Item] {
        var items = dataManager.items
        
        // Apply location filter if present
        if let location = locationFilter, !location.isEmpty {
            let cityName = location.components(separatedBy: ",").first ?? ""
            if !cityName.isEmpty && !cityName.contains("Unknown ZIP") {
                items = items.filter { item in
                    item.location.lowercased().contains(cityName.lowercased())
                }
            }
        }
        
        // Apply category/type filters
        if filterByJustListed {
            return items.filter { $0.isJustListed }
        } else if let types = listingTypes {
            return items.filter { item in
                types.contains(item.listingType)
            }
        } else {
            return items
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