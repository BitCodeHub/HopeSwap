import Foundation

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
         images: [String] = []) {
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