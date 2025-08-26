import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FirestoreManager: ObservableObject {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()
    
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
        
        let docRef = try await db.collection("items").addDocument(data: itemData)
        return docRef.documentID
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
        
        let document = try await db.collection("items").document(itemId).getDocument()
        guard let data = document.data(),
              let itemUserId = data["userId"] as? String,
              itemUserId == userId else {
            throw NSError(domain: "AuthError", code: 403, userInfo: [NSLocalizedDescriptionKey: "Not authorized to delete this item"])
        }
        
        try await db.collection("items").document(itemId).delete()
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