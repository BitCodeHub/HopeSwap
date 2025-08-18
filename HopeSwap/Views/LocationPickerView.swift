import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {
    @Binding var zipCode: String
    let currentUserLocation: String
    @Binding var searchedLocation: String
    @Binding var isUsingCurrentLocation: Bool
    let onLocationUpdate: (String) -> Void
    let onLocateMe: () -> Void
    
    @State private var searchText = ""
    @State private var previewCity = ""
    @State private var showCityPreview = false
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @StateObject private var searchCompleter = LocationSearchCompleter()
    @Environment(\.dismiss) var dismiss
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enter Location")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Search by zip code or use your location")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                onLocateMe()
                                dismiss()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.circle.fill")
                                        .font(.body)
                                    Text("Locate Me")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(Color.hopeOrange)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SEARCH LOCATION")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        HStack {
                            TextField("Enter city or zip code", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.body)
                                .foregroundColor(.white)
                                .focused($isSearchFocused)
                                .onChange(of: searchText) { oldValue, newValue in
                                    searchCompleter.searchQuery = newValue
                                    
                                    // Check if it's a complete 5-digit zip code
                                    if newValue.count == 5 && newValue.allSatisfy({ $0.isNumber }) {
                                        lookupCity(for: newValue)
                                    } else {
                                        showCityPreview = false
                                        previewCity = ""
                                    }
                                }
                            
                            // Clear button
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    searchResults = []
                                    showCityPreview = false
                                    previewCity = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.body)
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                        .background(Color.hopeDarkSecondary)
                        .cornerRadius(10)
                    }
                    
                    // Show search suggestions
                    if !searchResults.isEmpty && !showCityPreview {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(searchResults.prefix(5), id: \.self) { result in
                                Button(action: {
                                    selectSearchResult(result)
                                }) {
                                    HStack {
                                        Image(systemName: "location.fill")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(result.title)
                                                .font(.body)
                                                .foregroundColor(.white)
                                            if !result.subtitle.isEmpty {
                                                Text(result.subtitle)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if result != searchResults.prefix(5).last {
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
                                }
                            }
                        }
                        .background(Color.hopeDarkSecondary)
                        .cornerRadius(10)
                    }
                    
                    // Show city preview after entering zip code
                    if showCityPreview && !previewCity.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LOCATION FOUND")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(Color.hopeGreen)
                                Text(previewCity)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.hopeGreen.opacity(0.2))
                            .cornerRadius(10)
                        }
                    }
                    
                    // Show current location and searched location
                    VStack(alignment: .leading, spacing: 12) {
                        if !currentUserLocation.contains("Updating") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("YOUR LOCATION")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                
                                Button(action: {
                                    onLocateMe()
                                    dismiss()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "location.fill")
                                            .font(.body)
                                        Text(currentUserLocation)
                                            .font(.body)
                                        Spacer()
                                        if isUsingCurrentLocation {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.body)
                                                .foregroundColor(Color.hopeGreen)
                                        }
                                    }
                                    .foregroundColor(isUsingCurrentLocation ? .white : Color.hopeOrange)
                                    .padding()
                                    .background(isUsingCurrentLocation ? Color.hopeOrange.opacity(0.2) : Color.hopeDarkSecondary)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        
                        if !searchedLocation.isEmpty && !isUsingCurrentLocation {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SEARCHED LOCATION")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.body)
                                        .foregroundColor(.white)
                                    Text(searchedLocation)
                                        .font(.body)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.body)
                                        .foregroundColor(Color.hopeGreen)
                                }
                                .padding()
                                .background(Color.hopeOrange.opacity(0.2))
                                .cornerRadius(10)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Color.hopeOrange),
                trailing: Button("Add") {
                    if showCityPreview && !previewCity.isEmpty {
                        // Update the searched location
                        searchedLocation = previewCity
                        
                        // Extract zip code if available
                        if searchText.count == 5 && searchText.allSatisfy({ $0.isNumber }) {
                            zipCode = searchText
                            onLocationUpdate(searchText)
                        } else {
                            // For city searches, pass empty zip
                            zipCode = ""
                            onLocationUpdate("")
                        }
                        dismiss()
                    }
                }
                .foregroundColor(Color.hopeOrange)
                .fontWeight(.semibold)
                .disabled(!showCityPreview || previewCity.isEmpty)
            )
        }
        .onAppear {
            searchText = zipCode
            searchCompleter.delegate = LocationSearchCompleterDelegate { results in
                searchResults = results
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isSearchFocused = true
            }
        }
    }
    
    private func lookupCity(for zip: String) {
        // Use centralized ZipCodeManager
        if let city = ZipCodeManager.shared.getCityForZipCode(zip) {
            previewCity = city
            showCityPreview = true
        } else {
            // For unknown zip codes, try to get city from geocoding
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(zip) { placemarks, error in
                if let placemark = placemarks?.first,
                   let city = placemark.locality,
                   let state = placemark.administrativeArea {
                    previewCity = "\(city), \(state)"
                    showCityPreview = true
                } else {
                    previewCity = "Unknown location"
                    showCityPreview = true
                }
            }
        }
    }
    
    private func selectSearchResult(_ result: MKLocalSearchCompletion) {
        searchText = result.title
        searchResults = []
        
        // Extract city and state from the result, removing "United States"
        let cleanedTitle = result.title
            .replacingOccurrences(of: ", United States", with: "")
            .replacingOccurrences(of: "United States", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let components = cleanedTitle.components(separatedBy: ", ")
        if components.count >= 2 {
            previewCity = cleanedTitle
            showCityPreview = true
        } else {
            // Perform a more detailed search
            let searchRequest = MKLocalSearch.Request(completion: result)
            let search = MKLocalSearch(request: searchRequest)
            
            search.start { response, error in
                if let item = response?.mapItems.first,
                   let city = item.placemark.locality,
                   let state = item.placemark.administrativeArea {
                    previewCity = "\(city), \(state)"
                    showCityPreview = true
                }
            }
        }
    }
}

