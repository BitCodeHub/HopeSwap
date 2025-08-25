import SwiftUI
import MapKit
import CoreLocation

struct LocationSearchView: View {
    @Binding var searchedLocation: String
    @Binding var searchRadius: Double
    let onApply: (String, Double) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 33.7501, longitude: -117.8356),
        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )
    @State private var selectedLocation = "Westminster"
    @State private var selectedCoordinate = CLLocationCoordinate2D(latitude: 33.7501, longitude: -117.8356)
    @State private var userCoordinate: CLLocationCoordinate2D? = nil
    @State private var useCustomRadius = false
    @State private var customRadiusValue: Double = 10
    @StateObject private var searchCompleter = LocationSearchCompleter()
    @StateObject private var locationManager = LocationManager()
    @State private var showSearchResults = false
    
    // Calculate radius in meters for map overlay
    var radiusInMeters: Double {
        let radiusInMiles = useCustomRadius ? customRadiusValue : 15
        return radiusInMiles * 1609.34 // Convert miles to meters
    }
    
    var body: some View {
        ZStack {
            // Full screen map with circle overlay
            MapWithCircleOverlay(
                region: $mapRegion,
                centerCoordinate: selectedCoordinate,
                userCoordinate: userCoordinate,
                radiusInMeters: radiusInMeters
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with search bar
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        Text("Location")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Empty space for balance
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal)
                    .padding(.top, 50)
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.body)
                        
                        TextField("", text: $searchText)
                            .placeholder(when: searchText.isEmpty) {
                                Text("Search by city, neighborhood or ZIP code")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: searchText) { oldValue, newValue in
                                searchCompleter.searchText = newValue
                                showSearchResults = !newValue.isEmpty && newValue.count > 0
                            }
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: { 
                                searchText = ""
                                showSearchResults = false
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
                            .fill(Color.white.opacity(0.15))
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                }
                .background(Color.black.opacity(0.8))
                
                // Search results dropdown
                if showSearchResults && !searchCompleter.results.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(searchCompleter.results, id: \.self) { result in
                                Button(action: {
                                    selectSearchResult(result)
                                }) {
                                    HStack {
                                        Image(systemName: "mappin")
                                            .foregroundColor(.gray)
                                            .font(.body)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(result.title)
                                                .foregroundColor(.white)
                                                .font(.body)
                                            
                                            if !result.subtitle.isEmpty {
                                                Text(result.subtitle)
                                                    .foregroundColor(.gray)
                                                    .font(.caption)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 12)
                                }
                                
                                if result != searchCompleter.results.last {
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                    .background(Color.hopeDarkSecondary)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .shadow(radius: 5)
                }
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Suggested radius option
                        Button(action: {
                            useCustomRadius = false
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Suggested local radius")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text("Show me listings from this general area.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: useCustomRadius ? "circle" : "circle.fill")
                                    .font(.title2)
                                    .foregroundColor(useCustomRadius ? .gray : Color.hopeBlue)
                            }
                        }
                        
                        // Custom radius option
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                useCustomRadius = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Custom local radius")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Text("Only show me listings within a specific distance.")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: useCustomRadius ? "circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundColor(useCustomRadius ? Color.hopeBlue : .gray)
                                }
                            }
                            
                            // Slider when custom radius is selected
                            if useCustomRadius {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("\(Int(customRadiusValue)) miles")
                                            .font(.subheadline)
                                            .foregroundColor(Color.hopeBlue)
                                        
                                        Spacer()
                                    }
                                    
                                    Slider(value: $customRadiusValue, in: 2...50, step: 1)
                                        .accentColor(Color.hopeBlue)
                                        .onChange(of: customRadiusValue) { _, newValue in
                                            // Force map update when radius changes
                                            // This will trigger updateUIView in MapWithCircleOverlay
                                        }
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Apply button
                    Button(action: {
                        let radius = useCustomRadius ? customRadiusValue : 15 // Default 15 miles for suggested
                        searchRadius = radius
                        onApply(selectedLocation, radius)
                        dismiss()
                    }) {
                        Text("Apply")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.hopeBlue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.hopeDarkSecondary)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Initialize with the current searched location if available
            if !searchedLocation.isEmpty {
                selectedLocation = searchedLocation
                searchText = searchedLocation
                geocodeLocation(searchedLocation)
            }
            
            // Initialize radius values
            if searchRadius > 0 && searchRadius != 15 {
                useCustomRadius = true
                customRadiusValue = searchRadius
            }
            
            // Get user's current location with a small delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                locationManager.requestLocation()
                if let location = locationManager.location {
                    userCoordinate = location.coordinate
                }
            }
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let location = newLocation {
                userCoordinate = location.coordinate
            }
        }
    }
    
    private func performSearch() {
        // Handle direct search submission
        if !searchText.isEmpty {
            // First check if it's a ZIP code
            if let _ = Int(searchText), searchText.count == 5 {
                // It's a ZIP code
                if let city = ZipCodeManager.shared.getCityForZipCode(searchText) {
                    selectedLocation = city
                    searchText = city
                    
                    // Geocode the city to get coordinates
                    geocodeLocation(city)
                } else {
                    // Try geocoding the ZIP directly
                    geocodeLocation(searchText)
                }
            } else {
                // It's a city name or address
                geocodeLocation(searchText)
            }
        }
    }
    
    private func geocodeLocation(_ location: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { placemarks, error in
            if let placemark = placemarks?.first,
               let location = placemark.location {
                selectedLocation = placemark.locality ?? searchText
                selectedCoordinate = location.coordinate
                
                // Calculate region to show both user and search locations
                var center = location.coordinate
                var span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                
                if let userCoord = userCoordinate {
                    // Calculate region that includes both points
                    let minLat = min(location.coordinate.latitude, userCoord.latitude)
                    let maxLat = max(location.coordinate.latitude, userCoord.latitude)
                    let minLon = min(location.coordinate.longitude, userCoord.longitude)
                    let maxLon = max(location.coordinate.longitude, userCoord.longitude)
                    
                    center = CLLocationCoordinate2D(
                        latitude: (minLat + maxLat) / 2,
                        longitude: (minLon + maxLon) / 2
                    )
                    
                    let latDelta = (maxLat - minLat) * 1.3
                    let lonDelta = (maxLon - minLon) * 1.3
                    span = MKCoordinateSpan(
                        latitudeDelta: max(latDelta, 0.05),
                        longitudeDelta: max(lonDelta, 0.05)
                    )
                }
                
                withAnimation {
                    mapRegion = MKCoordinateRegion(center: center, span: span)
                }
                showSearchResults = false
            }
        }
    }
    
    private func selectSearchResult(_ result: MKLocalSearchCompletion) {
        searchText = result.title
        selectedLocation = result.title
        showSearchResults = false
        
        // Convert the search result to coordinates
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            if let item = response?.mapItems.first {
                selectedCoordinate = item.placemark.coordinate
                
                // Calculate region to show both user and search locations
                var center = item.placemark.coordinate
                var span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                
                if let userCoord = userCoordinate {
                    // Calculate region that includes both points
                    let minLat = min(item.placemark.coordinate.latitude, userCoord.latitude)
                    let maxLat = max(item.placemark.coordinate.latitude, userCoord.latitude)
                    let minLon = min(item.placemark.coordinate.longitude, userCoord.longitude)
                    let maxLon = max(item.placemark.coordinate.longitude, userCoord.longitude)
                    
                    center = CLLocationCoordinate2D(
                        latitude: (minLat + maxLat) / 2,
                        longitude: (minLon + maxLon) / 2
                    )
                    
                    let latDelta = (maxLat - minLat) * 1.3
                    let lonDelta = (maxLon - minLon) * 1.3
                    span = MKCoordinateSpan(
                        latitudeDelta: max(latDelta, 0.05),
                        longitudeDelta: max(lonDelta, 0.05)
                    )
                }
                
                withAnimation {
                    mapRegion = MKCoordinateRegion(center: center, span: span)
                }
            }
        }
    }
}

