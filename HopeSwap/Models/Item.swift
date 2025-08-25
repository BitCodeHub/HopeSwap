import Foundation
import SwiftUI
import FirebaseFirestore

struct Item: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var category: Category
    var condition: Condition
    var images: [String]
    var userId: UUID
    var postedDate: Date
    var status: ItemStatus
    var location: String
    var favoriteCount: Int
    var price: Double?
    var priceIsFirm: Bool
    var isTradeItem: Bool
    
    // Trade preferences
    var lookingFor: String?
    var acceptableItems: String?
    var tradeSuggestions: String?
    var openToOffers: Bool
    
    // Listing type to track which flow created this item
    var listingType: ListingType
    
    // New properties for Discover view
    var isJustListed: Bool {
        let hoursSincePosted = Date().timeIntervalSince(postedDate) / 3600
        return hoursSincePosted <= 24
    }
    
    var isNearby: Bool = false
    var distance: Double? = nil
    
    init(id: UUID = UUID(), 
         title: String, 
         description: String, 
         category: Category, 
         condition: Condition, 
         userId: UUID, 
         location: String,
         postedDate: Date = Date(),
         price: Double? = nil,
         priceIsFirm: Bool = false,
         isTradeItem: Bool = false,
         lookingFor: String? = nil,
         acceptableItems: String? = nil,
         tradeSuggestions: String? = nil,
         openToOffers: Bool = false,
         images: [String] = [],
         listingType: ListingType = .sell) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.condition = condition
        self.images = images
        self.userId = userId
        self.postedDate = postedDate
        self.status = .available
        self.location = location
        self.favoriteCount = 0
        self.price = price
        self.priceIsFirm = priceIsFirm
        self.isTradeItem = isTradeItem
        self.lookingFor = lookingFor
        self.acceptableItems = acceptableItems
        self.tradeSuggestions = tradeSuggestions
        self.openToOffers = openToOffers
        self.listingType = listingType
    }
}

enum Category: String, Codable, CaseIterable {
    case antiquesCollectibles = "Antiques & Collectibles"
    case artsCrafts = "Arts & Crafts"
    case autoParts = "Auto Parts"
    case baby = "Baby"
    case booksMoviesMusic = "Books, Movies & Music"
    case electronics = "Electronics"
    case furniture = "Furniture"
    case garageSale = "Garage Sale"
    case healthBeauty = "Health & Beauty"
    case homeKitchen = "Home & Kitchen"
    case homeImprovement = "Home Improvement"
    case housingForSale = "Housing for Sale"
    case jewelryWatches = "Jewelry & Watches"
    case kidswearBaby = "Kidswear & Baby"
    case luggageBags = "Luggage & Bags"
    case menswear = "Menswear"
    case miscellaneous = "Miscellaneous"
    case musicalInstruments = "Musical Instruments"
    case patioGarden = "Patio & Garden"
    case petSupplies = "Pet Supplies"
    case rentals = "Rentals"
    case sportingGoods = "Sporting Goods"
    case toysGames = "Toys & Games"
    case vehicles = "Vehicles"
    case womenswear = "Womenswear"
    
    // Mapping to support existing data
    static func fromOldCategory(_ oldCategory: String) -> Category {
        switch oldCategory {
        case "Electronics": return .electronics
        case "Clothing": return .miscellaneous
        case "Books": return .booksMoviesMusic
        case "Toys": return .toysGames
        case "Home & Garden": return .homeKitchen
        case "Sports": return .sportingGoods
        default: return .miscellaneous
        }
    }
}

enum Condition: String, Codable, CaseIterable {
    case new = "New"
    case likeNew = "Like New"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
}

enum ItemStatus: String, Codable, Equatable {
    case available = "Available"
    case pending = "Pending"
    case traded = "Traded"
    case sold = "Sold"
}

enum ListingType: String, Codable, CaseIterable {
    case sell = "Sell"
    case trade = "Trade"
    case giveAway = "Give Away"
    case needHelp = "Need Help"
    case carpool = "Carpool"
    case event = "Event"
    case lunchBuddy = "Lunch Buddy"
    case workoutBuddy = "Workout Buddy"
    case walkingBuddy = "Walking Buddy"
    
    var color: Color {
        switch self {
        case .sell: return Color.hopeGreen
        case .trade: return Color.hopeBlue
        case .giveAway: return Color.hopePink
        case .needHelp: return Color.hopeOrange
        case .carpool: return Color.hopePurple
        case .event: return Color.yellow
        case .lunchBuddy: return Color.red
        case .workoutBuddy: return Color.cyan
        case .walkingBuddy: return Color.mint
        }
    }
    
    var icon: String {
        switch self {
        case .sell: return "dollarsign.circle"
        case .trade: return "arrow.left.arrow.right"
        case .giveAway: return "gift"
        case .needHelp: return "hand.raised"
        case .carpool: return "car"
        case .event: return "calendar"
        case .lunchBuddy: return "fork.knife"
        case .workoutBuddy: return "dumbbell"
        case .walkingBuddy: return "figure.walk"
        }
    }
}

