import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class DataManager: ObservableObject {
    @Published var items: [Item] = []
    @Published var favorites: Set<UUID> = []
    @Published var currentUser: User
    @Published var isDataLoaded = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    static let shared = DataManager()
    
    private let firestoreManager = FirestoreManager.shared
    private let storageManager = StorageManager.shared
    private var itemsListener: ListenerRegistration?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Initialize with a placeholder user
        self.currentUser = User(username: "Loading...", email: "")
        setupAuthStateListener()
        setupRealtimeListener()
    }
    
    deinit {
        itemsListener?.remove()
        if let authListener = authStateListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }
    
    // Setup auth state listener to sync user data
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    // Update current user with Firebase Auth data
                    await self.updateCurrentUser(from: firebaseUser)
                    
                    // Clear all data including sample data
                    self.clearAllData()
                    
                    // Re-setup listener for user-specific items
                    self.itemsListener?.remove()
                    self.setupRealtimeListener()
                    
                    // Reload data from Firebase
                    await self.loadData()
                } else {
                    // User signed out - clear all data
                    self.currentUser = User(username: "Not Signed In", email: "")
                    self.items.removeAll()
                    self.favorites.removeAll()
                    self.isDataLoaded = false
                }
            }
        }
    }
    
    // Update current user from Firebase Auth
    private func updateCurrentUser(from firebaseUser: FirebaseAuth.User) async {
        let username = firebaseUser.displayName ?? firebaseUser.email?.components(separatedBy: "@").first ?? "User"
        let email = firebaseUser.email ?? ""
        
        // Create a proper user object
        var newUser = User(
            id: UUID(), // Note: In production, you might want to use firebaseUser.uid as the ID
            username: username,
            email: email
        )
        
        // Update profile image URL if available
        if let photoURL = firebaseUser.photoURL {
            newUser.profileImageURL = photoURL.absoluteString
        }
        
        // Try to fetch additional user data from Firestore
        do {
            if let userData = try await firestoreManager.getUserProfile(userId: firebaseUser.uid) {
                if let name = userData["name"] as? String, !name.isEmpty {
                    newUser.username = name
                }
                if let avatar = userData["avatar"] as? String, !avatar.isEmpty {
                    newUser.profileImageURL = avatar
                }
                // You can add more fields here as needed
            }
        } catch {
            print("Error fetching user profile from Firestore: \(error)")
        }
        
        self.currentUser = newUser
    }
    
    // Setup real-time listener for items
    private func setupRealtimeListener() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("🔴 No authenticated user, showing all public items")
            // For non-authenticated users, show all items
            itemsListener = firestoreManager.listenToItems { [weak self] items in
                print("📥 Received \(items.count) public items from Firestore")
                DispatchQueue.main.async {
                    self?.items = items
                    self?.isDataLoaded = true
                }
            }
            return
        }
        
        print("🎧 Setting up Firestore listener for user: \(userId)")
        
        // For authenticated users, we'll still show all items but can filter later
        // In a real app, you might want to show only user's items + public items
        itemsListener = firestoreManager.listenToItems { [weak self] items in
            print("📥 Received \(items.count) items from Firestore")
            DispatchQueue.main.async {
                self?.items = items
                self?.isDataLoaded = true
            }
        }
    }
    
    // Get items for current user only
    func getCurrentUserItems() -> [Item] {
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("❌ getCurrentUserItems: No authenticated user")
            return [] 
        }
        
        print("🔍 getCurrentUserItems: Filtering for user: \(userId)")
        print("🔍 Total items in array: \(items.count)")
        
        let userItems = items.filter { item in
            // Check both firebaseUserId and legacy userId
            let matches = item.firebaseUserId == userId || item.userId.uuidString == userId
            if matches {
                print("✅ Found user item: \(item.title) - firebaseUserId: \(item.firebaseUserId ?? "nil")")
            }
            return matches
        }
        
        print("🔍 Found \(userItems.count) items for current user")
        return userItems
    }
    
    // Load data from Firebase or sample data for development
    func loadData() async {
        print("DataManager.loadData() called")
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        // Update user data if authenticated
        if let firebaseUser = Auth.auth().currentUser {
            await updateCurrentUser(from: firebaseUser)
        }
        
        // The real-time listener in setupRealtimeListener() will handle loading items
        // We just need to check if Firebase is empty and load sample data if needed
        
        try? await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5s for listener to fire
        
        await MainActor.run {
            // Never load sample data - only real items from authenticated users
            if items.isEmpty && !isDataLoaded {
                print("No items found in Firebase")
                // Don't load sample data anymore
            }
            isLoading = false
        }
    }
    
    // Load sample data locally (fallback)
    private func loadSampleDataLocally() {
        // Prevent loading data multiple times
        guard !isDataLoaded else { return }
        
        // Don't load sample data for authenticated users
        if Auth.auth().currentUser != nil && !(Auth.auth().currentUser?.isAnonymous ?? true) {
            print("Skipping sample data for authenticated user")
            isDataLoaded = true
            return
        }
        
        // Create items with various post times for "Just listed" badges
        let now = Date()
        items = [
            {
                var item = Item(title: "Free plants and succulents", description: "Moving out, giving away my plant collection. Includes cacti, succulents, and a small plant stand.", category: .homeKitchen, condition: .good, userId: UUID(), location: "Garden Grove", postedDate: now.addingTimeInterval(-3600), price: 0, priceIsFirm: false, isTradeItem: false, listingType: .giveAway, sellerUsername: "Emily Chen", sellerProfileImageURL: nil)
                item.images = [
                    "https://images.unsplash.com/photo-1459156212016-c812468e2115?w=400",
                    "https://images.unsplash.com/photo-1509423350716-97f9360b4e09?w=400",
                    "https://images.unsplash.com/photo-1463320898484-cdee8141c787?w=400",
                    "https://images.unsplash.com/photo-1493957988430-a5f2e15f39a3?w=400"
                ]
                return item
            }(),
            {
                var item = Item(title: "Restaurant robot server", description: "Commercial-grade autonomous serving robot. Perfect for restaurants or events. Barely used.", category: .electronics, condition: .likeNew, userId: UUID(), location: "Garden Grove", postedDate: now.addingTimeInterval(-7200), price: 300.00, priceIsFirm: false, isTradeItem: false, listingType: .sell, sellerUsername: "TechStartup Inc", sellerProfileImageURL: nil)
                item.images = [
                    "https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=400",
                    "https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=400",
                    "https://images.unsplash.com/photo-1546776310-eef45dd6d63c?w=400"
                ]
                return item
            }(),
            {
                var item = Item(title: "Bodhi Tree for sale", description: "Beautiful Bodhi tree (Ficus religiosa), about 3 feet tall. Sacred Buddhist tree, very healthy.", category: .homeKitchen, condition: .good, userId: UUID(), location: "Garden Grove", postedDate: now.addingTimeInterval(-3600 * 4), price: 50.00, priceIsFirm: false, isTradeItem: false, listingType: .sell, sellerUsername: "Buddhist Temple", sellerProfileImageURL: nil)
                item.images = ["https://images.unsplash.com/photo-1502394202744-021cfbb17454?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Old Japanese Silk Bonsai", description: "Rare vintage Japanese silk bonsai tree in ceramic pot. Artistic piece, great for decoration.", category: .homeKitchen, condition: .good, userId: UUID(), location: "Westminster", postedDate: now.addingTimeInterval(-3600 * 6), price: 780.00, priceIsFirm: true, isTradeItem: false, listingType: .sell, sellerUsername: "Kenji Yamamoto", sellerProfileImageURL: nil)
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
                var item = Item(title: "Espresso Coffee Machine", description: "Professional espresso machine with grinder. Makes amazing coffee!", category: .homeKitchen, condition: .good, userId: UUID(), location: "Anaheim", postedDate: now.addingTimeInterval(-3600 * 5), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Kitchen appliances", acceptableItems: "Stand mixer, air fryer, instant pot", openToOffers: true, listingType: .trade, sellerUsername: "Coffee Lover Mike", sellerProfileImageURL: nil)
                item.images = ["https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Need Help Moving Furniture", description: "Need 2-3 people to help move heavy furniture to second floor apartment this weekend. Pizza and drinks provided!", category: .miscellaneous, condition: .new, userId: UUID(), location: "Santa Ana", postedDate: now.addingTimeInterval(-3600 * 2), price: 0, priceIsFirm: false, isTradeItem: false, listingType: .needHelp, sellerUsername: "Sarah Martinez", sellerProfileImageURL: nil)
                item.images = ["https://images.unsplash.com/photo-1603664454146-50b9bb1e7afa?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Daily Carpool to Downtown LA", description: "Looking for carpool buddy. Leave 7:30am from Fountain Valley, return 5:30pm. Split gas costs.", category: .miscellaneous, condition: .new, userId: UUID(), location: "Fountain Valley", postedDate: now.addingTimeInterval(-86400 * 3), price: 0, priceIsFirm: false, isTradeItem: false, listingType: .carpool, sellerUsername: "David Kim", sellerProfileImageURL: nil)
                item.images = ["https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Community Beach Cleanup Event", description: "Join us for monthly beach cleanup! All supplies provided. Family friendly event.", category: .miscellaneous, condition: .new, userId: UUID(), location: "Costa Mesa", postedDate: now.addingTimeInterval(-3600 * 8), price: 0, priceIsFirm: true, isTradeItem: false, listingType: .event)
                item.images = ["https://images.unsplash.com/photo-1602848597941-0d3d3a2c0b34?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Looking for Lunch Buddy", description: "Tech worker seeking lunch companions downtown. Love trying new restaurants!", category: .miscellaneous, condition: .new, userId: UUID(), location: "Irvine", postedDate: now.addingTimeInterval(-3600), price: 0, priceIsFirm: false, isTradeItem: false, listingType: .lunchBuddy)
                item.images = ["https://images.unsplash.com/photo-1584736286279-9bbdeb77a19a?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Workout Partner Needed", description: "Looking for gym buddy at 24 Hour Fitness. Morning workouts, focusing on strength training.", category: .sportingGoods, condition: .new, userId: UUID(), location: "Huntington Beach", postedDate: now.addingTimeInterval(-86400 * 4), price: 0, priceIsFirm: false, isTradeItem: false, listingType: .workoutBuddy)
                item.images = ["https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Morning Walking Partner", description: "Senior seeking walking companion for daily morning walks at the park. 6am start, 1 hour walk.", category: .miscellaneous, condition: .new, userId: UUID(), location: "Long Beach", postedDate: now.addingTimeInterval(-3600 * 12), price: 0, priceIsFirm: false, isTradeItem: false, listingType: .walkingBuddy)
                item.images = ["https://images.unsplash.com/photo-1578303512597-81e6cc155b3e?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Outdoor Patio Set", description: "4-piece patio furniture set with cushions", category: .homeKitchen, condition: .good, userId: UUID(), location: "Fullerton", postedDate: now.addingTimeInterval(-3600 * 18), price: 225.00, priceIsFirm: false, isTradeItem: false, listingType: .sell)
                item.images = ["https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?w=400"]
                return item
            }(),
            // Additional items for different cities
            {
                var item = Item(title: "MacBook Pro 14\"", description: "2023 model, M3 chip, excellent condition", category: .electronics, condition: .likeNew, userId: UUID(), location: "Los Angeles", postedDate: now.addingTimeInterval(-3600 * 3), price: 1800.00, priceIsFirm: true, isTradeItem: false, listingType: .sell, sellerUsername: "Alex Thompson", sellerProfileImageURL: nil)
                item.images = ["https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Surfboard Collection", description: "3 boards, various sizes, great for beginners", category: .sportingGoods, condition: .good, userId: UUID(), location: "San Diego", postedDate: now.addingTimeInterval(-3600 * 6), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Bike or skateboard", openToOffers: true, listingType: .trade)
                item.images = ["https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Art Supplies Bundle", description: "Professional grade paints, brushes, canvases", category: .miscellaneous, condition: .new, userId: UUID(), location: "Los Angeles", postedDate: now.addingTimeInterval(-3600 * 2), price: 150.00, priceIsFirm: false, isTradeItem: false, listingType: .sell)
                item.images = ["https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Beach Cruiser Bike", description: "Vintage style, perfect for boardwalk rides", category: .sportingGoods, condition: .good, userId: UUID(), location: "San Diego", postedDate: now.addingTimeInterval(-3600 * 8), price: 0, priceIsFirm: false, isTradeItem: false, listingType: .giveAway)
                item.images = ["https://images.unsplash.com/photo-1545558014-8692077e9b5c?w=400"]
                return item
            }(),
            // New York items
            {
                var item = Item(title: "Broadway Show Tickets", description: "2 tickets to Hamilton, orchestra seats", category: .miscellaneous, condition: .new, userId: UUID(), location: "New York", postedDate: now.addingTimeInterval(-3600 * 4), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Concert tickets or sports memorabilia", openToOffers: true, listingType: .trade, sellerUsername: "TheaterFan212", sellerProfileImageURL: nil)
                item.images = ["https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Vintage NYC Subway Map", description: "1970s original MTA subway map, framed", category: .miscellaneous, condition: .good, userId: UUID(), location: "New York", postedDate: now.addingTimeInterval(-3600 * 5), price: 85.00, priceIsFirm: false, isTradeItem: false, listingType: .sell)
                item.images = ["https://images.unsplash.com/photo-1609607847926-da4702f01fef?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Central Park Picnic Set", description: "Complete set with blanket, basket, utensils", category: .homeKitchen, condition: .likeNew, userId: UUID(), location: "New York", postedDate: now.addingTimeInterval(-3600 * 2), price: 0, priceIsFirm: false, isTradeItem: false, listingType: .giveAway)
                item.images = ["https://images.unsplash.com/photo-1595853035070-59a39fe84de9?w=400"]
                return item
            }(),
            // Chicago items
            {
                var item = Item(title: "Cubs Memorabilia", description: "Signed baseball and vintage jersey", category: .sportingGoods, condition: .good, userId: UUID(), location: "Chicago", postedDate: now.addingTimeInterval(-3600 * 3), price: 250.00, priceIsFirm: true, isTradeItem: false, listingType: .sell)
                item.images = ["https://images.unsplash.com/photo-1566479179474-c2e47c13cf50?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Deep Dish Pizza Stone", description: "Authentic Chicago-style pizza making kit", category: .homeKitchen, condition: .new, userId: UUID(), location: "Chicago", postedDate: now.addingTimeInterval(-3600 * 7), price: 45.00, priceIsFirm: false, isTradeItem: false, listingType: .sell)
                item.images = ["https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400"]
                return item
            }(),
            // Miami items
            {
                var item = Item(title: "Beach Volleyball Set", description: "Professional net and Wilson balls", category: .sportingGoods, condition: .good, userId: UUID(), location: "Miami", postedDate: now.addingTimeInterval(-3600 * 4), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Paddleboard or snorkel gear", openToOffers: true, listingType: .trade)
                item.images = ["https://images.unsplash.com/photo-1612872087720-bb876e2e67d1?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Art Deco Lamp", description: "Vintage Miami Beach style lamp", category: .homeKitchen, condition: .good, userId: UUID(), location: "Miami", postedDate: now.addingTimeInterval(-3600 * 6), price: 120.00, priceIsFirm: false, isTradeItem: false, listingType: .sell)
                item.images = ["https://images.unsplash.com/photo-1565636192437-9c5dd59a75a9?w=400"]
                return item
            }(),
            // New Orleans items
            {
                var item = Item(title: "Jazz Trumpet", description: "Professional B♭ trumpet, perfect tone", category: .miscellaneous, condition: .good, userId: UUID(), location: "New Orleans", postedDate: now.addingTimeInterval(-3600 * 2), price: 350.00, priceIsFirm: false, isTradeItem: false, listingType: .sell)
                item.images = ["https://images.unsplash.com/photo-1511192336575-5a79af67a629?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Mardi Gras Beads Collection", description: "Authentic throws from 20+ years of parades", category: .miscellaneous, condition: .likeNew, userId: UUID(), location: "New Orleans", postedDate: now.addingTimeInterval(-3600 * 3), price: 0, priceIsFirm: false, isTradeItem: false, listingType: .giveAway)
                item.images = ["https://images.unsplash.com/photo-1581235707960-4b6b66864b12?w=400"]
                return item
            }(),
            {
                var item = Item(title: "Cajun Cookbook Set", description: "5 classic Louisiana cookbooks", category: .miscellaneous, condition: .good, userId: UUID(), location: "New Orleans", postedDate: now.addingTimeInterval(-3600 * 5), price: 25.00, priceIsFirm: false, isTradeItem: false, listingType: .sell)
                item.images = ["https://images.unsplash.com/photo-1466637574441-749b8f19452f?w=400"]
                return item
            }(),
            {
                var item = Item(title: "French Quarter Art Print", description: "Limited edition signed print", category: .homeKitchen, condition: .new, userId: UUID(), location: "New Orleans", postedDate: now.addingTimeInterval(-3600), price: nil, priceIsFirm: false, isTradeItem: true, lookingFor: "Local artwork or photography", openToOffers: true, listingType: .trade)
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
        
        isDataLoaded = true
    }
    
    // Clear all local data (useful when user signs in/out)
    func clearAllData() {
        items.removeAll()
        favorites.removeAll()
        isDataLoaded = false
    }
    
    // Load sample data to Firebase (for first-time setup)
    private func loadSampleDataToFirebase() async {
        loadSampleDataLocally() // Create the items array
        
        // Upload sample items to Firebase
        for item in items {
            do {
                _ = try await firestoreManager.createItem(item)
            } catch {
                print("Failed to upload sample item: \(item.title), error: \(error)")
            }
        }
    }
    
    // Add item with Firebase integration
    func addItem(_ item: Item, images: [UIImage] = []) async {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            var newItem = item
            
            // Set the Firebase user ID
            if let firebaseUserId = AuthenticationManager.shared.currentUserId {
                newItem.firebaseUserId = firebaseUserId
            }
            
            // Set seller information from current user
            newItem.sellerUsername = currentUser.username
            newItem.sellerProfileImageURL = currentUser.profileImageURL
            
            // Set isNearby flag based on location
            let nearbyCities = ["Garden Grove", "Westminster", "Anaheim", "Santa Ana", "Fountain Valley", "Huntington Beach", "Costa Mesa", "Irvine"]
            newItem.isNearby = nearbyCities.contains { city in
                newItem.location.lowercased().contains(city.lowercased())
            }
            
            print("🔵 Adding new item: \(newItem.title)")
            print("🔵 User ID (UUID): \(newItem.userId)")
            print("🔵 Firebase Auth UID: \(newItem.firebaseUserId ?? "nil")")
            print("🔵 Seller: \(newItem.sellerUsername ?? "Unknown")")
            print("🔵 Location: \(newItem.location) - isNearby: \(newItem.isNearby)")
            
            // Upload images first if any
            if !images.isEmpty {
                print("🔵 Uploading \(images.count) images...")
                let itemId = UUID().uuidString
                let optimizedImages = images.map { storageManager.optimizeImageForUpload($0) }
                let imageUrls = try await storageManager.uploadItemImages(optimizedImages, itemId: itemId)
                newItem.images = imageUrls
                print("🔵 Images uploaded successfully: \(imageUrls)")
            }
            
            // Create item in Firestore
            print("🔵 Creating item in Firestore...")
            let documentId = try await firestoreManager.createItem(newItem)
            print("✅ Item created successfully with ID: \(documentId)")
            
            // The real-time listener will automatically update the local items array
            
            // Update local state
            await MainActor.run {
                currentUser.itemsListed += 1
                currentUser.totalDonated += 1
            }
            
        } catch {
            print("❌ Error adding item: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // Update existing item
    func updateItem(_ item: Item, newImages: [UIImage] = []) async {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            var updatedItem = item
            
            // Set the Firebase user ID if not already set
            if updatedItem.firebaseUserId == nil {
                if let firebaseUserId = AuthenticationManager.shared.currentUserId {
                    updatedItem.firebaseUserId = firebaseUserId
                }
            }
            
            // Update seller information from current user
            updatedItem.sellerUsername = currentUser.username
            updatedItem.sellerProfileImageURL = currentUser.profileImageURL
            
            // Update isNearby flag based on location
            let nearbyCities = ["Garden Grove", "Westminster", "Anaheim", "Santa Ana", "Fountain Valley", "Huntington Beach", "Costa Mesa", "Irvine"]
            updatedItem.isNearby = nearbyCities.contains { city in
                updatedItem.location.lowercased().contains(city.lowercased())
            }
            
            print("🔵 Updating item: \(updatedItem.title)")
            print("🔵 Item ID: \(updatedItem.id)")
            
            // Upload new images if provided
            if !newImages.isEmpty {
                print("🔵 Uploading \(newImages.count) new images...")
                let itemId = updatedItem.id.uuidString
                let optimizedImages = newImages.map { storageManager.optimizeImageForUpload($0) }
                let imageUrls = try await storageManager.uploadItemImages(optimizedImages, itemId: itemId)
                updatedItem.images = imageUrls
                print("🔵 Images uploaded successfully: \(imageUrls)")
            }
            
            // Update item in Firestore
            print("🔵 Updating item in Firestore...")
            try await firestoreManager.updateItem(itemId: updatedItem.id.uuidString, data: updatedItem.toDictionary())
            print("✅ Item updated successfully")
            
            // Update local state immediately
            await MainActor.run {
                if let index = self.items.firstIndex(where: { $0.id == updatedItem.id }) {
                    self.items[index] = updatedItem
                }
            }
            
        } catch {
            print("❌ Error updating item: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // Delete item with Firebase integration
    func deleteItem(_ item: Item) async {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            // Delete from Firestore (use the document ID if available)
            // Note: You might need to store the Firestore document ID in your Item model
            
            // Delete images from Storage
            if !item.images.isEmpty {
                await storageManager.deleteImages(urls: item.images)
            }
            
            // Remove from local state (real-time listener will handle this automatically)
            await MainActor.run {
                items.removeAll { $0.id == item.id }
            }
            
        } catch {
            print("Error deleting item: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
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
    
    // Search items
    func searchItems(query: String, category: String? = nil, location: String? = nil) async {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            let searchResults = try await firestoreManager.searchItems(
                query: query,
                category: category,
                location: location
            )
            
            await MainActor.run {
                items = searchResults
            }
        } catch {
            print("Error searching items: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // Refresh data
    func refreshData() async {
        await loadData()
    }
    
    func removeItem(_ item: Item) {
        items.removeAll { $0.id == item.id }
    }
}