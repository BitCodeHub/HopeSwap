import SwiftUI
import CoreLocation

struct DiscoverView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var locationManager = LocationManager()
    @State private var selectedTab = "For you"
    @State private var selectedItem: Item? = nil
    @State private var showLocationPicker = false
    @State private var zipCode = ""
    @State private var filteredItems: [Item] = []
    @State private var searchedLocation = ""
    @State private var showCategorySelection = false
    @State private var selectedCategory: Category? = nil
    @State private var searchText = ""
    @State private var showSearchBar = false
    @State private var isRefreshing = false
    @State private var showRefreshTutorial = false
    @State private var contentOffset: CGFloat = 0
    @State private var showRefreshIndicator = false
    @State private var tutorialText = ""
    
    let tabs = ["Sell", "For you", "Local", "More"]
    
    var displayedItems: [Item] {
        // If no filters are applied, show all items
        if searchText.isEmpty && selectedCategory == nil && locationManager.isUsingCurrentLocation && searchedLocation.isEmpty {
            return dataManager.items
        }
        // Otherwise show filtered items
        return filteredItems
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
                
                VStack(spacing: 0) {
                    // Custom header
                    VStack(spacing: 16) {
                        // Top bar with tabs and search
                        HStack(spacing: 0) {
                            // Tab selector on the left
                            HStack(spacing: 0) {
                                ForEach(tabs, id: \.self) { tab in
                                    TabButton(
                                        title: tab,
                                        isSelected: selectedTab == tab,
                                        showChevron: tab == "More",
                                        action: { 
                                            selectedTab = tab
                                            if tab == "More" {
                                                showCategorySelection = true
                                            }
                                        }
                                    )
                                }
                            }
                            
                            Spacer()
                            
                            // Search icon on the right
                            Button(action: { 
                                withAnimation {
                                    showSearchBar.toggle()
                                    if !showSearchBar {
                                        searchText = ""
                                        filterItems()
                                    }
                                }
                            }) {
                                Image(systemName: showSearchBar ? "xmark" : "magnifyingglass")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Search bar (when visible)
                        if showSearchBar {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .font(.body)
                                
                                TextField("", text: $searchText)
                                    .placeholder(when: searchText.isEmpty) {
                                        Text("Search for items...")
                                            .foregroundColor(.gray)
                                    }
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .onChange(of: searchText) {
                                        filterItems()
                                    }
                                    .onSubmit {
                                        filterItems()
                                    }
                                
                                if !searchText.isEmpty {
                                    Button(action: { 
                                        searchText = ""
                                        filterItems()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .font(.body)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Title and location
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Today's picks")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: { showLocationPicker = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "location.fill")
                                            .font(.caption)
                                        Text(locationManager.locationString)
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(Color.hopeOrange)
                                }
                            }
                            
                            // Filter indicators
                            VStack(alignment: .leading, spacing: 4) {
                                if let category = selectedCategory {
                                    HStack {
                                        Text("Filtered by: \(category.rawValue)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        
                                        Button(action: { 
                                            selectedCategory = nil
                                            filterItems()
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                
                                if !searchText.isEmpty {
                                    HStack {
                                        Text("Searching: \"\(searchText)\"")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        
                                        Text("(\(filteredItems.count) results)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    .padding(.bottom, 16)
                    
                    // Grid of items
                    ZStack(alignment: .top) {
                        // Refresh indicator
                        if showRefreshIndicator || !tutorialText.isEmpty {
                            VStack(spacing: 8) {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color.hopeOrange))
                                        .scaleEffect(1.2)
                                    Text(tutorialText.isEmpty ? "Refreshing..." : tutorialText)
                                        .font(.subheadline)
                                        .foregroundColor(tutorialText.isEmpty ? .gray : .white)
                                        .fontWeight(tutorialText.isEmpty ? .regular : .medium)
                                }
                                
                                if !tutorialText.isEmpty {
                                    Text("Try it yourself!")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.top, 20)
                            .opacity(showRefreshIndicator || !tutorialText.isEmpty ? 1 : 0)
                            .animation(.easeInOut(duration: 0.3), value: showRefreshIndicator)
                            .animation(.easeInOut(duration: 0.3), value: tutorialText)
                        }
                        
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(displayedItems) { item in
                                    DiscoverItemCard(item: item)
                                        .onTapGesture {
                                            selectedItem = item
                                        }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                        .refreshable {
                            await refreshItems()
                        }
                    }
                }
                .offset(y: contentOffset)
            }
            .navigationBarHidden(true)
            .onAppear {
                // Always request current location
                locationManager.requestLocation()
                
                // Check if there's a saved zip code
                if let savedZip = UserDefaults.standard.string(forKey: "lastSearchedZipCode"),
                   let savedCity = UserDefaults.standard.string(forKey: "lastSearchedCity") {
                    zipCode = savedZip
                    searchedLocation = savedCity
                    locationManager.locationString = savedCity
                    locationManager.isUsingCurrentLocation = false
                    filterItemsByLocation(savedCity)
                } else {
                    // Initialize filteredItems with all items if no saved location
                    filteredItems = dataManager.items
                }
                
                // Always show tutorial on app load
                showRefreshTutorial = true
                startTutorialAnimation()
            }
            .onChange(of: dataManager.items) { _, _ in
                filterItems()
            }
        }
        .sheet(item: $selectedItem) { item in
            ListingDetailView(item: item)
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(
                zipCode: $zipCode,
                currentUserLocation: locationManager.currentUserLocation,
                searchedLocation: $searchedLocation,
                isUsingCurrentLocation: $locationManager.isUsingCurrentLocation,
                onLocationUpdate: { zip in
                    if !zip.isEmpty {
                        updateLocationFromZipCode(zip)
                    } else {
                        // City was selected without zip code
                        locationManager.isUsingCurrentLocation = false
                        locationManager.locationString = searchedLocation
                        filterItemsByLocation(searchedLocation)
                        
                        // Save the city for persistence
                        UserDefaults.standard.removeObject(forKey: "lastSearchedZipCode")
                        UserDefaults.standard.set(searchedLocation, forKey: "lastSearchedCity")
                    }
                },
                onLocateMe: {
                    switchToCurrentLocation()
                }
            )
        }
        .sheet(isPresented: $showCategorySelection) {
            CategorySelectionView(selectedCategory: $selectedCategory)
                .onDisappear {
                    filterItems()
                }
        }
    }
    
    private func updateLocationFromZipCode(_ zip: String) {
        if !zip.isEmpty && zip.count == 5 {
            // Use centralized ZipCodeManager
            if let city = ZipCodeManager.shared.getCityForZipCode(zip) {
                // Update the location string
                searchedLocation = city
                locationManager.locationString = city
                locationManager.isUsingCurrentLocation = false
                zipCode = zip
                
                // Filter items based on location
                filterItemsByLocation(city)
                
                // Store the searched zip code for persistence
                UserDefaults.standard.set(zip, forKey: "lastSearchedZipCode")
                UserDefaults.standard.set(city, forKey: "lastSearchedCity")
            } else if let estimatedLocation = ZipCodeManager.shared.estimateLocationForZipCode(zip) {
                // For unknown but valid zip codes, show estimated location
                searchedLocation = estimatedLocation
                locationManager.locationString = estimatedLocation
                locationManager.isUsingCurrentLocation = false
                zipCode = zip
                
                // Show all items for estimated locations
                filteredItems = []
                
                UserDefaults.standard.set(zip, forKey: "lastSearchedZipCode")
                UserDefaults.standard.set(estimatedLocation, forKey: "lastSearchedCity")
            } else {
                // For completely unknown zip codes
                searchedLocation = "Unknown ZIP: \(zip)"
                locationManager.locationString = "Unknown ZIP: \(zip)"
                locationManager.isUsingCurrentLocation = false
                zipCode = zip
                
                // Show all items for unknown zip codes
                filteredItems = []
                
                UserDefaults.standard.set(zip, forKey: "lastSearchedZipCode")
                UserDefaults.standard.removeObject(forKey: "lastSearchedCity")
            }
        }
    }
    
    private func filterItemsByLocation(_ city: String) {
        filterItems()
    }
    
    private func filterItems() {
        var items = dataManager.items
        
        // Filter by location if not using current location or if there's a searched location
        if !locationManager.isUsingCurrentLocation || !searchedLocation.isEmpty {
            let cityName = (searchedLocation.isEmpty ? locationManager.locationString : searchedLocation)
                .components(separatedBy: ",").first ?? ""
            if !cityName.isEmpty && !cityName.contains("Unknown ZIP") {
                items = items.filter { item in
                    item.location.lowercased().contains(cityName.lowercased())
                }
            }
        }
        
        // Filter by category if one is selected
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        
        // Filter by search text if provided
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            items = items.filter { item in
                item.title.lowercased().contains(searchLower) ||
                item.description.lowercased().contains(searchLower) ||
                item.category.rawValue.lowercased().contains(searchLower)
            }
        }
        
        filteredItems = items
    }
    
    private func switchToCurrentLocation() {
        locationManager.isUsingCurrentLocation = true
        locationManager.locationString = locationManager.currentUserLocation
        searchedLocation = ""
        filterItems()
        
        // Clear saved search
        UserDefaults.standard.removeObject(forKey: "lastSearchedZipCode")
        UserDefaults.standard.removeObject(forKey: "lastSearchedCity")
    }
    
    private func refreshItems() async {
        // Add a small delay for better UX
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Randomly shuffle the current items while maintaining filters
        await MainActor.run {
            if searchText.isEmpty && selectedCategory == nil && locationManager.isUsingCurrentLocation && searchedLocation.isEmpty {
                // If no filters, shuffle all items
                dataManager.items.shuffle()
            } else {
                // If filters are applied, shuffle the filtered items
                filteredItems.shuffle()
            }
        }
    }
    
    private func startTutorialAnimation() {
        // Longer delay to ensure content is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Set tutorial text
            tutorialText = "Pull down to refresh"
            
            // First pull down animation
            withAnimation(.easeOut(duration: 1.5)) {
                contentOffset = 150
                showRefreshIndicator = true
            }
            
            // Hold for a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // Spring back up
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
                    contentOffset = 0
                }
                
                // Wait and repeat once more
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    // Second pull down
                    withAnimation(.easeOut(duration: 1.5)) {
                        contentOffset = 150
                    }
                    
                    // Hold and spring back
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
                            contentOffset = 0
                        }
                        
                        // Clear tutorial text after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                tutorialText = ""
                                showRefreshIndicator = false
                            }
                        }
                        
                        // Mark tutorial as complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showRefreshTutorial = false
                        }
                    }
                }
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    var showChevron: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                
                if showChevron {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                }
            }
            .padding(.horizontal, title == "For you" ? 14 : 16)
            .padding(.vertical, 10)
            .fixedSize(horizontal: true, vertical: false)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(tabColor(for: title))
                    }
                }
            )
        }
    }
    
    func tabColor(for title: String) -> Color {
        switch title {
        case "Sell":
            return Color.hopeOrange
        case "For you":
            return Color.hopeBlue
        case "Local":
            return Color.hopeGreen
        case "More":
            return Color.hopePurple
        default:
            return Color.hopeBlue
        }
    }
}

