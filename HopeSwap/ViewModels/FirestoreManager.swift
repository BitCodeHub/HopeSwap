import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FirestoreManager: ObservableObject {
    static let shared = FirestoreManager()
    let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - User Management
    func createUserProfile(userId: String, email: String, name: String = "") async throws {
        let userData: [String: Any] = [
            "email": email,
            "name": name,
            "createdAt": Timestamp(),
            "location": "",
            "avatar": "",
            "isActive": true
        ]
        
        try await db.collection("users").document(userId).setData(userData)
    }
    
    func getUserProfile(userId: String) async throws -> [String: Any]? {
        let document = try await db.collection("users").document(userId).getDocument()
        return document.data()
    }
    
    func updateUserProfile(userId: String, data: [String: Any]) async throws {
        try await db.collection("users").document(userId).updateData(data)
    }
    
    // MARK: - Items Management
    func createItem(_ item: Item) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        var itemData = item.toDictionary()
        // Don't override userId if it's already set correctly
        if itemData["userId"] as? String == nil {
            itemData["userId"] = userId
        }
        
        // Add seller information from current user
        if itemData["sellerUsername"] as? String == nil || (itemData["sellerUsername"] as? String)?.isEmpty == true {
            if let displayName = Auth.auth().currentUser?.displayName {
                itemData["sellerUsername"] = displayName
            } else if let email = Auth.auth().currentUser?.email {
                itemData["sellerUsername"] = email.components(separatedBy: "@").first ?? "User"
            }
        }
        
        if itemData["sellerProfileImageURL"] as? String == nil || (itemData["sellerProfileImageURL"] as? String)?.isEmpty == true {
            if let photoURL = Auth.auth().currentUser?.photoURL {
                itemData["sellerProfileImageURL"] = photoURL.absoluteString
            }
        }
        
        itemData["createdAt"] = Timestamp()
        itemData["updatedAt"] = Timestamp()
        
        // Use the item's UUID as the document ID for consistency
        let itemId = itemData["id"] as? String ?? UUID().uuidString
        try await db.collection("items").document(itemId).setData(itemData)
        return itemId
    }
    
    func updateItem(itemId: String, data: [String: Any]) async throws {
        var updateData = data
        updateData["updatedAt"] = Timestamp()
        try await db.collection("items").document(itemId).updateData(updateData)
    }
    
    func deleteItem(itemId: String) async throws {
        // Verify ownership before deleting
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("🗑️ Attempting to delete item with ID: \(itemId)")
        
        // First try to delete using the item ID as document ID
        let document = try await db.collection("items").document(itemId).getDocument()
        
        if document.exists {
            // Document found with item ID
            guard let data = document.data() else {
                throw NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document data not found"])
            }
            
            // Check ownership
            let itemFirebaseUserId = data["firebaseUserId"] as? String
            let itemUserId = data["userId"] as? String
            
            // Allow deletion if user owns the item
            guard itemFirebaseUserId == userId || itemUserId == userId else {
                throw NSError(domain: "AuthError", code: 403, userInfo: [NSLocalizedDescriptionKey: "Not authorized to delete this item"])
            }
            
            print("✅ Found document with matching ID, deleting...")
            try await db.collection("items").document(itemId).delete()
            print("✅ Item deleted successfully")
        } else {
            // Document not found with item ID, search by id field
            print("⚠️ Document not found with ID \(itemId), searching by id field...")
            
            let querySnapshot = try await db.collection("items")
                .whereField("id", isEqualTo: itemId)
                .limit(to: 1)
                .getDocuments()
            
            guard let doc = querySnapshot.documents.first else {
                throw NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found in database"])
            }
            
            let data = doc.data()
            
            // Check ownership
            let itemFirebaseUserId = data["firebaseUserId"] as? String
            let itemUserId = data["userId"] as? String
            
            guard itemFirebaseUserId == userId || itemUserId == userId else {
                throw NSError(domain: "AuthError", code: 403, userInfo: [NSLocalizedDescriptionKey: "Not authorized to delete this item"])
            }
            
            print("✅ Found document with ID \(doc.documentID), deleting...")
            try await db.collection("items").document(doc.documentID).delete()
            print("✅ Item deleted successfully")
        }
    }
    
    // MARK: - Analytics Methods
    func incrementItemClick(itemId: String) async throws {
        // Use safe method that handles document ID mismatch
        try await safeIncrementItemClick(itemId: itemId)
    }
    
    func incrementVideoPlay(itemId: String) async throws {
        // Use safe method that handles document ID mismatch
        try await safeIncrementVideoPlay(itemId: itemId)
    }
    
    func incrementItemSave(itemId: String) async throws {
        // Use safe method that handles document ID mismatch
        try await safeIncrementItemSave(itemId: itemId)
    }
    
    func decrementItemSave(itemId: String) async throws {
        // Use safe method that handles document ID mismatch
        try await safeDecrementItemSave(itemId: itemId)
    }
    
    func incrementItemShare(itemId: String) async throws {
        // Use safe method that handles document ID mismatch
        try await safeIncrementItemShare(itemId: itemId)
    }
    
    // MARK: - Fetch Single Item
    func fetchItem(itemId: String) async throws -> Item? {
        // First try using the item ID as document ID
        let document = try await db.collection("items").document(itemId).getDocument()
        
        if document.exists {
            return try Item.fromFirestore(document: document)
        }
        
        // If not found, search by id field
        print("⚠️ Document not found with ID \(itemId), searching by id field...")
        let querySnapshot = try await db.collection("items")
            .whereField("id", isEqualTo: itemId)
            .limit(to: 1)
            .getDocuments()
        
        guard let doc = querySnapshot.documents.first else {
            return nil
        }
        
        return try Item.fromFirestore(document: doc)
    }
    
    // MARK: - Initialize Analytics Fields
    func initializeAnalyticsFields(itemId: String) async throws {
        // Use findDocumentId helper to get the actual document ID
        let docId = try await findDocumentId(for: itemId)
        let document = try await db.collection("items").document(docId).getDocument()
        
        guard document.exists else { 
            print("⚠️ Document with ID \(docId) does not exist!")
            return 
        }
        
        let data = document.data() ?? [:]
        
        // Check if analytics fields exist, if not initialize them
        var updates: [String: Any] = [:]
        if data["clickCount"] == nil { updates["clickCount"] = 0 }
        if data["videoPlays"] == nil { updates["videoPlays"] = 0 }
        if data["saveCount"] == nil { updates["saveCount"] = 0 }
        if data["shareCount"] == nil { updates["shareCount"] = 0 }
        
        // Only update if there are missing fields
        if !updates.isEmpty {
            print("🔧 Initializing analytics fields for document \(docId)")
            try await db.collection("items").document(docId).updateData(updates)
        }
    }
    
    // Helper function to find document by item ID
    private func findDocumentId(for itemId: String) async throws -> String {
        // First try using the item ID as document ID
        let document = try await db.collection("items").document(itemId).getDocument()
        
        if document.exists {
            return document.documentID
        }
        
        // If not found, search by id field
        print("⚠️ Document not found with ID \(itemId), searching by id field...")
        let querySnapshot = try await db.collection("items")
            .whereField("id", isEqualTo: itemId)
            .limit(to: 1)
            .getDocuments()
        
        guard let doc = querySnapshot.documents.first else {
            throw NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found in database"])
        }
        
        print("✅ Found document with ID \(doc.documentID) for item \(itemId)")
        return doc.documentID
    }
    
    // MARK: - Migrate Documents to Use Item UUID as Document ID
    func migrateItemsToUseUUIDAsDocumentId() async throws {
        print("🔄 Starting migration to use UUID as document ID...")
        
        let snapshot = try await db.collection("items").getDocuments()
        var migrated = 0
        
        for document in snapshot.documents {
            let data = document.data()
            guard let itemIdString = data["id"] as? String else { continue }
            
            // If document ID doesn't match item ID, we need to migrate
            if document.documentID != itemIdString {
                print("🔄 Migrating item: \(data["title"] ?? "Unknown") from \(document.documentID) to \(itemIdString)")
                
                // Create new document with item UUID as ID
                try await db.collection("items").document(itemIdString).setData(data)
                
                // Delete old document
                try await db.collection("items").document(document.documentID).delete()
                
                migrated += 1
            }
        }
        
        print("✅ Migration complete. Migrated \(migrated) items.")
    }
    
    func fetchItems(limit: Int = 50) async throws -> [Item] {
        let snapshot = try await db.collection("items")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try Item.fromFirestore(document: document)
        }
    }
    
    func fetchUserItems(userId: String) async throws -> [Item] {
        let snapshot = try await db.collection("items")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try Item.fromFirestore(document: document)
        }
    }
    
    func searchItems(query: String, category: String? = nil, location: String? = nil) async throws -> [Item] {
        var firestoreQuery = db.collection("items")
            .order(by: "createdAt", descending: true)
        
        if let category = category, !category.isEmpty {
            firestoreQuery = firestoreQuery.whereField("category", isEqualTo: category)
        }
        
        // Note: For text search, you might want to implement Algolia or use Firestore's array-contains
        // For now, we'll fetch all and filter client-side (not recommended for production)
        let snapshot = try await firestoreQuery.getDocuments()
        
        let items = try snapshot.documents.compactMap { document -> Item? in
            try Item.fromFirestore(document: document)
        }
        
        // Client-side filtering (replace with proper search solution in production)
        if !query.isEmpty {
            return items.filter { item in
                item.title.lowercased().contains(query.lowercased()) ||
                item.description.lowercased().contains(query.lowercased())
            }
        }
        
        return items
    }
    
    // MARK: - Real-time Listeners
    func listenToItems(completion: @escaping ([Item]) -> Void) -> ListenerRegistration {
        return db.collection("items")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to items: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let items = documents.compactMap { document -> Item? in
                    try? Item.fromFirestore(document: document)
                }
                
                completion(items)
            }
    }
    
    func listenToUserItems(userId: String, completion: @escaping ([Item]) -> Void) -> ListenerRegistration {
        return db.collection("items")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to user items: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let items = documents.compactMap { document -> Item? in
                    try? Item.fromFirestore(document: document)
                }
                
                completion(items)
            }
    }
    
    // MARK: - Messaging System (Basic)
    func createConversation(participants: [String], itemId: String?) async throws -> String {
        let conversationData: [String: Any] = [
            "participants": participants,
            "itemId": itemId ?? "",
            "createdAt": Timestamp(),
            "lastMessage": "",
            "lastMessageAt": Timestamp(),
            "isActive": true
        ]
        
        let docRef = try await db.collection("conversations").addDocument(data: conversationData)
        return docRef.documentID
    }
    
    func sendMessage(conversationId: String, senderId: String, text: String) async throws {
        let messageData: [String: Any] = [
            "senderId": senderId,
            "text": text,
            "timestamp": Timestamp(),
            "read": false
        ]
        
        // Add message to conversation
        try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .addDocument(data: messageData)
        
        // Update conversation last message
        try await db.collection("conversations")
            .document(conversationId)
            .updateData([
                "lastMessage": text,
                "lastMessageAt": Timestamp()
            ])
    }
    
    // MARK: - Testing Security Rules (Development Only)
    #if DEBUG
    func testSecurityRules() async {
        print("🧪 Testing Firestore Security Rules...")
        
        // Test 1: Unauthenticated read
        print("\nTest 1: Unauthenticated read")
        do {
            let items = try await db.collection("items").limit(to: 1).getDocuments()
            print("✅ Unauthenticated read: SUCCESS (\(items.documents.count) items)")
        } catch {
            print("❌ Unauthenticated read: FAILED - \(error.localizedDescription)")
        }
        
        // Test 2: Authenticated write (requires current user)
        if let userId = Auth.auth().currentUser?.uid {
            print("\nTest 2: Authenticated write")
            let testItem = Item(
                title: "Test Security Rules",
                description: "Testing write permissions",
                category: .miscellaneous,
                condition: .good,
                userId: UUID(uuidString: userId) ?? UUID(),
                location: "Test Location",
                price: 0,
                priceIsFirm: false,
                images: [],
                listingType: .sell
            )
            
            do {
                let docRef = try await createItem(testItem)
                print("✅ Authenticated write: SUCCESS (ID: \(docRef))")
                
                // Clean up test item
                try await db.collection("items").document(docRef).delete()
                print("✅ Cleanup: Test item deleted")
            } catch {
                print("❌ Authenticated write: FAILED - \(error.localizedDescription)")
            }
            
            // Test 3: Update own profile
            print("\nTest 3: Update own profile")
            do {
                try await db.collection("users").document(userId).setData([
                    "testField": "testValue",
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)
                print("✅ Update own profile: SUCCESS")
            } catch {
                print("❌ Update own profile: FAILED - \(error.localizedDescription)")
            }
            
            // Test 4: Try to update another user's profile (should fail)
            print("\nTest 4: Update another user's profile")
            let fakeUserId = "fake-user-123"
            do {
                try await db.collection("users").document(fakeUserId).setData([
                    "hackerField": "Should not work"
                ], merge: true)
                print("❌ Update other profile: UNEXPECTEDLY SUCCEEDED (Security rules may be too permissive!)")
            } catch {
                print("✅ Update other profile: CORRECTLY FAILED - \(error.localizedDescription)")
            }
        } else {
            print("⚠️ No authenticated user - skipping write tests")
        }
        
        print("\n🧪 Security rules testing complete\n")
    }
    #endif
}