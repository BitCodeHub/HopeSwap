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
                    self?.checkItemsWithoutFirebaseUserId()
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
                self?.checkItemsWithoutFirebaseUserId()
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
    
    // Initialize analytics fields for all items
    func initializeAllAnalyticsFields() async {
        print("🔧 Initializing analytics fields for all items...")
        do {
            // First migrate any items to use UUID as document ID
            try await firestoreManager.migrateItemsToUseUUIDAsDocumentId()
            
            // Then initialize analytics fields
            let allItems = try await firestoreManager.fetchItems(limit: 1000)
            print("🔧 Found \(allItems.count) items to check")
            
            var initialized = 0
            for item in allItems {
                try await firestoreManager.initializeAnalyticsFields(itemId: item.id.uuidString)
                initialized += 1
                if initialized % 10 == 0 {
                    print("🔧 Initialized \(initialized) items...")
                }
            }
            
            print("✅ Analytics fields initialized for \(initialized) items")
        } catch {
            print("❌ Error initializing analytics fields: \(error)")
        }
    }
    
    // Fix items without firebaseUserId set
    func fixItemsWithoutFirebaseUserId() async {
        print("🔧 Checking for items without firebaseUserId...")
        do {
            let allItems = try await firestoreManager.fetchItems(limit: 1000)
            var itemsFixed = 0
            
            for item in allItems {
                // Skip if firebaseUserId is already set
                if let firebaseUserId = item.firebaseUserId, !firebaseUserId.isEmpty {
                    continue
                }
                
                // For items without firebaseUserId, we can't automatically determine the correct Firebase UID
                // Log these items for manual review
                print("⚠️ Item without firebaseUserId found:")
                print("   - Title: \(item.title)")
                print("   - ID: \(item.id)")
                print("   - userId (UUID): \(item.userId)")
                print("   - Seller: \(item.sellerUsername ?? "Unknown")")
                
                itemsFixed += 1
            }
            
            if itemsFixed > 0 {
                print("⚠️ Found \(itemsFixed) items without firebaseUserId. These items won't support messaging until manually updated.")
            } else {
                print("✅ All items have firebaseUserId set")
            }
        } catch {
            print("❌ Error checking items: \(error)")
        }
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
        
        // Initialize analytics fields for all items (run once)
        if UserDefaults.standard.bool(forKey: "hasInitializedAnalytics") == false {
            await initializeAllAnalyticsFields()
            UserDefaults.standard.set(true, forKey: "hasInitializedAnalytics")
        }
        
        // Check for items without firebaseUserId (run once)
        if UserDefaults.standard.bool(forKey: "hasCheckedFirebaseUserIds") == false {
            await fixItemsWithoutFirebaseUserId()
            UserDefaults.standard.set(true, forKey: "hasCheckedFirebaseUserIds")
        }
        
        await MainActor.run {
            // Never load sample data - only real items from authenticated users
            if items.isEmpty && !isDataLoaded {
                print("No items found in Firebase")
                // Don't load sample data anymore
            }
            isLoading = false
        }
    }
    
    // Create a test item owned by current user (for testing edit/delete functionality)
    func createTestOwnedItem() async {
        guard let currentUserId = AuthenticationManager.shared.currentUserId else {
            print("❌ Cannot create test item: No authenticated user")
            return
        }
        
        let testItem = Item(
            title: "Test Nintendo Switch - Animal Crossing Edition",
            description: "This is a test item to demonstrate edit/delete functionality. Special Edition console with custom design.",
            category: .electronics,
            condition: .likeNew,
            userId: UUID(),
            firebaseUserId: currentUserId, // Set current user as owner
            location: "Garden Grove",
            postedDate: Date(),
            price: 299.99,
            priceIsFirm: false,
            isTradeItem: false,
            listingType: .sell,
            sellerUsername: currentUser.username,
            sellerProfileImageURL: currentUser.profileImageURL
        )
        
        // Add test images
        var itemWithImages = testItem
        itemWithImages.images = [
            "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400", // Nintendo Switch image
            "https://images.unsplash.com/photo-1585857189141-003ab7bbbe10?w=400"
        ]
        
        print("🧪 Creating test item owned by current user: \(currentUserId)")
        await addItem(itemWithImages)
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
                var item = Item(title: "Free plants and succulents", description: "Moving out and need to find a good home for my beloved plant collection!\n\n**What's Included:**\n• 3 different varieties of cacti (barrel, bunny ear, and pincushion)\n• 5 assorted succulents in 4\" pots\n• 1 large jade plant (about 2ft tall)\n• Various propagated succulent babies\n• Small wooden plant stand (holds 4 pots)\n\n**Condition:**\nAll plants are healthy and well-maintained. Some pots have minor wear but all are functional. The plant stand is sturdy pine wood with a natural finish.\n\n**Pickup Details:**\nMust take everything - not splitting up the collection. Available for pickup this weekend only. Please bring your own boxes/containers for transport.\n\nFirst come, first served!", category: .homeKitchen, condition: .good, userId: UUID(), location: "Garden Grove", postedDate: now.addingTimeInterval(-3600), price: 0, priceIsFirm: false, isTradeItem: false, listingType: .giveAway, sellerUsername: "Emily Chen", sellerProfileImageURL: nil)
                item.images = [
                    "https://images.unsplash.com/photo-1459156212016-c812468e2115?w=400",
                    "https://images.unsplash.com/photo-1509423350716-97f9360b4e09?w=400",
                    "https://images.unsplash.com/photo-1463320898484-cdee8141c787?w=400",
                    "https://images.unsplash.com/photo-1493957988430-a5f2e15f39a3?w=400"
                ]
                return item
            }(),
            {
                var item = Item(title: "Restaurant robot server", description: "**Professional Autonomous Serving Robot - Model SR-2000**\n\nOur startup is pivoting, so we're selling our barely-used restaurant serving robot at a fraction of the original cost!\n\n**Key Features:**\n- Multi-level serving trays (3 tiers)\n- Advanced obstacle avoidance sensors\n- 8-hour battery life per charge\n- Touch screen interface for easy programming\n- Voice announcement capability\n- Can carry up to 40kg (88lbs)\n\n**Technical Specifications:**\n- Dimensions: 55cm x 55cm x 125cm\n- Speed: 0.5-1.2 m/s (adjustable)\n- Navigation: LIDAR + Visual SLAM\n- Connectivity: WiFi, Bluetooth\n- Charging time: 4-6 hours\n\n**What's Included:**\n- SR-2000 Robot Server\n- Charging dock\n- Tablet controller\n- Original manual and setup guide\n- 1-year warranty still valid (transferable)\n\n**Condition Notes:**\nUsed for only 3 months in our pilot program. Minor scuff on the base from normal use, otherwise in excellent condition. All sensors and systems fully functional.\n\n**Original Price:** $8,500\n**Asking Price:** $3,000 (negotiable for serious buyers)", category: .electronics, condition: .likeNew, userId: UUID(), location: "Garden Grove", postedDate: now.addingTimeInterval(-7200), price: 300.00, priceIsFirm: false, isTradeItem: false, listingType: .sell, sellerUsername: "TechStartup Inc", sellerProfileImageURL: nil)
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
                var item = Item(title: "Old Japanese Silk Bonsai", description: "**Exquisite Vintage Japanese Silk Bonsai Collection**\n\nA rare opportunity to own an authentic piece of Japanese artistry from the 1970s.\n\n**About This Piece:**\nThis handcrafted silk bonsai represents the traditional Japanese art of creating lifelike artificial trees. Made by master craftsmen in Kyoto, each branch and leaf has been carefully positioned to mirror the natural growth patterns of a living bonsai.\n\n**Details:**\n• Age: Circa 1975-1980\n• Style: Formal upright (Chokkan)\n• Tree type: Pine replica\n• Height: 18 inches (including pot)\n• Spread: 22 inches\n\n**Craftsmanship Features:**\n- Hand-dyed silk leaves with realistic texture\n- Wire-wrapped branches for authentic shaping\n- Traditional moss ground cover\n- Genuine Tokoname ceramic pot (signed)\n- Original wooden display stand included\n\n**Historical Significance:**\nThis piece comes from the estate of a Japanese diplomat who served in Los Angeles during the 1970s. It was displayed in the consulate's reception area for many years.\n\n**Condition:**\nExcellent vintage condition with minor fading on some leaves that adds to its authentic aged appearance. No tears or damage to the silk. Ceramic pot has beautiful patina.\n\n**Why Silk Bonsai?**\nIn Japanese culture, high-quality silk bonsai are valued for their eternal beauty and zero maintenance. They're often passed down through generations as family heirlooms.\n\n**Price is firm** - Comparable pieces sell for $1,200+ at Japanese antique dealers.", category: .homeKitchen, condition: .good, userId: UUID(), location: "Westminster", postedDate: now.addingTimeInterval(-3600 * 6), price: 780.00, priceIsFirm: true, isTradeItem: false, listingType: .sell, sellerUsername: "Kenji Yamamoto", sellerProfileImageURL: nil)
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
                var item = Item(title: "MacBook Pro 14\"", description: "**2023 MacBook Pro 14\" - M3 Chip**\n\n*Upgrading to the M3 Max, so letting this go to a good home!*\n\n**Specifications:**\n- Processor: Apple M3 chip (8-core CPU, 10-core GPU)\n- RAM: 16GB unified memory\n- Storage: 512GB SSD\n- Display: 14.2\" Liquid Retina XDR\n- Color: Space Gray\n\n**What's Included:**\n• MacBook Pro 14\" (2023)\n• Original 67W USB-C power adapter\n• USB-C to MagSafe 3 cable\n• Original box and documentation\n• Tomtoc protective sleeve (bonus)\n\n**Condition Details:**\n- Battery cycle count: 47\n- No scratches, dents, or cosmetic damage\n- Screen is pristine - always used with screen protector\n- Keyboard and trackpad work perfectly\n- All ports tested and functional\n\n**Additional Information:**\n- Purchased: November 2023 from Apple Store\n- AppleCare+ eligible until November 2024\n- Will be factory reset before sale\n- Original receipt available\n\n**Why I'm Selling:**\nI'm a video editor and need the extra GPU cores in the M3 Max for 8K footage. This machine is perfect for coding, design work, or general professional use.\n\n**Price is firm** - This is already $700 below retail for a practically new machine.", category: .electronics, condition: .likeNew, userId: UUID(), location: "Los Angeles", postedDate: now.addingTimeInterval(-3600 * 3), price: 1800.00, priceIsFirm: true, isTradeItem: false, listingType: .sell, sellerUsername: "Alex Thompson", sellerProfileImageURL: nil)
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
            // Delete from Firestore using the item's UUID as document ID
            print("🗑️ Deleting item: \(item.title)")
            try await firestoreManager.deleteItem(itemId: item.id.uuidString)
            print("✅ Item deleted from Firestore successfully")
            
            // Delete images from Storage
            if !item.images.isEmpty {
                print("🗑️ Deleting \(item.images.count) images from storage...")
                await storageManager.deleteImages(urls: item.images)
                print("✅ Images deleted successfully")
            }
            
            // Remove from local state (real-time listener will handle this automatically)
            await MainActor.run {
                items.removeAll { $0.id == item.id }
                // Also remove from favorites if it was favorited
                favorites.remove(item.id)
            }
            
        } catch {
            print("❌ Error deleting item: \(error)")
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
    
    // MARK: - Helper Methods for Item Management
    
    // Check and log items without proper firebaseUserId
    func checkItemsWithoutFirebaseUserId() {
        let itemsWithoutFirebaseUserId = items.filter { $0.firebaseUserId == nil || $0.firebaseUserId?.isEmpty == true }
        
        if !itemsWithoutFirebaseUserId.isEmpty {
            print("⚠️ Found \(itemsWithoutFirebaseUserId.count) items without proper firebaseUserId:")
            for item in itemsWithoutFirebaseUserId {
                print("   - \(item.title) (ID: \(item.id), userId: \(item.userId), seller: \(item.sellerUsername ?? "Unknown"))")
            }
            print("⚠️ These items will not support messaging until updated with proper Firebase user IDs.")
        }
    }
    
    // MARK: - Messaging Methods
    
    // Create or get existing conversation
    func createOrGetConversation(with userId: String, itemId: String? = nil) async -> Conversation? {
        guard let currentUserId = AuthenticationManager.shared.currentUserId else {
            print("❌ No current user ID")
            return nil
        }
        
        let db = Firestore.firestore()
        let participants = [currentUserId, userId].sorted() // Sort to ensure consistent order
        
        print("🔍 Creating/getting conversation between: \(currentUserId) and \(userId)")
        print("🔍 Participants array: \(participants)")
        
        do {
            // First, check if conversation already exists
            let query = db.collection("conversations")
                .whereField("participants", isEqualTo: participants)
            
            let snapshot = try await query.getDocuments()
            
            if let existingDoc = snapshot.documents.first {
                // Return existing conversation
                let data = existingDoc.data()
                print("✅ Found existing conversation: \(existingDoc.documentID)")
                return Conversation(
                    id: existingDoc.documentID,
                    participants: data["participants"] as? [String] ?? [],
                    itemId: data["itemId"] as? String,
                    lastMessage: data["lastMessage"] as? String ?? "",
                    lastMessageTimestamp: (data["lastMessageTimestamp"] as? Timestamp)?.dateValue() ?? Date(),
                    unreadCount: data["unreadCount"] as? Int ?? 0
                )
            }
            
            // Create new conversation
            let newConversation = Conversation(
                participants: participants,
                itemId: itemId
            )
            
            try await db.collection("conversations")
                .document(newConversation.id)
                .setData(newConversation.dictionary)
            
            print("✅ Created new conversation: \(newConversation.id)")
            return newConversation
            
        } catch {
            print("❌ Error creating/getting conversation: \(error)")
            return nil
        }
    }
    
    // Send a message
    func sendMessage(text: String, to conversation: Conversation) async -> Bool {
        guard let currentUserId = AuthenticationManager.shared.currentUserId else {
            print("❌ No current user ID")
            return false
        }
        
        let receiverId = conversation.participants.first { $0 != currentUserId } ?? ""
        
        let message = Message(
            conversationId: conversation.id,
            senderId: currentUserId,
            receiverId: receiverId,
            text: text
        )
        
        let db = Firestore.firestore()
        
        do {
            // Add message
            try await db.collection("messages")
                .document(message.id)
                .setData(message.dictionary)
            
            // Update conversation
            try await db.collection("conversations")
                .document(conversation.id)
                .updateData([
                    "lastMessage": text,
                    "lastMessageTimestamp": Timestamp(date: message.timestamp)
                ])
            
            print("✅ Message sent successfully")
            return true
            
        } catch {
            print("❌ Error sending message: \(error)")
            return false
        }
    }
}