struct DiscoverItemCard: View {
    let item: Item
    
    var priceText: String {
        if let price = item.price {
            return price == 0 ? "Free" : "$\(Int(price))"
        } else {
            return "Trade"
        }
    }
    
    var imagePlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 200)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with overlay badges
            ZStack(alignment: .topLeading) {
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
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .frame(height: 200)
                            } else {
                                imagePlaceholder
                            }
                        } else {
                            // Handle URL images
                            AsyncImage(url: URL(string: firstImage)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .frame(height: 200)
                            } placeholder: {
                                imagePlaceholder
                            }
                        }
                    } else {
                        imagePlaceholder
                    }
                }
                .clipped()
                
                // Badges
                VStack(alignment: .leading, spacing: 4) {
                    if item.isJustListed {
                        Badge(text: "Just listed", backgroundColor: .white, textColor: .black)
                    }
                    if item.isNearby {
                        Badge(text: "Nearby", backgroundColor: .white, textColor: .black)
                    }
                }
                .padding(6)
            }
            .frame(height: 200)
            .clipped()
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(priceText)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if item.price == 0 || item.price == nil {
                        Text("•")
                            .foregroundColor(.gray)
                    }
                }
                
                Text(item.title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.hopeDarkSecondary)
        }
        .background(Color.hopeDarkSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct Badge: View {
    let text: String
    let backgroundColor: Color
    let textColor: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(textColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(backgroundColor)
            )
    }
}
