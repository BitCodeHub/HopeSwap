# Firebase SDK Integration Guide for HopeSwap

## Step 1: Add Firebase Package Dependencies

1. **Open HopeSwap.xcodeproj in Xcode**

2. **Add Package Dependency:**
   - File → Add Package Dependencies
   - Enter URL: `https://github.com/firebase/firebase-ios-sdk`
   - Dependency Rule: "Up to Next Major Version" (10.0.0 or latest)
   - Click "Add Package"

3. **Select Required Products:**
   Choose these Firebase products for HopeSwap:
   - ✅ **FirebaseAuth** (user authentication)
   - ✅ **FirebaseFirestore** (database for items, users)
   - ✅ **FirebaseStorage** (image uploads)
   - ✅ **FirebaseMessaging** (push notifications)
   - ✅ **FirebaseAnalytics** (user insights)
   - ✅ **FirebaseCrashlytics** (crash reporting)

4. **Add to Target:** Make sure "HopeSwap" target is selected
5. Click "Add Package"

## Step 2: Add GoogleService-Info.plist

1. **Download from Firebase Console:**
   - Go to Project Settings → Your apps → iOS app
   - Download `GoogleService-Info.plist`

2. **Add to Xcode:**
   - Drag file into Xcode project (same level as HopeSwapApp.swift)
   - ✅ Check "Add to target: HopeSwap"
   - ✅ Check "Copy items if needed"

## Step 3: Configure Firebase in App

Update `HopeSwapApp.swift`:

```swift
import SwiftUI
import Firebase

@main
struct HopeSwapApp: App {
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(DataManager())
        }
    }
}
```

## Step 4: Create Firebase Services

Create new files in your project:

### AuthenticationManager.swift
```swift
import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var isSignedIn = false
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            self?.user = user
            self?.isSignedIn = user != nil
        }
    }
    
    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        // Create user profile in Firestore
        try await createUserProfile(userId: result.user.uid, email: email)
    }
    
    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    private func createUserProfile(userId: String, email: String) async throws {
        // Will implement with FirestoreManager
    }
}
```

### FirestoreManager.swift
```swift
import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FirestoreManager: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - User Management
    func createUserProfile(userId: String, email: String, name: String = "") async throws {
        let userData: [String: Any] = [
            "email": email,
            "name": name,
            "createdAt": Timestamp(),
            "location": "",
            "avatar": ""
        ]
        
        try await db.collection("users").document(userId).setData(userData)
    }
    
    // MARK: - Items Management
    func createItem(_ item: Item) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        var itemData = item.toDictionary()
        itemData["userId"] = userId
        itemData["createdAt"] = Timestamp()
        
        try await db.collection("items").addDocument(data: itemData)
    }
    
    func fetchItems() async throws -> [Item] {
        let snapshot = try await db.collection("items")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try Item.fromFirestore(document: document)
        }
    }
    
    // MARK: - Real-time Listeners
    func listenToItems(completion: @escaping ([Item]) -> Void) {
        db.collection("items")
            .order(by: "createdAt", descending: true)
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
}
```

### StorageManager.swift
```swift
import Foundation
import FirebaseStorage
import UIKit

@MainActor
class StorageManager: ObservableObject {
    private let storage = Storage.storage()
    
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ImageError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let storageRef = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    func uploadItemImages(_ images: [UIImage], itemId: String) async throws -> [String] {
        var uploadedURLs: [String] = []
        
        for (index, image) in images.enumerated() {
            let path = "items/\(itemId)/image_\(index).jpg"
            let url = try await uploadImage(image, path: path)
            uploadedURLs.append(url)
        }
        
        return uploadedURLs
    }
}
```

## Step 5: Update Your Models

Add Firestore support to `Item.swift`:

```swift
// Add these methods to your Item struct
extension Item {
    func toDictionary() -> [String: Any] {
        return [
            "title": title,
            "description": description,
            "price": price ?? 0,
            "category": category.rawValue,
            "condition": condition.rawValue,
            "location": location,
            "images": images,
            "listingType": listingType.rawValue,
            "postedDate": Timestamp(date: postedDate),
            "isTradeItem": isTradeItem,
            "lookingFor": lookingFor ?? "",
            "acceptableItems": acceptableItems ?? "",
            "openToOffers": openToOffers
        ]
    }
    
    static func fromFirestore(document: QueryDocumentSnapshot) throws -> Item {
        let data = document.data()
        
        guard let title = data["title"] as? String,
              let description = data["description"] as? String,
              let categoryString = data["category"] as? String,
              let category = Category(rawValue: categoryString),
              let conditionString = data["condition"] as? String,
              let condition = Condition(rawValue: conditionString),
              let location = data["location"] as? String,
              let images = data["images"] as? [String],
              let listingTypeString = data["listingType"] as? String,
              let listingType = ListingType(rawValue: listingTypeString),
              let timestamp = data["postedDate"] as? Timestamp else {
            throw NSError(domain: "FirestoreError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid item data"])
        }
        
        let price = data["price"] as? Double
        let isTradeItem = data["isTradeItem"] as? Bool ?? false
        let lookingFor = data["lookingFor"] as? String
        let acceptableItems = data["acceptableItems"] as? String
        let openToOffers = data["openToOffers"] as? Bool ?? false
        
        return Item(
            id: document.documentID,
            title: title,
            description: description,
            price: price == 0 ? nil : price,
            category: category,
            condition: condition,
            location: location,
            images: images,
            listingType: listingType,
            postedDate: timestamp.dateValue(),
            isTradeItem: isTradeItem,
            lookingFor: lookingFor,
            acceptableItems: acceptableItems,
            openToOffers: openToOffers
        )
    }
}
```

## Step 6: Update DataManager

Replace your local `DataManager` with Firebase integration:

```swift
@MainActor
class DataManager: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    
    private let firestoreManager = FirestoreManager()
    private let storageManager = StorageManager()
    
    init() {
        setupRealtimeListener()
    }
    
    private func setupRealtimeListener() {
        firestoreManager.listenToItems { [weak self] items in
            Task { @MainActor in
                self?.items = items
            }
        }
    }
    
    func addItem(_ item: Item, images: [UIImage] = []) async {
        isLoading = true
        
        do {
            // Upload images first if any
            var imageUrls: [String] = []
            if !images.isEmpty {
                let itemId = UUID().uuidString
                imageUrls = try await storageManager.uploadItemImages(images, itemId: itemId)
            }
            
            // Create item with image URLs
            var newItem = item
            newItem.images = imageUrls
            
            try await firestoreManager.createItem(newItem)
        } catch {
            print("Error adding item: \(error)")
        }
        
        isLoading = false
    }
}
```

## Next Steps

1. Follow the Xcode integration steps above
2. Add the GoogleService-Info.plist file
3. Create the Firebase service files
4. Test authentication and data flow
5. Configure Firestore security rules in Firebase Console

Your app will now be connected to Firebase! 🚀