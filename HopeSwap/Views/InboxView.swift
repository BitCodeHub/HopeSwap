import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct InboxView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var conversations: [Conversation] = []
    @State private var userProfiles: [String: User] = [:] // Cache user profiles
    @State private var selectedConversation: Conversation? = nil
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                VStack {
                    // Custom header
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        Text("Inbox")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Spacer to balance the header
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .hopeOrange))
                        Spacer()
                    } else if conversations.isEmpty {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 80))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No messages yet")
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            Text("Start a conversation with a seller!")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(conversations) { conversation in
                                    ConversationRow(
                                        conversation: conversation,
                                        otherUser: getOtherUser(from: conversation)
                                    )
                                    .onTapGesture {
                                        selectedConversation = conversation
                                    }
                                    
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadConversations()
        }
        .sheet(item: $selectedConversation) { conversation in
            ChatView(conversation: conversation, otherUser: getOtherUser(from: conversation))
        }
    }
    
    private func loadConversations() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { 
            print("❌ No current user ID in loadConversations")
            return 
        }
        
        print("📥 Loading conversations for user: \(currentUserId)")
        
        db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error loading conversations: \(error)")
                    isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No documents found in conversations")
                    isLoading = false
                    return
                }
                
                var loadedConversations: [Conversation] = []
                var userIdsToLoad = Set<String>()
                
                print("📋 Found \(documents.count) conversations")
                
                for doc in documents {
                    let data = doc.data()
                    let participants = data["participants"] as? [String] ?? []
                    print("💬 Conversation \(doc.documentID) participants: \(participants)")
                    
                    let conversation = Conversation(
                        id: doc.documentID,
                        participants: participants,
                        itemId: data["itemId"] as? String,
                        lastMessage: data["lastMessage"] as? String ?? "",
                        lastMessageTimestamp: (data["lastMessageTimestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        unreadCount: data["unreadCount"] as? Int ?? 0
                    )
                    loadedConversations.append(conversation)
                    
                    // Collect user IDs to load profiles
                    for participantId in conversation.participants {
                        if participantId != currentUserId {
                            userIdsToLoad.insert(participantId)
                        }
                    }
                }
                
                self.conversations = loadedConversations
                
                // Load user profiles
                loadUserProfiles(userIds: Array(userIdsToLoad))
                isLoading = false
            }
    }
    
    private func loadUserProfiles(userIds: [String]) {
        for userId in userIds {
            if userProfiles[userId] == nil {
                db.collection("users").document(userId).getDocument { document, error in
                    if let document = document, document.exists,
                       let data = document.data() {
                        DispatchQueue.main.async {
                            let user = User(
                                username: data["name"] as? String ?? "Unknown User",
                                email: data["email"] as? String ?? ""
                            )
                            var mutableUser = user
                            mutableUser.profileImageURL = data["avatar"] as? String
                            mutableUser.profilePicture = data["avatar"] as? String
                            self.userProfiles[userId] = mutableUser
                        }
                    }
                }
            }
        }
    }
    
    private func getOtherUser(from conversation: Conversation) -> User? {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return nil }
        let otherUserId = conversation.participants.first { $0 != currentUserId }
        return otherUserId.flatMap { userProfiles[$0] }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let otherUser: User?
    @State private var item: Item? = nil
    
    private let db = Firestore.firestore()
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile picture with verification badge
            ZStack(alignment: .bottomTrailing) {
                if let profileURL = otherUser?.profileImageURL ?? otherUser?.profilePicture,
                   let url = URL(string: profileURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                // Verification badge
                Circle()
                    .fill(Color.blue)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(otherUser?.name ?? "Unknown User")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(timeAgoString(from: conversation.lastMessageTimestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text(conversation.lastMessage)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let item = item, let firstImage = item.images.first,
                       let url = URL(string: firstImage) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .cornerRadius(6)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                        }
                    }
                }
                
                // Item title if available
                if let item = item {
                    Text(item.title)
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            
            if conversation.unreadCount > 0 {
                Circle()
                    .fill(Color.hopeGreen)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
        .background(Color.hopeDarkBg)
        .onAppear {
            loadItem()
        }
    }
    
    private func loadItem() {
        guard let itemId = conversation.itemId else { return }
        
        db.collection("items").document(itemId).getDocument { document, error in
            if let document = document, document.exists,
               let itemData = try? document.data(as: Item.self) {
                self.item = itemData
            }
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
            return "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m"
        } else {
            return "now"
        }
    }
}