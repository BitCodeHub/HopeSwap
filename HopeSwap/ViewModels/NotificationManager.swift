import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

@MainActor
class NotificationManager: ObservableObject {
    @Published var unreadNotifications = 0
    @Published var notifications: [ItemNotification] = []
    @Published var favoriteSellers: Set<String> = []
    @Published var searchHistory: [String] = []
    @Published var viewedCategories: Set<Category> = []
    
    private var notificationListener: ListenerRegistration?
    private var itemListener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    static let shared = NotificationManager()
    
    private init() {
        loadFavoriteSellers()
        loadSearchHistory()
        setupNotificationListeners()
    }
    
    deinit {
        notificationListener?.remove()
        itemListener?.remove()
    }
    
    // MARK: - Notification Model
    struct ItemNotification: Identifiable {
        let id: String
        let type: NotificationType
        let itemId: String
        let itemTitle: String
        let sellerId: String
        let sellerName: String
        let timestamp: Date
        let isRead: Bool
        let message: String
        
        enum NotificationType {
            case favoriteSeller
            case similarItem
            case priceUpdate
        }
    }
    
    // MARK: - Favorite Sellers
    func toggleFavoriteSeller(_ sellerId: String) {
        if favoriteSellers.contains(sellerId) {
            favoriteSellers.remove(sellerId)
        } else {
            favoriteSellers.insert(sellerId)
        }
        saveFavoriteSellers()
    }
    
    private func saveFavoriteSellers() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).updateData([
            "favoriteSellers": Array(favoriteSellers)
        ])
    }
    
    private func loadFavoriteSellers() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let data = document?.data(),
               let sellers = data["favoriteSellers"] as? [String] {
                self?.favoriteSellers = Set(sellers)
            }
        }
    }
    
    // MARK: - Search History
    func addToSearchHistory(_ query: String) {
        searchHistory.removeAll { $0 == query }
        searchHistory.insert(query, at: 0)
        
        // Keep only last 20 searches
        if searchHistory.count > 20 {
            searchHistory = Array(searchHistory.prefix(20))
        }
        
        saveSearchHistory()
    }
    
    private func saveSearchHistory() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).updateData([
            "searchHistory": searchHistory
        ])
    }
    
    private func loadSearchHistory() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let data = document?.data(),
               let history = data["searchHistory"] as? [String] {
                self?.searchHistory = history
            }
        }
    }
    
    // MARK: - Category Tracking
    func trackViewedCategory(_ category: Category) {
        viewedCategories.insert(category)
        saveViewedCategories()
    }
    
    private func saveViewedCategories() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let categoryStrings = viewedCategories.map { $0.rawValue }
        
        db.collection("users").document(userId).updateData([
            "viewedCategories": categoryStrings
        ])
    }
    
    // MARK: - Notification Listeners
    private func setupNotificationListeners() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Listen for new items from favorite sellers
        itemListener = db.collection("items")
            .whereField("isDeleted", isEqualTo: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let documents = snapshot?.documentChanges.filter({ $0.type == .added }) else { return }
                
                for change in documents {
                    if let item = try? change.document.data(as: Item.self) {
                        // Check if from favorite seller
                        if let sellerId = item.firebaseUserId,
                           self.favoriteSellers.contains(sellerId) {
                            self.createNotification(
                                type: .favoriteSeller,
                                item: item,
                                message: "New item from \(item.sellerUsername ?? "seller") you follow"
                            )
                        }
                        
                        // Check if similar to search history
                        for searchTerm in self.searchHistory {
                            if item.title.lowercased().contains(searchTerm.lowercased()) ||
                               item.description.lowercased().contains(searchTerm.lowercased()) {
                                self.createNotification(
                                    type: .similarItem,
                                    item: item,
                                    message: "New item matches your search: '\(searchTerm)'"
                                )
                                break
                            }
                        }
                        
                        // Check if in viewed categories
                        if self.viewedCategories.contains(item.category) {
                            self.createNotification(
                                type: .similarItem,
                                item: item,
                                message: "New item in \(item.category.rawValue)"
                            )
                        }
                    }
                }
            }
        
        // Listen for notification count changes
        notificationListener = db.collection("users").document(userId)
            .collection("notifications")
            .whereField("isRead", isEqualTo: false)
            .addSnapshotListener { [weak self] snapshot, error in
                self?.unreadNotifications = snapshot?.documents.count ?? 0
            }
    }
    
    private func createNotification(type: ItemNotification.NotificationType, item: Item, message: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let notification: [String: Any] = [
            "type": type == .favoriteSeller ? "favoriteSeller" : "similarItem",
            "itemId": item.id.uuidString,
            "itemTitle": item.title,
            "sellerId": item.firebaseUserId ?? "",
            "sellerName": item.sellerUsername ?? "Unknown",
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false,
            "message": message
        ]
        
        db.collection("users").document(userId)
            .collection("notifications")
            .addDocument(data: notification)
    }
    
    func markNotificationAsRead(_ notificationId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId)
            .collection("notifications")
            .document(notificationId)
            .updateData(["isRead": true])
    }
    
    func clearAllNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId)
            .collection("notifications")
            .getDocuments { snapshot, error in
                snapshot?.documents.forEach { doc in
                    doc.reference.delete()
                }
            }
    }
}