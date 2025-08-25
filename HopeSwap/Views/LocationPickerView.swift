import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {
    @Binding var zipCode: String
    let currentUserLocation: String
    @Binding var searchedLocation: String
    @Binding var isUsingCurrentLocation: Bool
    @Binding var searchRadius: Double
    let onLocationUpdate: (String) -> Void
    let onLocateMe: () -> Void
    
    @State private var searchText = ""
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 33.7501, longitude: -117.8356), // Westminster, CA default
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var currentLocationName = ""
    @State private var recentLocations: [String] = []
    @State private var suggestedLocations = ["Los Angeles, California", "Amarillo, Texas"]
    @StateObject private var locationManager = LocationManager()
    @State private var hasInitializedLocation = false
    @State private var showLocationSearch = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        Text("Choose a location")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            showLocationSearch = true
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Map view with blue circle overlay
                            Button(action: {
                                showLocationSearch = true
                            }) {
                                ZStack {
                                    // Simple map using Map from MapKit
                                    Map(coordinateRegion: $mapRegion)
                                        .frame(height: 180)
                                        .disabled(true)
                                    
                                    // Blue circle overlay to show radius
                                    Circle()
                                        .fill(Color.hopeBlue.opacity(0.2))
                                        .stroke(Color.hopeBlue.opacity(0.5), lineWidth: 2)
                                        .frame(width: 150, height: 150)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Location info
                            VStack(alignment: .leading, spacing: 8) {
                                Text(currentLocationName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text(searchRadius > 0 && searchRadius < 15 ? "\(Int(searchRadius)) mile radius" : searchRadius == 15 ? "Suggested radius" : "\(Int(searchRadius)) mile radius")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            
                            // Locate me button
                            Button(action: {
                                onLocateMe()
                                updateToCurrentLocation()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "location.fill")
                                        .font(.title3)
                                    Text("Locate me")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.hopeBlue)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                            
                            // Recent locations section
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Recent locations")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: {}) {
                                        Text("See all")
                                            .font(.subheadline)
                                            .foregroundColor(Color.hopeBlue)
                                    }
                                }
                                .padding(.horizontal)
                                
                                ForEach(recentLocations, id: \.self) { location in
                                    LocationRow(
                                        location: location,
                                        icon: "clock",
                                        showHeart: true,
                                        action: {
                                            selectLocation(location)
                                        }
                                    )
                                }
                            }
                            .padding(.bottom, 20)
                            
                            // Suggested locations section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Suggested for you")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                
                                // Grid layout for suggested locations
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(suggestedLocations, id: \.self) { location in
                                        Button(action: {
                                            selectLocation(location)
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "mappin")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                
                                                Text(location)
                                                    .font(.subheadline)
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                
                                                Spacer()
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .frame(maxWidth: .infinity)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showLocationSearch) {
            LocationSearchView(
                searchedLocation: $searchedLocation,
                searchRadius: $searchRadius,
                onApply: { location, radius in
                    // Update the location based on search
                    currentLocationName = location
                    searchedLocation = location
                    searchRadius = radius
                    isUsingCurrentLocation = false
                    updateMapRegion(for: location)
                    selectLocation(location)
                }
            )
        }
        .onAppear {
            setupInitialLocation()
            loadRecentLocations()
            
            // Request location permission after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                locationManager.requestLocation()
            }
        }
    }
    
    private func setupInitialLocation() {
        // Setup based on current location or saved location
        if !searchedLocation.isEmpty {
            currentLocationName = searchedLocation
            updateMapRegion(for: searchedLocation)
        } else if !currentUserLocation.contains("Updating") && !currentUserLocation.isEmpty {
            currentLocationName = currentUserLocation
            updateMapRegion(for: currentUserLocation)
        } else {
            // Default to Westminster, CA if no location available
            currentLocationName = "Westminster, California"
        }
    }
    
    private func updateMapRegion(for locationName: String) {
        // Geocode the location to get coordinates
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(locationName) { placemarks, error in
            if let placemark = placemarks?.first,
               let location = placemark.location {
                withAnimation {
                    mapRegion = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    )
                }
            }
        }
    }
    
    private func updateToCurrentLocation() {
        if let location = locationManager.location {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first,
                   let city = placemark.locality,
                   let state = placemark.administrativeArea {
                    currentLocationName = "\(city), \(state)"
                    withAnimation {
                        mapRegion = MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                        )
                    }
                    selectLocation(currentLocationName)
                }
            }
        }
    }
    
    private func selectLocation(_ location: String) {
        searchedLocation = location
        isUsingCurrentLocation = false
        
        // Save to recent locations
        if !recentLocations.contains(location) {
            recentLocations.insert(location, at: 0)
            if recentLocations.count > 5 {
                recentLocations.removeLast()
            }
            saveRecentLocations()
        }
        
        // Extract zip if possible (would need reverse geocoding for full implementation)
        onLocationUpdate("")
        dismiss()
    }
    
    private func loadRecentLocations() {
        if let saved = UserDefaults.standard.stringArray(forKey: "recentLocations"), !saved.isEmpty {
            recentLocations = saved
        } else {
            // Default recent location
            recentLocations = ["Garden Grove, California"]
        }
    }
    
    private func saveRecentLocations() {
        UserDefaults.standard.set(recentLocations, forKey: "recentLocations")
    }
}

// MapView temporarily removed to debug black screen issue

struct LocationRow: View {
    let location: String
    let icon: String
    let showHeart: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                Text(location)
                    .font(.body)
                    .foregroundColor(.white)
                
                Spacer()
                
                if showHeart {
                    Button(action: {}) {
                        Image(systemName: "heart")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}