// Custom annotation class to differentiate between user and search locations
class CustomAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType
    
    enum AnnotationType {
        case userLocation
        case searchLocation
    }
    
    init(coordinate: CLLocationCoordinate2D, type: AnnotationType) {
        self.coordinate = coordinate
        self.type = type
    }
}

// Custom map view with circle overlay
struct MapWithCircleOverlay: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let centerCoordinate: CLLocationCoordinate2D
    let userCoordinate: CLLocationCoordinate2D?
    let radiusInMeters: Double
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update map region
        if !context.coordinator.isUserInteracting {
            mapView.setRegion(region, animated: true)
        }
        
        // Remove existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        // Add circle overlay
        let circle = MKCircle(center: centerCoordinate, radius: radiusInMeters)
        mapView.addOverlay(circle)
        
        // Add searched location pin
        let searchAnnotation = CustomAnnotation(coordinate: centerCoordinate, type: .searchLocation)
        mapView.addAnnotation(searchAnnotation)
        
        // Add user location pin if available
        if let userCoord = userCoordinate {
            let userAnnotation = CustomAnnotation(coordinate: userCoord, type: .userLocation)
            mapView.addAnnotation(userAnnotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapWithCircleOverlay
        var isUserInteracting = false
        
        init(_ parent: MapWithCircleOverlay) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circle)
                renderer.fillColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 0.2) // Blue with opacity
                renderer.strokeColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 0.5)
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let customAnnotation = annotation as? CustomAnnotation else { return nil }
            
            let identifier = customAnnotation.type == .userLocation ? "UserLocation" : "SearchLocation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
                
                // Create custom pin view based on type
                if customAnnotation.type == .userLocation {
                    // User location - smaller blue dot with pulsing effect
                    let containerView = UIView(frame: CGRect(x: -10, y: -10, width: 20, height: 20))
                    
                    // Outer glow circle
                    let glowView = UIView(frame: CGRect(x: 3, y: 3, width: 14, height: 14))
                    glowView.backgroundColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 0.3)
                    glowView.layer.cornerRadius = 7
                    containerView.addSubview(glowView)
                    
                    // White border
                    let pinView = UIView(frame: CGRect(x: 5, y: 5, width: 10, height: 10))
                    pinView.backgroundColor = .white
                    pinView.layer.cornerRadius = 5
                    
                    // Inner blue dot
                    let innerView = UIView(frame: CGRect(x: 1, y: 1, width: 8, height: 8))
                    innerView.backgroundColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
                    innerView.layer.cornerRadius = 4
                    
                    pinView.addSubview(innerView)
                    containerView.addSubview(pinView)
                    annotationView?.addSubview(containerView)
                    annotationView?.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
                } else {
                    // Search location - larger blue dot with white border
                    let pinView = UIView(frame: CGRect(x: -10, y: -10, width: 20, height: 20))
                    pinView.backgroundColor = .white
                    pinView.layer.cornerRadius = 10
                    pinView.layer.shadowColor = UIColor.black.cgColor
                    pinView.layer.shadowOffset = CGSize(width: 0, height: 2)
                    pinView.layer.shadowRadius = 3
                    pinView.layer.shadowOpacity = 0.3
                    
                    let innerView = UIView(frame: CGRect(x: 2, y: 2, width: 16, height: 16))
                    innerView.backgroundColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
                    innerView.layer.cornerRadius = 8
                    
                    pinView.addSubview(innerView)
                    annotationView?.addSubview(pinView)
                    annotationView?.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
                }
                
                annotationView?.centerOffset = CGPoint(x: 0, y: 0)
            }
            
            annotationView?.annotation = annotation
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            isUserInteracting = true
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            isUserInteracting = false
            parent.region = mapView.region
        }
    }
}

