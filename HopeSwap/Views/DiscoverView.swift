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
    
    let tabs = ["Sell", "For you", "Local", "More"]
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
                        // Tab selector
                        HStack(spacing: 0) {
                            ForEach(tabs, id: \.self) { tab in
                                TabButton(
                                    title: tab,
                                    isSelected: selectedTab == tab,
                                    action: { selectedTab = tab }
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Title and location
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
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    .padding(.bottom, 16)
                    
                    // Grid of items
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredItems.isEmpty ? dataManager.items : filteredItems) { item in
                                DiscoverItemCard(item: item)
                                    .onTapGesture {
                                        selectedItem = item
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
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
                }
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
        let cityName = city.components(separatedBy: ",").first ?? ""
        filteredItems = dataManager.items.filter { item in
            item.location.lowercased().contains(cityName.lowercased())
        }
    }
    
    private func switchToCurrentLocation() {
        locationManager.isUsingCurrentLocation = true
        locationManager.locationString = locationManager.currentUserLocation
        filterItemsByLocation(locationManager.currentUserLocation)
        
        // Clear saved search
        UserDefaults.standard.removeObject(forKey: "lastSearchedZipCode")
        UserDefaults.standard.removeObject(forKey: "lastSearchedCity")
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(isSelected ? Color.hopeDarkBg : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with overlay badges
            ZStack(alignment: .topLeading) {
                if let firstImage = item.images.first {
                    AsyncImage(url: URL(string: firstImage)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            )
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                }
                
                // Badges
                VStack(alignment: .leading, spacing: 8) {
                    if item.isJustListed {
                        Badge(text: "Just listed", backgroundColor: .white, textColor: .black)
                    }
                    if item.isNearby {
                        Badge(text: "Nearby", backgroundColor: .white, textColor: .black)
                    }
                }
                .padding(8)
            }
            
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
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor)
            )
    }
}
