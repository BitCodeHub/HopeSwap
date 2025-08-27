import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct InboxView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var conversations: [Conversation] = []
    @State private var userProfiles: [String: User] = [:] // Cache user profiles
    @State private var selectedConversation: Conversation? = nil
    @State private var isLoading = true
    @State private var isEditing = false
    @State private var selectedConversations = Set<String>()
    @State private var showingSortMenu = false
    @State private var sortOption: SortOption = .newest
    @State private var groupByListing = false
    @State private var showingNotifications = false
    @Environment(\.dismiss) var dismiss
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case unread = "Unread"
        case read = "Read"
        
        var title: String { rawValue }
    }
    
    private let db = Firestore.firestore()
    
    @ViewBuilder
    var headerView: some View {
        HStack {
            if isEditing {
                Button(action: {
                    isEditing = false
                    selectedConversations.removeAll()
                }) {
                    Text("Cancel")
                        .font(.body)
                        .foregroundColor(Color.hopeGreen)
                }
            }
            
            Spacer()
            
            Text("Inbox")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            // Notification bell
            Button(action: {
                showingNotifications = true
            }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.title2)
                        .foregroundColor(notificationManager.unreadNotifications > 0 ? Color.hopeOrange : .white)
                    
                    if notificationManager.unreadNotifications > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Text("\(notificationManager.unreadNotifications)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                            .offset(x: 8, y: -8)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom header
                    headerView
                    
                    // Group by listing toggle and edit button
                    HStack(spacing: 20) {
                        // Group by listing toggle
                        Button(action: {
                            withAnimation {
                                groupByListing.toggle()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: groupByListing ? "square.grid.2x2" : "list.bullet")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                    )
                                
                                Text("Group by listing")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Toggle("", isOn: $groupByListing)
                                    .labelsHidden()
                                    .tint(Color.hopeGreen)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Edit button
                        Button(action: {
                            withAnimation {
                                isEditing.toggle()
                                if !isEditing {
                                    selectedConversations.removeAll()
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil")
                                    .font(.body)
                                Text(isEditing ? "Done" : "Edit")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(Color.hopeGreen)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Sort button
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showingSortMenu = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 14))
                                Text("Sort: \(sortOption.title)")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(Color.hopeGreen)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.hopeGreen, lineWidth: 2)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    
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
                        List {
                            ForEach(sortedConversations) { conversation in
                                ConversationRowEnhanced(
                                    conversation: conversation,
                                    otherUser: getOtherUser(from: conversation),
                                    isEditing: isEditing,
                                    isSelected: selectedConversations.contains(conversation.id),
                                    isSystem: conversation.lastMessage.contains("sold") || getOtherUser(from: conversation)?.name == "OfferUp"
                                )
                                .listRowBackground(Color.hopeDarkBg)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                                .onTapGesture {
                                    if isEditing {
                                        toggleSelection(for: conversation)
                                    } else {
                                        selectedConversation = conversation
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteConversation(conversation)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        .background(Color.hopeDarkBg)
                        .scrollContentBackground(.hidden)
                        
                        Spacer()
                        
                        // Delete button when editing
                        if isEditing && !selectedConversations.isEmpty {
                            Button(action: deleteSelectedConversations) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete (\(selectedConversations.count))")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                            }
                            .padding()
                            .padding(.bottom, 80)
                        }
                    }
                }
                
                // Start new chat button at the bottom
                if !conversations.isEmpty && !isEditing {
                    VStack {
                        Spacer()
                        
                        Button(action: {}) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.body)
                                Text("Start a new chat")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(25)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .padding(.bottom, 90)
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
        .sheet(isPresented: $showingNotifications) {
            NotificationListView()
        }
        .actionSheet(isPresented: $showingSortMenu) {
            ActionSheet(
                title: Text("Sort messages by"),
                buttons: SortOption.allCases.map { option in
                    .default(
                        Text(option.title + (sortOption == option ? " ✓" : ""))
                    ) {
                        sortOption = option
                    }
                } + [.cancel()]
            )
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
    
    private var sortedConversations: [Conversation] {
        switch sortOption {
        case .newest:
            return conversations.sorted { $0.lastMessageTimestamp > $1.lastMessageTimestamp }
        case .oldest:
            return conversations.sorted { $0.lastMessageTimestamp < $1.lastMessageTimestamp }
        case .unread:
            return conversations.sorted { $0.unreadCount > $1.unreadCount }
        case .read:
            return conversations.sorted { $0.unreadCount < $1.unreadCount }
        }
    }
    
    private func toggleSelection(for conversation: Conversation) {
        if selectedConversations.contains(conversation.id) {
            selectedConversations.remove(conversation.id)
        } else {
            selectedConversations.insert(conversation.id)
        }
    }
    
    private func deleteConversation(_ conversation: Conversation) {
        // Delete from Firestore
        db.collection("conversations").document(conversation.id).delete()
        
        // Remove from local array
        conversations.removeAll { $0.id == conversation.id }
    }
    
    private func deleteSelectedConversations() {
        for conversationId in selectedConversations {
            db.collection("conversations").document(conversationId).delete()
        }
        
        conversations.removeAll { selectedConversations.contains($0.id) }
        selectedConversations.removeAll()
        isEditing = false
    }
    
    private func getOtherUser(from conversation: Conversation) -> User? {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return nil }
        let otherUserId = conversation.participants.first { $0 != currentUserId }
        return otherUserId.flatMap { userProfiles[$0] }
    }
}

struct ConversationRowEnhanced: View {
    let conversation: Conversation
    let otherUser: User?
    let isEditing: Bool
    let isSelected: Bool
    let isSystem: Bool
    @State private var item: Item? = nil
    
    private let db = Firestore.firestore()
    
    var profileView: some View {
        Group {
            if isSystem {
                // System message profile (OfferUp logo)
                ZStack {
                    Circle()
                        .fill(Color.hopeGreen)
                        .frame(width: 60, height: 60)
                    
                    Text("OU")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            } else {
                // Regular user profile
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
                    if !isSystem {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator in edit mode
            if isEditing {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Color.hopeGreen : .gray)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            
            profileView
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(isSystem ? "OfferUp" : (otherUser?.name ?? "Unknown User"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Text(timeAgoString(from: conversation.lastMessageTimestamp))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let item = item, let firstImage = item.images.first,
                           let url = URL(string: firstImage) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                            }
                        }
                    }
                }
                
                Text(conversation.lastMessage)
                    .font(.system(size: 16))
                    .foregroundColor(isSystem ? .white : .gray)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Item title if available and not a system message
                if let item = item, !isSystem {
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
        .background(isSystem ? Color.hopeDarkSecondary : Color.hopeDarkBg)
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

