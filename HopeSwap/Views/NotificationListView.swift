import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct NotificationListView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject var dataManager: DataManager
    @State private var notifications: [NotificationManager.ItemNotification] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                VStack {
                    // Header
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("Notifications")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if !notifications.isEmpty {
                            Button(action: {
                                notificationManager.clearAllNotifications()
                                notifications.removeAll()
                            }) {
                                Text("Clear All")
                                    .font(.caption)
                                    .foregroundColor(Color.hopeGreen)
                            }
                        }
                    }
                    .padding()
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .hopeOrange))
                        Spacer()
                    } else if notifications.isEmpty {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 80))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No notifications yet")
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            Text("We'll notify you about new items from sellers you follow\nand items similar to your searches")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(notifications) { notification in
                                    NotificationRow(notification: notification)
                                        .onTapGesture {
                                            notificationManager.markNotificationAsRead(notification.id)
                                            // Navigate to item
                                            dismiss()
                                        }
                                    
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadNotifications()
        }
    }
    
    private func loadNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId)
            .collection("notifications")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    self.notifications = documents.compactMap { doc in
                        let data = doc.data()
                        
                        let typeString = data["type"] as? String ?? ""
                        let type: NotificationManager.ItemNotification.NotificationType
                        switch typeString {
                        case "favoriteSeller":
                            type = .favoriteSeller
                        case "priceUpdate":
                            type = .priceUpdate
                        default:
                            type = .similarItem
                        }
                        
                        return NotificationManager.ItemNotification(
                            id: doc.documentID,
                            type: type,
                            itemId: data["itemId"] as? String ?? "",
                            itemTitle: data["itemTitle"] as? String ?? "",
                            sellerId: data["sellerId"] as? String ?? "",
                            sellerName: data["sellerName"] as? String ?? "",
                            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                            isRead: data["isRead"] as? Bool ?? false,
                            message: data["message"] as? String ?? ""
                        )
                    }
                }
                isLoading = false
            }
    }
}

struct NotificationRow: View {
    let notification: NotificationManager.ItemNotification
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.message)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(notification.itemTitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                Text(timeAgoString(from: notification.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.8))
            }
            
            Spacer()
            
            if !notification.isRead {
                Circle()
                    .fill(Color.hopeGreen)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(notification.isRead ? Color.hopeDarkBg : Color.hopeDarkSecondary)
    }
    
    private var iconName: String {
        switch notification.type {
        case .favoriteSeller:
            return "heart.fill"
        case .similarItem:
            return "magnifyingglass"
        case .priceUpdate:
            return "tag.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .favoriteSeller:
            return .red
        case .similarItem:
            return .hopeGreen
        case .priceUpdate:
            return .hopeOrange
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            if days > 7 {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}