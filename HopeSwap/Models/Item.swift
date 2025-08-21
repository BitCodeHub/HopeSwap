import Foundation
import SwiftUI

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
        return hoursSincePosted < 24
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