import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var locationString = "Updating location..."
    @Published var currentUserLocation = "Updating location..."
    @Published var isUsingCurrentLocation = true
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Check current authorization status
        authorizationStatus = locationManager.authorizationStatus
        
        // Request location if already authorized
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    func requestLocation() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            locationString = "Location access denied"
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        
        // Reverse geocode to get city name
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let placemark = placemarks?.first {
                let city = placemark.locality ?? "Unknown"
                let state = placemark.administrativeArea ?? ""
                
                // Get state abbreviation
                let stateAbbreviation = self?.getStateAbbreviation(from: state) ?? state
                
                if !city.isEmpty && !stateAbbreviation.isEmpty {
                    self?.currentUserLocation = "\(city), \(stateAbbreviation)"
                    if self?.isUsingCurrentLocation == true {
                        self?.locationString = "\(city), \(stateAbbreviation)"
                    }
                } else if !city.isEmpty {
                    self?.currentUserLocation = city
                    if self?.isUsingCurrentLocation == true {
                        self?.locationString = city
                    }
                } else {
                    self?.currentUserLocation = "Unknown location"
                    if self?.isUsingCurrentLocation == true {
                        self?.locationString = "Unknown location"
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        locationString = "Location unavailable"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    private func getStateAbbreviation(from state: String) -> String {
        let stateAbbreviations: [String: String] = [
            "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR",
            "California": "CA", "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE",
            "Florida": "FL", "Georgia": "GA", "Hawaii": "HI", "Idaho": "ID",
            "Illinois": "IL", "Indiana": "IN", "Iowa": "IA", "Kansas": "KS",
            "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME", "Maryland": "MD",
            "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN", "Mississippi": "MS",
            "Missouri": "MO", "Montana": "MT", "Nebraska": "NE", "Nevada": "NV",
            "New Hampshire": "NH", "New Jersey": "NJ", "New Mexico": "NM", "New York": "NY",
            "North Carolina": "NC", "North Dakota": "ND", "Ohio": "OH", "Oklahoma": "OK",
            "Oregon": "OR", "Pennsylvania": "PA", "Rhode Island": "RI", "South Carolina": "SC",
            "South Dakota": "SD", "Tennessee": "TN", "Texas": "TX", "Utah": "UT",
            "Vermont": "VT", "Virginia": "VA", "Washington": "WA", "West Virginia": "WV",
            "Wisconsin": "WI", "Wyoming": "WY", "District of Columbia": "DC"
        ]
        
        return stateAbbreviations[state] ?? state
    }
}