// MARK: - Firestore Support
extension Item {
    // Convert Item to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "title": title,
            "description": description,
            "price": price ?? 0,
            "category": category.rawValue,
            "condition": condition.rawValue,
            "location": location,
            "images": images,
            "listingType": listingType.rawValue,
            "postedDate": Timestamp(date: postedDate),
            "status": status.rawValue,
            "favoriteCount": favoriteCount,
            "priceIsFirm": priceIsFirm,
            "isTradeItem": isTradeItem,
            "lookingFor": lookingFor ?? "",
            "acceptableItems": acceptableItems ?? "",
            "tradeSuggestions": tradeSuggestions ?? "",
            "openToOffers": openToOffers,
            "isNearby": isNearby,
            "distance": distance ?? 0
        ]
    }
    
    // Create Item from Firestore document
    static func fromFirestore(document: QueryDocumentSnapshot) throws -> Item {
        let data = document.data()
        
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let categoryString = data["category"] as? String,
              let category = Category(rawValue: categoryString),
              let conditionString = data["condition"] as? String,
              let condition = Condition(rawValue: conditionString),
              let location = data["location"] as? String,
              let images = data["images"] as? [String],
              let listingTypeString = data["listingType"] as? String,
              let listingType = ListingType(rawValue: listingTypeString),
              let timestamp = data["postedDate"] as? Timestamp,
              let statusString = data["status"] as? String,
              let status = ItemStatus(rawValue: statusString) else {
            throw NSError(domain: "FirestoreError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid item data in document: \(document.documentID)"])
        }
        
        // Extract optional fields with defaults
        let price = data["price"] as? Double
        let finalPrice = (price == 0) ? nil : price
        let favoriteCount = data["favoriteCount"] as? Int ?? 0
        let priceIsFirm = data["priceIsFirm"] as? Bool ?? false
        let isTradeItem = data["isTradeItem"] as? Bool ?? false
        let lookingFor = data["lookingFor"] as? String
        let acceptableItems = data["acceptableItems"] as? String
        let tradeSuggestions = data["tradeSuggestions"] as? String
        let openToOffers = data["openToOffers"] as? Bool ?? false
        let isNearby = data["isNearby"] as? Bool ?? false
        let distance = data["distance"] as? Double
        
        // Create a temporary userId (in production, you'd get this from the document)
        let userId = UUID() // You might want to store userId as string in Firestore
        
        var item = Item(
            id: id,
            title: title,
            description: description,
            category: category,
            condition: condition,
            userId: userId,
            location: location,
            postedDate: timestamp.dateValue(),
            price: finalPrice,
            priceIsFirm: priceIsFirm,
            isTradeItem: isTradeItem,
            lookingFor: lookingFor?.isEmpty == true ? nil : lookingFor,
            acceptableItems: acceptableItems?.isEmpty == true ? nil : acceptableItems,
            tradeSuggestions: tradeSuggestions?.isEmpty == true ? nil : tradeSuggestions,
            openToOffers: openToOffers,
            images: images,
            listingType: listingType
        )
        
        item.status = status
        item.favoriteCount = favoriteCount
        item.isNearby = isNearby
        item.distance = distance
        
        return item
    }
    
    // Alternative fromFirestore that takes DocumentSnapshot (for real-time listeners)
    static func fromFirestore(document: DocumentSnapshot) throws -> Item {
        guard let data = document.data() else {
            throw NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document data not found"])
        }
        
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let categoryString = data["category"] as? String,
              let category = Category(rawValue: categoryString),
              let conditionString = data["condition"] as? String,
              let condition = Condition(rawValue: conditionString),
              let location = data["location"] as? String,
              let images = data["images"] as? [String],
              let listingTypeString = data["listingType"] as? String,
              let listingType = ListingType(rawValue: listingTypeString),
              let timestamp = data["postedDate"] as? Timestamp,
              let statusString = data["status"] as? String,
              let status = ItemStatus(rawValue: statusString) else {
            throw NSError(domain: "FirestoreError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid item data in document: \(document.documentID)"])
        }
        
        // Extract optional fields with defaults
        let price = data["price"] as? Double
        let finalPrice = (price == 0) ? nil : price
        let favoriteCount = data["favoriteCount"] as? Int ?? 0
        let priceIsFirm = data["priceIsFirm"] as? Bool ?? false
        let isTradeItem = data["isTradeItem"] as? Bool ?? false
        let lookingFor = data["lookingFor"] as? String
        let acceptableItems = data["acceptableItems"] as? String
        let tradeSuggestions = data["tradeSuggestions"] as? String
        let openToOffers = data["openToOffers"] as? Bool ?? false
        let isNearby = data["isNearby"] as? Bool ?? false
        let distance = data["distance"] as? Double
        
        // Create a temporary userId (in production, you'd get this from the document)
        let userId = UUID() // You might want to store userId as string in Firestore
        
        var item = Item(
            id: id,
            title: title,
            description: description,
            category: category,
            condition: condition,
            userId: userId,
            location: location,
            postedDate: timestamp.dateValue(),
            price: finalPrice,
            priceIsFirm: priceIsFirm,
            isTradeItem: isTradeItem,
            lookingFor: lookingFor?.isEmpty == true ? nil : lookingFor,
            acceptableItems: acceptableItems?.isEmpty == true ? nil : acceptableItems,
            tradeSuggestions: tradeSuggestions?.isEmpty == true ? nil : tradeSuggestions,
            openToOffers: openToOffers,
            images: images,
            listingType: listingType
        )
        
        item.status = status
        item.favoriteCount = favoriteCount
        item.isNearby = isNearby
        item.distance = distance
        
        return item
    }
}