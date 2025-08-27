import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatView: View {
    let conversation: Conversation
    let otherUser: User?
    
    @State private var messages: [Message] = []
    @State private var messageText = ""
    @State private var isLoading = true
    @State private var item: Item? = nil
    @State private var lastSeenTimestamp: Date? = nil
    @Environment(\.dismiss) var dismiss
    
    private let db = Firestore.firestore()
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(Color.hopeGreen)
                        }
                        
                        Spacer()
                        
                        Text("Message")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 20) {
                            Button(action: {}) {
                                Image(systemName: "pin.fill")
                                    .font(.title3)
                                    .foregroundColor(Color.hopeGreen)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "ellipsis")
                                    .font(.title3)
                                    .foregroundColor(Color.hopeGreen)
                            }
                        }
                    }
                    .padding()
                    
                    // Seller Info Bar
                    if let otherUser = otherUser, let item = item {
                        HStack(spacing: 12) {
                            // Profile picture with verification badge
                            ZStack(alignment: .bottomTrailing) {
                                if let profileURL = otherUser.profileImageURL ?? otherUser.profilePicture,
                                   let url = URL(string: profileURL) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.gray)
                                        )
                                }
                                
                                // Verification badge
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(otherUser.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 4) {
                                    ForEach(0..<5) { index in
                                        Image(systemName: "star.fill")
                                            .font(.caption2)
                                            .foregroundColor(.yellow)
                                    }
                                    Text("(21)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(item.location)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            // Item preview
                            ZStack(alignment: .topLeading) {
                                if let firstImage = item.images.first,
                                   let url = URL(string: firstImage) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(8)
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 60, height: 60)
                                    }
                                }
                                
                                // Price tag
                                Text(item.price != nil ? "$\(Int(item.price!))" : "Trade")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white)
                                    .cornerRadius(4)
                                    .padding(4)
                            }
                        }
                        .padding()
                        .background(Color.hopeDarkSecondary)
                    }
                    
                    // Messages
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .hopeGreen))
                        Spacer()
                    } else {
                        ScrollViewReader { scrollView in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 16) {
                                    // Safety Tip Section (show at the beginning)
                                    if messages.isEmpty || messages.count <= 2 {
                                        SafetyTipView()
                                    }
                                    
                                    // Messages with timestamps
                                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                                        VStack(spacing: 16) {
                                            // Show timestamp if it's the first message or different day
                                            if index == 0 || !isSameDay(messages[index - 1].timestamp, message.timestamp) {
                                                Text(formatMessageDate(message.timestamp))
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 8)
                                            }
                                            
                                            MessageBubbleOfferUp(
                                                message: message,
                                                isCurrentUser: message.senderId == currentUserId,
                                                lastSeenTimestamp: lastSeenTimestamp
                                            )
                                            .id(message.id)
                                            .transition(.asymmetric(
                                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                                removal: .opacity
                                            ))
                                        }
                                    }
                                }
                                .padding()
                            }
                            .onChange(of: messages.count) { _, _ in
                                if let lastMessage = messages.last {
                                    withAnimation {
                                        scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Input area
                    HStack(spacing: 0) {
                        // Location button
                        Button(action: {}) {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .foregroundColor(Color.hopeGreen)
                        }
                        .padding(.leading, 16)
                        
                        // Message input
                        TextField("Message...", text: $messageText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .foregroundColor(.white)
                        
                        // Send button
                        Button(action: sendMessage) {
                            Circle()
                                .fill(messageText.isEmpty ? Color.gray.opacity(0.3) : Color.hopeGreen)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(messageText.isEmpty ? .gray : .white)
                                )
                        }
                        .disabled(messageText.isEmpty)
                        .padding(.trailing, 16)
                    }
                    .frame(height: 60)
                    .background(Color.hopeDarkSecondary)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadItem()
            loadMessages()
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
    
    private func loadMessages() {
        db.collection("messages")
            .whereField("conversationId", isEqualTo: conversation.id)
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error loading messages: \(error)")
                    isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    isLoading = false
                    return
                }
                
                let newMessages = documents.compactMap { doc in
                    let data = doc.data()
                    return Message(
                        id: doc.documentID,
                        conversationId: data["conversationId"] as? String ?? "",
                        senderId: data["senderId"] as? String ?? "",
                        receiverId: data["receiverId"] as? String ?? "",
                        text: data["text"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        isRead: data["isRead"] as? Bool ?? false
                    )
                }
                
                // Only update if there are actual changes
                if self.messages != newMessages {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.messages = newMessages
                    }
                }
                
                // Track when messages were last seen
                if let lastMessage = newMessages.last,
                   lastMessage.receiverId == currentUserId && lastMessage.isRead {
                    self.lastSeenTimestamp = Date()
                }
                
                isLoading = false
                markMessagesAsRead()
            }
    }
    
    private func markMessagesAsRead() {
        guard let currentUserId = currentUserId else { return }
        
        for message in messages where message.receiverId == currentUserId && !message.isRead {
            db.collection("messages").document(message.id).updateData([
                "isRead": true
            ])
        }
    }
    
    private func sendMessage() {
        guard let currentUserId = currentUserId,
              let receiverId = conversation.participants.first(where: { $0 != currentUserId }),
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = Message(
            conversationId: conversation.id,
            senderId: currentUserId,
            receiverId: receiverId,
            text: messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        // Immediately add message to local array for instant UI update
        withAnimation(.easeInOut(duration: 0.3)) {
            messages.append(message)
        }
        
        // Clear text field immediately
        messageText = ""
        
        // Add message to Firebase
        db.collection("messages").document(message.id).setData(message.dictionary) { error in
            if let error = error {
                print("Error sending message: \(error)")
                // Remove message from local array if send failed
                DispatchQueue.main.async {
                    self.messages.removeAll { $0.id == message.id }
                }
                return
            }
            
            // Update conversation's last message
            db.collection("conversations").document(conversation.id).updateData([
                "lastMessage": message.text,
                "lastMessageTimestamp": Timestamp(date: message.timestamp)
            ])
        }
    }
    
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    private func formatMessageDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a MMM d"
        return formatter.string(from: date)
    }
}

