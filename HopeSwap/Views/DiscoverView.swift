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
    @State private var tutorialBackgroundOpacity: Double = 0
    @State private var showCategoryListing = false
    @State private var selectedCategoryTitle = ""
    @State private var selectedListingTypes: [ListingType]? = nil
    @State private var filterByJustListed = false
    @State private var searchRadius: Double = 15
    
    let tabs = ["Sell", "For you", "Local", "More"]
    
    var displayedItems: [Item] {
        // If no filters are applied, show all items
        if searchText.isEmpty && selectedCategory == nil && locationManager.isUsingCurrentLocation && searchedLocation.isEmpty {
            print("DiscoverView: Showing all items, count: \(dataManager.items.count)")
            return dataManager.items
        }
        // Otherwise show filtered items
        print("DiscoverView: Showing filtered items, count: \(filteredItems.count)")
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
                                    HStack(spacing: 6) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 14))
                                        Text(locationManager.locationString)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
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
                    
                    // Tutorial text that appears when grid is pulled down
                    VStack(spacing: 8) {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.hopeOrange))
                                .scaleEffect(1.2)
                            Text(tutorialText.isEmpty ? " " : tutorialText)
                                .font(.headline)
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                        }
                        
                        if !tutorialText.isEmpty {
                            Text("Try it yourself!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: tutorialText.isEmpty ? 0 : nil)
                    .padding(.vertical, tutorialText.isEmpty ? 0 : 20)
                    .opacity(tutorialText.isEmpty ? 0 : 1)
                    .animation(.easeInOut(duration: 0.4), value: tutorialText)
                    
                    // Grid of items
                    ZStack(alignment: .top) {
                        // Refresh indicator for actual refresh
                        if showRefreshIndicator && tutorialText.isEmpty {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.hopeOrange))
                                    .scaleEffect(1.2)
                                Text("Refreshing...")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 20)
                            .opacity(showRefreshIndicator ? 1 : 0)
                            .animation(.easeInOut(duration: 0.3), value: showRefreshIndicator)
                        }
                        
                        ScrollView {
                            VStack(spacing: 32) {
                                // Show category sections if no filters applied
                                if searchText.isEmpty && selectedCategory == nil {
                                    // Newly listed section
                                    CategorySection(
                                        title: "Newly listed",
                                        items: displayedItems.filter { $0.isJustListed }.prefix(4).map { $0 },
                                        selectedItem: $selectedItem,
                                        onSeeAll: { 
                                            selectedCategoryTitle = "Newly listed"
                                            selectedListingTypes = nil
                                            filterByJustListed = true
                                            showCategoryListing = true
                                        }
                                    )
                                    
                                    // Sell section
                                    CategorySection(
                                        title: "Sell",
                                        items: displayedItems.filter { $0.listingType == .sell }.prefix(4).map { $0 },
                                        selectedItem: $selectedItem,
                                        onSeeAll: { 
                                            selectedCategoryTitle = "Sell"
                                            selectedListingTypes = [.sell]
                                            filterByJustListed = false
                                            showCategoryListing = true
                                        }
                                    )
                                    
                                    // Trade section
                                    CategorySection(
                                        title: "Trade",
                                        items: displayedItems.filter { $0.listingType == .trade }.prefix(4).map { $0 },
                                        selectedItem: $selectedItem,
                                        onSeeAll: { 
                                            selectedCategoryTitle = "Trade"
                                            selectedListingTypes = [.trade]
                                            filterByJustListed = false
                                            showCategoryListing = true
                                        }
                                    )
                                    
                                    // Give Away section
                                    CategorySection(
                                        title: "Give Away",
                                        items: displayedItems.filter { $0.listingType == .giveAway }.prefix(4).map { $0 },
                                        selectedItem: $selectedItem,
                                        onSeeAll: { 
                                            selectedCategoryTitle = "Give Away"
                                            selectedListingTypes = [.giveAway]
                                            filterByJustListed = false
                                            showCategoryListing = true
                                        }
                                    )
                                    
                                    // Need Help section
                                    CategorySection(
                                        title: "Need Help",
                                        items: displayedItems.filter { $0.listingType == .needHelp }.prefix(4).map { $0 },
                                        selectedItem: $selectedItem,
                                        onSeeAll: { 
                                            selectedCategoryTitle = "Need Help"
                                            selectedListingTypes = [.needHelp]
                                            filterByJustListed = false
                                            showCategoryListing = true
                                        }
                                    )
                                    
                                    // Events section
                                    CategorySection(
                                        title: "Events",
                                        items: displayedItems.filter { $0.listingType == .event }.prefix(4).map { $0 },
                                        selectedItem: $selectedItem,
                                        onSeeAll: { 
                                            selectedCategoryTitle = "Events"
                                            selectedListingTypes = [.event]
                                            filterByJustListed = false
                                            showCategoryListing = true
                                        }
                                    )
                                    
                                    // Buddy sections combined
                                    CategorySection(
                                        title: "Find a Buddy",
                                        subtitle: "Carpool, Lunch, Walking & Workout",
                                        items: displayedItems.filter { 
                                            [.carpool, .lunchBuddy, .walkingBuddy, .workoutBuddy].contains($0.listingType)
                                        }.prefix(4).map { $0 },
                                        selectedItem: $selectedItem,
                                        onSeeAll: { 
                                            selectedCategoryTitle = "Find a Buddy"
                                            selectedListingTypes = [.carpool, .lunchBuddy, .walkingBuddy, .workoutBuddy]
                                            filterByJustListed = false
                                            showCategoryListing = true
                                        }
                                    )
                                } else {
                                    // Show regular grid when filters are applied
                                    LazyVGrid(columns: columns, spacing: 12) {
                                        ForEach(displayedItems) { item in
                                            DiscoverItemCard(item: item, isCompact: false)
                                                .onTapGesture {
                                                    selectedItem = item
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.bottom, 100)
                        }
                        .refreshable {
                            await refreshItems()
                        }
                    }
                    .offset(y: contentOffset)
                }
                
                // Tutorial background overlay
                if tutorialBackgroundOpacity > 0 {
                    Color.black
                        .opacity(tutorialBackgroundOpacity)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Initialize filteredItems with all items first
                filteredItems = dataManager.items
                
                // Check saved location preferences
                if let savedZip = UserDefaults.standard.string(forKey: "lastSearchedZipCode"),
                   let savedCity = UserDefaults.standard.string(forKey: "lastSearchedCity") {
                    zipCode = savedZip
                    searchedLocation = savedCity
                    locationManager.locationString = savedCity
                    locationManager.isUsingCurrentLocation = false
                }
                
                // Request location after a small delay to avoid blocking
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    locationManager.requestLocation()
                }
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
                searchRadius: $searchRadius,
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
            .presentationDetents([.medium]) // Show as half page from bottom
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.hopeDarkBg)
        }
        .sheet(isPresented: $showCategorySelection) {
            CategorySelectionView(selectedCategory: $selectedCategory)
                .onDisappear {
                    filterItems()
                }
        }
        .fullScreenCover(isPresented: $showCategoryListing) {
            ZStack {
                Color.hopeDarkBg.ignoresSafeArea()
                
                let currentLocationFilter = (!locationManager.isUsingCurrentLocation || !searchedLocation.isEmpty) ? (searchedLocation.isEmpty ? locationManager.locationString : searchedLocation) : nil
                
                if filterByJustListed {
                    CategoryListingView(categoryTitle: selectedCategoryTitle, filterByJustListed: true, locationFilter: currentLocationFilter)
                        .environmentObject(dataManager)
                } else if let types = selectedListingTypes {
                    if types.count == 1, let type = types.first {
                        CategoryListingView(categoryTitle: selectedCategoryTitle, listingType: type, locationFilter: currentLocationFilter)
                            .environmentObject(dataManager)
                    } else {
                        CategoryListingView(categoryTitle: selectedCategoryTitle, listingTypes: types, locationFilter: currentLocationFilter)
                            .environmentObject(dataManager)
                    }
                } else {
                    // Fallback if no filter is set
                    CategoryListingView(categoryTitle: selectedCategoryTitle, listingTypes: ListingType.allCases, locationFilter: currentLocationFilter)
                        .environmentObject(dataManager)
                }
            }
            .onDisappear {
                // Reset state when sheet is dismissed
                selectedCategoryTitle = ""
                selectedListingTypes = nil
                filterByJustListed = false
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
            
            // Note: For a production app, you would also filter by radius here
            // using geocoding and distance calculations. For now, we're just
            // filtering by city name match.
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
        print("Starting pull-to-refresh tutorial animation")
        // Delay to ensure content is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Set tutorial text
            tutorialText = "Pull down to refresh"
            
            // Fade in background
            withAnimation(.easeIn(duration: 0.3)) {
                tutorialBackgroundOpacity = 0.3
            }
            
            // Pull down animation
            withAnimation(.easeOut(duration: 1.0)) {
                contentOffset = 100
            }
            
            // Hold for a moment and then spring back
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                // Spring back up
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
                    contentOffset = 0
                }
                
                // Clear tutorial text after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        tutorialText = ""
                        tutorialBackgroundOpacity = 0
                    }
                    
                    // Mark tutorial as complete and save to UserDefaults
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showRefreshTutorial = false
                        // Save that tutorial has been shown
                        UserDefaults.standard.set(true, forKey: "hasShownPullToRefreshTutorial")
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


struct CategorySection: View {
    let title: String
    var subtitle: String? = nil
    let items: [Item]
    @Binding var selectedItem: Item?
    let onSeeAll: () -> Void
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: onSeeAll) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            // Items in grid
            if items.isEmpty {
                Text("No items in this category yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items.prefix(4)) { item in
                        DiscoverItemCard(item: item, isCompact: false)
                            .onTapGesture {
                                selectedItem = item
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
