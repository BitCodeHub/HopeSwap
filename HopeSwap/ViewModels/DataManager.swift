import Foundation
import SwiftUI

class DataManager: ObservableObject {
    @Published var items: [Item] = []
    @Published var favorites: Set<UUID> = []
    @Published var currentUser: User
    
    static let shared = DataManager()
    
    init() {
        self.currentUser = User(username: "JohnDoe", email: "john@example.com")
        loadSampleData()
    }
    
    func loadSampleData() {
        items = [
            Item(title: "Vintage Camera", description: "Classic film camera in working condition", category: .electronics, condition: .good, userId: UUID(), location: "New York", price: 150.00, priceIsFirm: true, isTradeItem: false),
            Item(title: "Children's Books Set", description: "Collection of 20 popular children's books", category: .books, condition: .likeNew, userId: UUID(), location: "Los Angeles", price: nil, priceIsFirm: false, isTradeItem: true),
            Item(title: "Bicycle", description: "Mountain bike, barely used", category: .sports, condition: .likeNew, userId: UUID(), location: "Chicago", price: 250.00, priceIsFirm: false, isTradeItem: false),
            Item(title: "Coffee Maker", description: "Espresso machine with milk frother", category: .home, condition: .good, userId: UUID(), location: "Seattle", price: nil, priceIsFirm: false, isTradeItem: true),
            Item(title: "Winter Jacket", description: "Warm winter jacket, size M", category: .clothing, condition: .new, userId: UUID(), location: "Boston", price: 75.99, priceIsFirm: true, isTradeItem: false)
        ]
    }
    
    func addItem(_ item: Item) {
        items.insert(item, at: 0)
        currentUser.itemsListed += 1
        currentUser.totalDonated += 1
    }
    
    func toggleFavorite(_ itemId: UUID) {
        if favorites.contains(itemId) {
            favorites.remove(itemId)
        } else {
            favorites.insert(itemId)
        }
    }
    
    func getFavoriteItems() -> [Item] {
        items.filter { favorites.contains($0.id) }
    }
    
    func removeItem(_ item: Item) {
        items.removeAll { $0.id == item.id }
    }
}