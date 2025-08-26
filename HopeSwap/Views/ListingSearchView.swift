import SwiftUI

struct ListingSearchView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var searchResults: [Item] = []
    @State private var selectedItem: Item? = nil
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("", text: $searchText)
                            .placeholder(when: searchText.isEmpty) {
                                Text("Search listings...")
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: searchText) { _ in
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: { 
                                searchText = ""
                                searchResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding()
                    
                    // Results
                    if searchResults.isEmpty && !searchText.isEmpty {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No results found")
                                .font(.title3)
                                .foregroundColor(.gray)
                            
                            Text("Try different keywords")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        
                        Spacer()
                    } else if !searchResults.isEmpty {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(searchResults) { item in
                                    DiscoverItemCard(item: item, isCompact: false)
                                        .onTapGesture {
                                            selectedItem = item
                                        }
                                }
                            }
                            .padding()
                            .padding(.bottom, 100)
                        }
                    } else if searchText.isEmpty {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("Search for listings")
                                .font(.title3)
                                .foregroundColor(.gray)
                            
                            Text("Enter keywords to find items")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Search")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.hopeBlue)
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            ListingDetailView(item: item)
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        let searchLower = searchText.lowercased()
        searchResults = dataManager.items.filter { item in
            item.title.lowercased().contains(searchLower) ||
            item.description.lowercased().contains(searchLower) ||
            item.category.rawValue.lowercased().contains(searchLower) ||
            item.location.lowercased().contains(searchLower)
        }
    }
}