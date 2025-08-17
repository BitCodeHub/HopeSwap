import Foundation

struct Trade: Identifiable, Codable {
    let id: UUID
    var requesterId: UUID
    var itemOwnerId: UUID
    var itemId: UUID
    var offeredItemId: UUID?
    var offeredAmount: Double?
    var type: TradeType
    var status: TradeStatus
    var message: String?
    var createdDate: Date
    var updatedDate: Date
    
    init(id: UUID = UUID(), requesterId: UUID, itemOwnerId: UUID, itemId: UUID, type: TradeType) {
        self.id = id
        self.requesterId = requesterId
        self.itemOwnerId = itemOwnerId
        self.itemId = itemId
        self.type = type
        self.status = .pending
        self.createdDate = Date()
        self.updatedDate = Date()
    }
}

enum TradeType: String, Codable {
    case trade = "Trade"
    case purchase = "Purchase"
}

enum TradeStatus: String, Codable {
    case pending = "Pending"
    case accepted = "Accepted"
    case rejected = "Rejected"
    case completed = "Completed"
    case cancelled = "Cancelled"
}