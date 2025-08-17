import Foundation

struct Donation: Identifiable, Codable {
    let id: UUID
    var userId: UUID
    var amount: Double
    var type: DonationType
    var relatedItemId: UUID?
    var relatedTradeId: UUID?
    var donationDate: Date
    var status: DonationStatus
    
    init(id: UUID = UUID(), userId: UUID, amount: Double, type: DonationType) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.type = type
        self.donationDate = Date()
        self.status = .pending
    }
}

enum DonationType: String, Codable {
    case listingFee = "Listing Fee"
    case tradeCommission = "Trade Commission"
    case directDonation = "Direct Donation"
}

enum DonationStatus: String, Codable {
    case pending = "Pending"
    case completed = "Completed"
    case failed = "Failed"
}