struct SafetyTipView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Timestamp
            Text(formatDate(Date()))
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            
            // Safety tip box
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "shield.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.hopeGreen)
                    }
                    
                    Text("Safety Tip")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Text("Heads up: Meet in a well-lit, public place like a coffee shop, store, or a local police station when buying and selling expensive items. Find an official Community MeetUp spot with the Location icon at the bottom left.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .lineSpacing(4)
                
                Button(action: {}) {
                    Text("Learn more")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.hopeGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.hopeGreen, lineWidth: 2)
                        )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.hopeDarkSecondary)
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a MMM d"
        return formatter.string(from: date)
    }
}

struct MessageBubbleOfferUp: View {
    let message: Message
    let isCurrentUser: Bool
    let lastSeenTimestamp: Date?
    
    var seenText: String {
        guard isCurrentUser && message.isRead else { return "" }
        
        let now = Date()
        let timeSinceRead = now.timeIntervalSince(message.timestamp)
        
        // If read within 5 seconds, show "Just seen"
        if timeSinceRead < 5 {
            return "Just seen"
        } else if timeSinceRead < 60 {
            // Less than a minute
            return "Seen"
        } else if timeSinceRead < 3600 {
            // Less than an hour
            let minutes = Int(timeSinceRead / 60)
            return "Seen \(minutes)m ago"
        } else if timeSinceRead < 86400 {
            // Less than a day
            let hours = Int(timeSinceRead / 3600)
            return "Seen \(hours)h ago"
        } else {
            // Format date
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            return "Seen \(formatter.string(from: message.timestamp))"
        }
    }
    
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            HStack(alignment: .bottom, spacing: 8) {
                if isCurrentUser { Spacer() }
                
                // Message bubble
                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
                    Text(message.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isCurrentUser ? Color.gray.opacity(0.3) : Color.hopeGreen)
                        )
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    
                    // Time stamp below message
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.horizontal, 4)
                }
                
                if !isCurrentUser { Spacer() }
            }
            
            // Seen indicator with enhanced status
            if isCurrentUser && !seenText.isEmpty {
                HStack(spacing: 4) {
                    Text(seenText)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(Color.hopeGreen)
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}