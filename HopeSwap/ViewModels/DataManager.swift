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
            {
                var item = Item(title: "Free plants and succulents", description: "Moving out, giving away my plant collection. Includes cacti, succulents, and a small plant stand.", category: .homeKitchen, condition: .good, userId: UUID(), location: "Garden Grove", postedDate: now.addingTimeInterval(-3600), price: 0, priceIsFirm: false, isTradeItem: false)
                item.images = [
                    "https://images.unsplash.com/photo-1459156212016-c812468e2115?w=400",
                    "https://images.unsplash.com/photo-1509423350716-97f9360b4e09?w=400",
                    "https://images.unsplash.com/photo-1463320898484-cdee8141c787?w=400",
                    "https://images.unsplash.com/photo-1493957988430-a5f2e15f39a3?w=400"
                ]
                return item
            }(),
            {
                var item = Item(title: "Restaurant robot server", description: "Commercial-grade autonomous serving robot. Perfect for restaurants or events. Barely used.", category: .electronics, condition: .likeNew, userId: UUID(), location: "Garden Grove", postedDate: now.addingTimeInterval(-7200), price: 300.00, priceIsFirm: false, isTradeItem: false)
                item.images = [
                    "https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=400",
                    "https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=400",
                    "https://images.unsplash.com/photo-1546776310-eef45dd6d63c?w=400"
                ]
                return item
            }(),
            {
                var item = Item(title: "Bodhi Tree for sale", description: "Beautiful Bodhi tree (Ficus religiosa), about 3 feet tall. Sacred Buddhist tree, very healthy.", category: .homeKitchen, condition: .good, userId: UUID(), location: "Garden Grove", postedDate: now.addingTimeInterval(-86400 * 2), price: 50.00, priceIsFirm: false, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1502394202744-021cfbb17454?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Old Japanese Silk Bonsai", description: "Rare vintage Japanese silk bonsai tree in ceramic pot. Artistic piece, great for decoration.", category: .homeKitchen, condition: .good, userId: UUID(), location: "Westminster", postedDate: now.addingTimeInterval(-86400), price: 780.00, priceIsFirm: true, isTradeItem: false)
                item.images = [
                    "https://images.unsplash.com/photo-1467043198406-dc953a3defa0?w=400",
                    "https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=400",
                    "https://images.unsplash.com/photo-1512428813834-c702c7702b78?w=400",
                    "https://images.unsplash.com/photo-1490312278390-ab64016e0aa9?w=400",
                    "https://images.unsplash.com/photo-1545239351-1a1c0814f912?w=400"
                ]
                return item
            }(),
            {
                var item = Item(title: "Espresso Coffee Machine", description: "Professional espresso machine with grinder. Makes amazing coffee!", category: .homeKitchen, condition: .good, userId: UUID(), location: "Anaheim", postedDate: now.addingTimeInterval(-3600 * 5), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Kitchen appliances", acceptableItems: "Stand mixer, air fryer, instant pot", openToOffers: true)
                item.images = ["https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Kids Play Kitchen Set", description: "Wooden play kitchen with accessories. Great for imaginative play!", category: .toysGames, condition: .likeNew, userId: UUID(), location: "Santa Ana", postedDate: now.addingTimeInterval(-3600 * 2), price: 45.00, priceIsFirm: false, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1603664454146-50b9bb1e7afa?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Gaming Chair", description: "Ergonomic gaming chair with RGB lighting. Very comfortable!", category: .electronics, condition: .good, userId: UUID(), location: "Fountain Valley", postedDate: now.addingTimeInterval(-86400 * 3), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Gaming accessories or desk", acceptableItems: "Gaming keyboard, monitor, desk", openToOffers: true)
                item.images = ["https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Vintage Vinyl Records", description: "Collection of 50+ classic rock and jazz vinyl records", category: .miscellaneous, condition: .good, userId: UUID(), location: "Costa Mesa", postedDate: now.addingTimeInterval(-3600 * 8), price: 120.00, priceIsFirm: true, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1602848597941-0d3d3a2c0b34?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Baby Stroller System", description: "Travel system with car seat and base. Like new condition.", category: .miscellaneous, condition: .likeNew, userId: UUID(), location: "Irvine", postedDate: now.addingTimeInterval(-3600), price: 0, priceIsFirm: false, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1584736286279-9bbdeb77a19a?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Mountain Bike 26\"", description: "Trek mountain bike, 21 speeds, includes helmet", category: .sportingGoods, condition: .good, userId: UUID(), location: "Huntington Beach", postedDate: now.addingTimeInterval(-86400 * 4), price: 185.00, priceIsFirm: false, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Nintendo Switch Games", description: "Bundle of 5 popular Switch games", category: .electronics, condition: .likeNew, userId: UUID(), location: "Long Beach", postedDate: now.addingTimeInterval(-3600 * 12), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "PS5 games or Xbox games", acceptableItems: "Any current gen games", openToOffers: true)
                item.images = ["https://images.unsplash.com/photo-1578303512597-81e6cc155b3e?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Outdoor Patio Set", description: "4-piece patio furniture set with cushions", category: .homeKitchen, condition: .good, userId: UUID(), location: "Fullerton", postedDate: now.addingTimeInterval(-3600 * 18), price: 225.00, priceIsFirm: false, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?w=400"]
                return item
            }(),
            // Additional items for different cities
            {
                var item = Item(title: "MacBook Pro 14\"", description: "2023 model, M3 chip, excellent condition", category: .electronics, condition: .likeNew, userId: UUID(), location: "Los Angeles", postedDate: now.addingTimeInterval(-3600 * 3), price: 1800.00, priceIsFirm: true, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Surfboard Collection", description: "3 boards, various sizes, great for beginners", category: .sportingGoods, condition: .good, userId: UUID(), location: "San Diego", postedDate: now.addingTimeInterval(-3600 * 6), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Bike or skateboard", openToOffers: true)
                item.images = ["https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Art Supplies Bundle", description: "Professional grade paints, brushes, canvases", category: .miscellaneous, condition: .new, userId: UUID(), location: "Los Angeles", postedDate: now.addingTimeInterval(-3600 * 2), price: 150.00, priceIsFirm: false, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Beach Cruiser Bike", description: "Vintage style, perfect for boardwalk rides", category: .sportingGoods, condition: .good, userId: UUID(), location: "San Diego", postedDate: now.addingTimeInterval(-3600 * 8), price: 0, priceIsFirm: false, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1545558014-8692077e9b5c?w=400"]
                return item
            }(),
            // New York items
            {
                var item = Item(title: "Broadway Show Tickets", description: "2 tickets to Hamilton, orchestra seats", category: .miscellaneous, condition: .new, userId: UUID(), location: "New York", postedDate: now.addingTimeInterval(-3600 * 4), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Concert tickets or sports memorabilia", openToOffers: true)
                item.images = ["https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Vintage NYC Subway Map", description: "1970s original MTA subway map, framed", category: .miscellaneous, condition: .good, userId: UUID(), location: "New York", postedDate: now.addingTimeInterval(-3600 * 5), price: 85.00, priceIsFirm: false, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1609607847926-da4702f01fef?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Central Park Picnic Set", description: "Complete set with blanket, basket, utensils", category: .homeKitchen, condition: .likeNew, userId: UUID(), location: "New York", postedDate: now.addingTimeInterval(-3600 * 2), price: 0, priceIsFirm: false, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1595853035070-59a39fe84de9?w=400"]
                return item
            }(),
            // Chicago items
            {
                var item = Item(title: "Cubs Memorabilia", description: "Signed baseball and vintage jersey", category: .sportingGoods, condition: .good, userId: UUID(), location: "Chicago", postedDate: now.addingTimeInterval(-3600 * 3), price: 250.00, priceIsFirm: true, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1566479179474-c2e47c13cf50?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Deep Dish Pizza Stone", description: "Authentic Chicago-style pizza making kit", category: .homeKitchen, condition: .new, userId: UUID(), location: "Chicago", postedDate: now.addingTimeInterval(-3600 * 7), price: 45.00, priceIsFirm: false, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400"]
                return item
            }(),
            // Miami items
            {
                var item = Item(title: "Beach Volleyball Set", description: "Professional net and Wilson balls", category: .sportingGoods, condition: .good, userId: UUID(), location: "Miami", postedDate: now.addingTimeInterval(-3600 * 4), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Paddleboard or snorkel gear", openToOffers: true)
                item.images = ["https://images.unsplash.com/photo-1612872087720-bb876e2e67d1?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Art Deco Lamp", description: "Vintage Miami Beach style lamp", category: .homeKitchen, condition: .good, userId: UUID(), location: "Miami", postedDate: now.addingTimeInterval(-3600 * 6), price: 120.00, priceIsFirm: false, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1565636192437-9c5dd59a75a9?w=400"]
                return item
            }(),
            // New Orleans items
            {
                var item = Item(title: "Jazz Trumpet", description: "Professional B♭ trumpet, perfect tone", category: .miscellaneous, condition: .good, userId: UUID(), location: "New Orleans", postedDate: now.addingTimeInterval(-3600 * 2), price: 350.00, priceIsFirm: false, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1511192336575-5a79af67a629?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Mardi Gras Beads Collection", description: "Authentic throws from 20+ years of parades", category: .miscellaneous, condition: .likeNew, userId: UUID(), location: "New Orleans", postedDate: now.addingTimeInterval(-3600 * 3), price: 0, priceIsFirm: false, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1581235707960-4b6b66864b12?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Cajun Cookbook Set", description: "5 classic Louisiana cookbooks", category: .miscellaneous, condition: .good, userId: UUID(), location: "New Orleans", postedDate: now.addingTimeInterval(-3600 * 5), price: 25.00, priceIsFirm: false, isTradeItem: false)
                item.images = ["https://images.unsplash.com/photo-1466637574441-749b8f19452f?w=400"]
                return item
            }(),
            {
                var item = Item(title: "French Quarter Art Print", description: "Limited edition signed print", category: .homeKitchen, condition: .new, userId: UUID(), location: "New Orleans", postedDate: now.addingTimeInterval(-3600), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Local artwork or photography", openToOffers: true)
                item.images = ["https://images.unsplash.com/photo-1568693059993-a239b9cd4957?w=400"]
                return item
            }()
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