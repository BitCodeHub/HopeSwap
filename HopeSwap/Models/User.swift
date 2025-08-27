import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var username: String
    var email: String
    var profileImageURL: String?
    var profilePicture: String? // Alias for profileImageURL for messaging views
    var bio: String?
    var totalDonated: Double
    var itemsListed: Int
    var tradesCompleted: Int
    var joinedDate: Date
    
    var name: String { // Computed property for display name
        username
    }
    
    init(id: UUID = UUID(), username: String, email: String) {
        self.id = id
        self.username = username
        self.email = email
        self.profileImageURL = nil
        self.profilePicture = nil
        self.totalDonated = 0
        self.itemsListed = 0
        self.tradesCompleted = 0
        self.joinedDate = Date()
    }
}