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
        // Create items with various post times for "Just listed" badges
        let now = Date()
        items = [
            Item(title: "Free plants and succulents", description: "Moving out, giving away my plant collection. Includes cacti, succulents, and a small plant stand.", category: .home, condition: .good, userId: UUID(), location: "Garden Grove", postedDate: now.addingTimeInterval(-3600), price: 0, priceIsFirm: false, isTradeItem: false),
            Item(title: "Restaurant robot server", description: "Commercial-grade autonomous serving robot. Perfect for restaurants or events. Barely used.", category: .electronics, condition: .likeNew, userId: UUID(), location: "Garden Grove", postedDate: now.addingTimeInterval(-7200), price: 300.00, priceIsFirm: false, isTradeItem: false),
            Item(title: "Bodhi Tree for sale", description: "Beautiful Bodhi tree (Ficus religiosa), about 3 feet tall. Sacred Buddhist tree, very healthy.", category: .home, condition: .good, userId: UUID(), location: "Garden Grove", postedDate: now.addingTimeInterval(-86400 * 2), price: 50.00, priceIsFirm: false, isTradeItem: false),
            Item(title: "Old Japanese Silk Bonsai", description: "Rare vintage Japanese silk bonsai tree in ceramic pot. Artistic piece, great for decoration.", category: .home, condition: .good, userId: UUID(), location: "Westminster", postedDate: now.addingTimeInterval(-86400), price: 780.00, priceIsFirm: true, isTradeItem: false),
            Item(title: "Espresso Coffee Machine", description: "Professional espresso machine with grinder. Makes amazing coffee!", category: .home, condition: .good, userId: UUID(), location: "Anaheim", postedDate: now.addingTimeInterval(-3600 * 5), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Kitchen appliances", acceptableItems: "Stand mixer, air fryer, instant pot", openToOffers: true),
            Item(title: "Kids Play Kitchen Set", description: "Wooden play kitchen with accessories. Great for imaginative play!", category: .toys, condition: .likeNew, userId: UUID(), location: "Santa Ana", postedDate: now.addingTimeInterval(-3600 * 2), price: 45.00, priceIsFirm: false, isTradeItem: false),
            Item(title: "Gaming Chair", description: "Ergonomic gaming chair with RGB lighting. Very comfortable!", category: .electronics, condition: .good, userId: UUID(), location: "Fountain Valley", postedDate: now.addingTimeInterval(-86400 * 3), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Gaming accessories or desk", acceptableItems: "Gaming keyboard, monitor, desk", openToOffers: true),
            Item(title: "Vintage Vinyl Records", description: "Collection of 50+ classic rock and jazz vinyl records", category: .other, condition: .good, userId: UUID(), location: "Costa Mesa", postedDate: now.addingTimeInterval(-3600 * 8), price: 120.00, priceIsFirm: true, isTradeItem: false),
            Item(title: "Baby Stroller System", description: "Travel system with car seat and base. Like new condition.", category: .other, condition: .likeNew, userId: UUID(), location: "Irvine", postedDate: now.addingTimeInterval(-3600), price: 0, priceIsFirm: false, isTradeItem: false),
            Item(title: "Mountain Bike 26\"", description: "Trek mountain bike, 21 speeds, includes helmet", category: .sports, condition: .good, userId: UUID(), location: "Huntington Beach", postedDate: now.addingTimeInterval(-86400 * 4), price: 185.00, priceIsFirm: false, isTradeItem: false),
            Item(title: "Nintendo Switch Games", description: "Bundle of 5 popular Switch games", category: .electronics, condition: .likeNew, userId: UUID(), location: "Long Beach", postedDate: now.addingTimeInterval(-3600 * 12), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "PS5 games or Xbox games", acceptableItems: "Any current gen games", openToOffers: true),
            Item(title: "Outdoor Patio Set", description: "4-piece patio furniture set with cushions", category: .home, condition: .good, userId: UUID(), location: "Fullerton", postedDate: now.addingTimeInterval(-3600 * 18), price: 225.00, priceIsFirm: false, isTradeItem: false),
            // Additional items for different cities
            Item(title: "MacBook Pro 14\"", description: "2023 model, M3 chip, excellent condition", category: .electronics, condition: .likeNew, userId: UUID(), location: "Los Angeles", postedDate: now.addingTimeInterval(-3600 * 3), price: 1800.00, priceIsFirm: true, isTradeItem: false),
            Item(title: "Surfboard Collection", description: "3 boards, various sizes, great for beginners", category: .sports, condition: .good, userId: UUID(), location: "San Diego", postedDate: now.addingTimeInterval(-3600 * 6), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Bike or skateboard", openToOffers: true),
            Item(title: "Art Supplies Bundle", description: "Professional grade paints, brushes, canvases", category: .other, condition: .new, userId: UUID(), location: "Los Angeles", postedDate: now.addingTimeInterval(-3600 * 2), price: 150.00, priceIsFirm: false, isTradeItem: false),
            Item(title: "Beach Cruiser Bike", description: "Vintage style, perfect for boardwalk rides", category: .sports, condition: .good, userId: UUID(), location: "San Diego", postedDate: now.addingTimeInterval(-3600 * 8), price: 0, priceIsFirm: false, isTradeItem: false),
            // New York items
            Item(title: "Broadway Show Tickets", description: "2 tickets to Hamilton, orchestra seats", category: .other, condition: .new, userId: UUID(), location: "New York", postedDate: now.addingTimeInterval(-3600 * 4), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Concert tickets or sports memorabilia", openToOffers: true),
            Item(title: "Vintage NYC Subway Map", description: "1970s original MTA subway map, framed", category: .other, condition: .good, userId: UUID(), location: "New York", postedDate: now.addingTimeInterval(-3600 * 5), price: 85.00, priceIsFirm: false, isTradeItem: false),
            Item(title: "Central Park Picnic Set", description: "Complete set with blanket, basket, utensils", category: .home, condition: .likeNew, userId: UUID(), location: "New York", postedDate: now.addingTimeInterval(-3600 * 2), price: 0, priceIsFirm: false, isTradeItem: false),
            // Chicago items
            Item(title: "Cubs Memorabilia", description: "Signed baseball and vintage jersey", category: .sports, condition: .good, userId: UUID(), location: "Chicago", postedDate: now.addingTimeInterval(-3600 * 3), price: 250.00, priceIsFirm: true, isTradeItem: false),
            Item(title: "Deep Dish Pizza Stone", description: "Authentic Chicago-style pizza making kit", category: .home, condition: .new, userId: UUID(), location: "Chicago", postedDate: now.addingTimeInterval(-3600 * 7), price: 45.00, priceIsFirm: false, isTradeItem: false),
            // Miami items
            Item(title: "Beach Volleyball Set", description: "Professional net and Wilson balls", category: .sports, condition: .good, userId: UUID(), location: "Miami", postedDate: now.addingTimeInterval(-3600 * 4), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Paddleboard or snorkel gear", openToOffers: true),
            Item(title: "Art Deco Lamp", description: "Vintage Miami Beach style lamp", category: .home, condition: .good, userId: UUID(), location: "Miami", postedDate: now.addingTimeInterval(-3600 * 6), price: 120.00, priceIsFirm: false, isTradeItem: false),
            // New Orleans items
            Item(title: "Jazz Trumpet", description: "Professional B♭ trumpet, perfect tone", category: .other, condition: .good, userId: UUID(), location: "New Orleans", postedDate: now.addingTimeInterval(-3600 * 2), price: 350.00, priceIsFirm: false, isTradeItem: false),
            Item(title: "Mardi Gras Beads Collection", description: "Authentic throws from 20+ years of parades", category: .other, condition: .likeNew, userId: UUID(), location: "New Orleans", postedDate: now.addingTimeInterval(-3600 * 3), price: 0, priceIsFirm: false, isTradeItem: false),
            Item(title: "Cajun Cookbook Set", description: "5 classic Louisiana cookbooks", category: .other, condition: .good, userId: UUID(), location: "New Orleans", postedDate: now.addingTimeInterval(-3600 * 5), price: 25.00, priceIsFirm: false, isTradeItem: false),
            Item(title: "French Quarter Art Print", description: "Limited edition signed print", category: .home, condition: .new, userId: UUID(), location: "New Orleans", postedDate: now.addingTimeInterval(-3600), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Local artwork or photography", openToOffers: true)
        ]
        
        // Mark items in nearby cities as nearby
        let nearbyCities = ["Garden Grove", "Westminster", "Anaheim", "Santa Ana"]
        for index in items.indices {
            if nearbyCities.contains(where: { items[index].location.contains($0) }) {
                items[index].isNearby = true
            }
        }
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