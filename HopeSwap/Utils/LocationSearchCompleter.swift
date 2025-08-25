import Foundation
import MapKit

// Location Search Completer implementation
class LocationSearchCompleter: NSObject, ObservableObject {
    private let completer = MKLocalSearchCompleter()
    var delegate: LocationSearchCompleterDelegate?
    
    @Published var searchQuery = "" {
        didSet {
            if searchQuery.isEmpty {
                delegate?.didUpdateResults([])
                results = []
            } else {
                completer.queryFragment = searchQuery
            }
        }
    }
    
    @Published var searchText = "" {
        didSet {
            if searchText.isEmpty {
                results = []
            } else {
                completer.queryFragment = searchText
            }
        }
    }
    
    @Published var results: [MKLocalSearchCompletion] = []
    
    override init() {
        super.init()
        completer.delegate = self
        // Allow all result types including addresses and businesses
        completer.resultTypes = [.address, .pointOfInterest, .query]
        completer.pointOfInterestFilter = .includingAll
    }
}

extension LocationSearchCompleter: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        delegate?.didUpdateResults(completer.results)
        results = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search error: \(error)")
        delegate?.didUpdateResults([])
        results = []
    }
}

struct LocationSearchCompleterDelegate {
    let didUpdateResults: ([MKLocalSearchCompletion]) -> Void
}