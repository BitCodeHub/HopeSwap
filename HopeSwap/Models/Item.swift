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
         openToOffers: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.condition = condition
        self.images = []
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
    case electronics = "Electronics"
    case clothing = "Clothing"
    case books = "Books"
    case toys = "Toys"
    case home = "Home & Garden"
    case sports = "Sports"
    case other = "Other"
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