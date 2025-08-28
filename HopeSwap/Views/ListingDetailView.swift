import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ListingDetailSheets: ViewModifier {
    let item: Item
    let isOwnItem: Bool
    let conversation: Conversation?
    let sellerInfo: User?
    let messageText: String
    let messageErrorText: String
    let selectedSuggestion: String
    let offerPrice: String
    let tradeOfferText: String
    
    @Binding var showingImageGallery: Bool
    @Binding var selectedImageIndex: Int
    @Binding var showingDeleteAlert: Bool
    @Binding var showingMenu: Bool
    @Binding var showingSearch: Bool
    @Binding var showingInsights: Bool
    @Binding var showingEditFlow: Bool
    @Binding var showingChat: Bool
    @Binding var showingMessageError: Bool
    @Binding var showingAskSuggestions: Bool
    @Binding var showingMakeOffer: Bool
    @Binding var showingTradeOffer: Bool
    @Binding var messageTextBinding: String
    @Binding var selectedSuggestionBinding: String
    @Binding var tradeOfferTextBinding: String
    
    let deleteItem: () -> Void
    let sendMessage: () -> Void
    let dataManager: DataManager
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $showingImageGallery) {
                ImageGalleryView(images: item.images, selectedIndex: $selectedImageIndex)
            }
            .alert("Delete Listing", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteItem()
                }
            } message: {
                Text("Are you sure you want to delete this listing? This action cannot be undone.")
            }
            .sheet(isPresented: $showingMenu) {
                ListingMenuSheet(
                    item: item,
                    isOwnItem: isOwnItem,
                    showingEditFlow: $showingEditFlow,
                    showingDeleteAlert: $showingDeleteAlert,
                    showingInsights: $showingInsights
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color.hopeDarkSecondary)
            }
            .sheet(isPresented: $showingSearch) {
                ListingSearchView()
                    .environmentObject(dataManager)
            }
            .sheet(isPresented: $showingInsights) {
                MarketplaceInsightsView(item: item)
            }
            .fullScreenCover(isPresented: $showingEditFlow) {
                PostItemFlow(editingItem: item)
                    .environmentObject(dataManager)
            }
            .sheet(isPresented: $showingChat) {
                if let conversation = conversation {
                    ChatView(conversation: conversation, otherUser: sellerInfo)
                        .onDisappear {
                            messageTextBinding = "Is this still available?"
                        }
                }
            }
            .alert("Unable to Send Message", isPresented: $showingMessageError) {
                Button("OK") {
                    showingMessageError = false
                }
            } message: {
                Text(messageErrorText)
            }
            .sheet(isPresented: $showingAskSuggestions) {
                AskSuggestionsSheet(
                    showingAskSuggestions: $showingAskSuggestions,
                    messageText: $messageTextBinding,
                    selectedSuggestion: $selectedSuggestionBinding,
                    onSend: {
                        sendMessage()
                        showingAskSuggestions = false
                    },
                    isTradeItem: item.listingType == .trade
                )
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.hopeDarkSecondary)
            }
            .sheet(isPresented: $showingMakeOffer) {
                MakeOfferSheet(
                    item: item,
                    showingMakeOffer: $showingMakeOffer,
                    offerPrice: Binding(
                        get: { offerPrice },
                        set: { _ in }
                    ),
                    onSubmit: { price in
                        messageTextBinding = "I'd like to offer $\(price) for this item."
                        sendMessage()
                        showingMakeOffer = false
                    }
                )
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.hopeDarkSecondary)
            }
            .sheet(isPresented: $showingTradeOffer) {
                TradeOfferSheet(
                    item: item,
                    showingTradeOffer: $showingTradeOffer,
                    tradeOfferText: $tradeOfferTextBinding,
                    onSubmit: { offerText in
                        messageTextBinding = offerText
                        sendMessage()
                        showingTradeOffer = false
                    }
                )
                .presentationDetents([.height(500)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.hopeDarkSecondary)
            }
    }
}

struct ListingDetailView: View {
    let item: Item
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedImageIndex = 0
    @State private var showingImageGallery = false
    @State private var messageText = "Is this still available?"
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @State private var showingMenu = false
    @State private var showingSearch = false
    @State private var showingInsights = false
    @State private var showingEditFlow = false
    @State private var isDescriptionExpanded = false
    @State private var showingChat = false
    @State private var conversation: Conversation? = nil
    @State private var isSendingMessage = false
    @State private var sellerInfo: User? = nil
    @State private var showingMessageError = false
    @State private var messageErrorText = ""
    @FocusState private var isMessageFieldFocused: Bool
    @State private var showingAskSuggestions = false
    @State private var showingMakeOffer = false
    @State private var showingTradeOffer = false
    @State private var offerPrice = ""
    @State private var selectedSuggestion = ""
    @State private var tradeOfferText = ""
    
    var isOwnItem: Bool {
        guard let currentUserId = AuthenticationManager.shared.currentUserId else { 
            print("🔍 isOwnItem: No current user ID")
            return false 
        }
        let isOwn = item.firebaseUserId == currentUserId || item.userId.uuidString == currentUserId
        print("🔍 isOwnItem check:")
        print("   - Current user ID: \(currentUserId)")
        print("   - Item firebaseUserId: \(item.firebaseUserId ?? "nil")")
        print("   - Item userId: \(item.userId.uuidString)")
        print("   - Is own item: \(isOwn)")
        print("   - Seller name: \(item.sellerUsername ?? "Unknown")")
        return isOwn
    }
    
    var priceText: String {
        if let price = item.price {
            return price == 0 ? "Free" : "$\(Int(price))"
        } else {
            return "Trade"
        }
    }
    
    var originalPriceText: String? {
        // Show original price if there's a discount
        if let price = item.price, price > 0 {
            // Only show original price if current price is below a threshold
            if price < 100 || (price < 1000 && price.truncatingRemainder(dividingBy: 10) == 0) {
                let originalPrice = price * 1.2 // Assuming 20% discount for demo
                return "$\(Int(originalPrice))"
            }
        }
        return nil
    }
    
    var imagePlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
            )
    }
    
    @ViewBuilder
    var navigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: { showingSearch = true }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Button(action: { showingMenu = true }) {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    var imageCarousel: some View {
        ZStack(alignment: .bottom) {
            if !item.images.isEmpty {
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(item.images.enumerated()), id: \.offset) { index, imageUrl in
                        GeometryReader { geometry in
                            Group {
                                if imageUrl.starts(with: "data:image") {
                                    // Handle base64 images
                                    if let data = Data(base64Encoded: String(imageUrl.dropFirst("data:image/jpeg;base64,".count))),
                                       let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width, height: geometry.size.width)
                                            .clipped()
                                    } else {
                                        imagePlaceholder
                                            .frame(width: geometry.size.width, height: geometry.size.width)
                                    }
                                } else {
                                    // Handle URL images
                                    AsyncImage(url: URL(string: imageUrl)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width, height: geometry.size.width)
                                            .clipped()
                                    } placeholder: {
                                        imagePlaceholder
                                            .frame(width: geometry.size.width, height: geometry.size.width)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showingImageGallery = true
                            }
                        }
                        .tag(index)
                    }
                }
                .frame(height: UIScreen.main.bounds.width)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Custom page indicator
                if item.images.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(0..<item.images.count, id: \.self) { index in
                            Circle()
                                .fill(index == selectedImageIndex ? Color.white : Color.white.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
                    .padding(.bottom, 20)
                }
                
                // Overlay badges
                VStack {
                    HStack {
                        HStack(spacing: 6) {
                            if item.isNearby {
                                Badge(
                                    text: "Nearby",
                                    backgroundColor: Color.hopeGreen,
                                    textColor: .white
                                )
                            }
                            
                            if item.isJustListed {
                                Badge(
                                    text: "Just listed",
                                    backgroundColor: Color.hopeOrange,
                                    textColor: .white
                                )
                            }
                        }
                        .padding(.leading, 12)
                        .padding(.top, 12)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                            .padding()
                    }
                    
                    Spacer()
                }
            } else {
                imagePlaceholder
                    .frame(height: UIScreen.main.bounds.width)
            }
        }
    }
    
    @ViewBuilder
    var bottomButtons: some View {
        if !isOwnItem {
            VStack(spacing: 0) {
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                HStack(spacing: 16) {
                    // Ask button
                    Button(action: {
                        showingAskSuggestions = true
                    }) {
                        Text("Ask")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.hopeGreen)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.hopeGreen, lineWidth: 2)
                            )
                    }
                    .buttonStyle(PressedButtonStyle())
                    
                    // Make offer button
                    Button(action: {
                        if item.listingType == .trade || item.isTradeItem {
                            showingTradeOffer = true
                        } else {
                            showingMakeOffer = true
                            if let price = item.price {
                                offerPrice = String(Int(price))
                            }
                        }
                    }) {
                        Text("Make offer")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.hopeGreen)
                            .cornerRadius(25)
                    }
                    .buttonStyle(PressedButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.hopeDarkBg)
            }
        }
    }
    
    @ViewBuilder
    var titlePriceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.top, 20)
            
            HStack(spacing: 12) {
                Text(priceText)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let originalPrice = originalPriceText {
                    Text(originalPrice)
                        .font(.title3)
                        .foregroundColor(.gray)
                        .strikethrough()
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    var sellerInfoSection: some View {
        HStack(spacing: 12) {
            // Seller profile image
            Group {
                if let profileImageURL = item.sellerProfileImageURL,
                   let url = URL(string: profileImageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.sellerUsername ?? "Unknown seller")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("4.8")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("(127 reviews)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("View Profile")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.hopeBlue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.hopeBlue, lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.hopeDarkSecondary)
        )
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    @ViewBuilder
    var actionButtonsSection: some View {
        if !isOwnItem {
            HStack(spacing: 12) {
                Button(action: { trackShare() }) {
                    VStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(.hopeTextPrimary)
                        Text("Share")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.hopeTextPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.hopeDarkSecondary)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.hopeTextSecondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PressedButtonStyle())
                
                Button(action: {
                    trackSave()
                    dataManager.toggleFavorite(item.id)
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: dataManager.favorites.contains(item.id) ? "bookmark.fill" : "bookmark")
                            .font(.title2)
                            .foregroundColor(dataManager.favorites.contains(item.id) ? Color.hopePink : .hopeTextPrimary)
                        Text(dataManager.favorites.contains(item.id) ? "Saved" : "Save")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(dataManager.favorites.contains(item.id) ? Color.hopePink : .hopeTextPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(dataManager.favorites.contains(item.id) ? Color.hopePink.opacity(0.15) : Color.hopeDarkSecondary)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(dataManager.favorites.contains(item.id) ? Color.hopePink.opacity(0.3) : Color.hopeTextSecondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PressedButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color.hopeDarkBg)
        }
    }
    
    @ViewBuilder
    var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Description")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 12) {
                if item.description.isEmpty {
                    Text("No description provided.")
                        .font(.body)
                        .foregroundColor(.gray)
                } else {
                    let formattedDescription = formatDescription(item.description)
                    
                    if isDescriptionExpanded || formattedDescription.count <= 300 {
                        Text(formattedDescription)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(String(formattedDescription.prefix(300)) + "...")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                if !item.description.isEmpty && item.description.count > 300 {
                    Button(action: {
                        withAnimation {
                            isDescriptionExpanded.toggle()
                        }
                    }) {
                        Text(isDescriptionExpanded ? "See less" : "See more")
                            .font(.body)
                            .foregroundColor(Color.hopeBlue)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    var additionalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Location and time
            HStack(spacing: 32) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(item.location)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(timeAgoString(from: item.postedDate))
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Category and Condition
            HStack(spacing: 50) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Category")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                    Text(item.category.rawValue)
                        .font(.system(size: 17))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Condition")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                    Text(item.condition.rawValue)
                        .font(.system(size: 17))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            // Trade preferences if applicable
            if item.isTradeItem {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Trade Preferences")
                        .font(.headline)
                        .foregroundColor(Color.hopeGreen)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        if let lookingFor = item.lookingFor, !lookingFor.isEmpty {
                            TradePreferenceRow(icon: "magnifyingglass", label: "Looking for", value: lookingFor)
                        }
                        
                        if let acceptableItems = item.acceptableItems, !acceptableItems.isEmpty {
                            TradePreferenceRow(icon: "checkmark.circle", label: "Will accept", value: acceptableItems)
                        }
                        
                        if item.openToOffers {
                            HStack {
                                Image(systemName: "hands.sparkles")
                                    .foregroundColor(Color.hopeGreen)
                                Text("Open to all offers")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.hopeGreen.opacity(0.1))
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)
            }
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    var mainContent: some View {
        VStack(spacing: 0) {
            navigationBar
            
            ScrollView {
                VStack(spacing: 0) {
                    imageCarousel
                    
                    VStack(alignment: .leading, spacing: 0) {
                        titlePriceSection
                        sellerInfoSection
                        actionButtonsSection
                        descriptionSection
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 1)
                            .padding(.horizontal, 20)
                        
                        additionalDetailsSection
                    }
                    .padding(.bottom, isOwnItem ? 100 : 160)
                }
            }
            
            bottomButtons
        }
    }
    
    var body: some View {
        ZStack {
            Color.hopeDarkBg
                .ignoresSafeArea()
            
            mainContent
        }
        .navigationBarHidden(true)
        .onAppear {
            trackClick()
        }
        .modifier(
            ListingDetailSheets(
                item: item,
                isOwnItem: isOwnItem,
                conversation: conversation,
                sellerInfo: sellerInfo,
                messageText: messageText,
                messageErrorText: messageErrorText,
                selectedSuggestion: selectedSuggestion,
                offerPrice: offerPrice,
                tradeOfferText: tradeOfferText,
                showingImageGallery: $showingImageGallery,
                selectedImageIndex: $selectedImageIndex,
                showingDeleteAlert: $showingDeleteAlert,
                showingMenu: $showingMenu,
                showingSearch: $showingSearch,
                showingInsights: $showingInsights,
                showingEditFlow: $showingEditFlow,
                showingChat: $showingChat,
                showingMessageError: $showingMessageError,
                showingAskSuggestions: $showingAskSuggestions,
                showingMakeOffer: $showingMakeOffer,
                showingTradeOffer: $showingTradeOffer,
                messageTextBinding: $messageText,
                selectedSuggestionBinding: $selectedSuggestion,
                tradeOfferTextBinding: $tradeOfferText,
                deleteItem: deleteItem,
                sendMessage: sendMessage,
                dataManager: dataManager
            )
        )
    }
    
    func deleteItem() {
        isDeleting = true
        Task {
            // Always use proper deletion from Firestore
            print("🗑️ Deleting item: \(item.title) (ID: \(item.id.uuidString))")
            await dataManager.deleteItem(item)
            
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    func sendMessage() {
        print("📨 sendMessage called with text: '\(messageText)'")
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            print("❌ Message text is empty")
            return 
        }
        
        // Use firebaseUserId if available, otherwise we need to handle this differently
        guard let sellerId = item.firebaseUserId, !sellerId.isEmpty else {
            print("❌ Item doesn't have a valid firebaseUserId. This item may have been created before Firebase Auth was implemented.")
            print("   Item ID: \(item.id)")
            print("   Item userId (UUID): \(item.userId)")
            print("   Item firebaseUserId: \(item.firebaseUserId ?? "nil")")
            
            // Show an alert to the user
            messageErrorText = "Unable to send message to this seller. This listing may have been created before our messaging system was updated. Please try another listing."
            showingMessageError = true
            isSendingMessage = false
            return
        }
        
        print("📨 Sending message to seller: \(sellerId)")
        isSendingMessage = true
        
        Task {
            // First fetch seller information
            await fetchSellerInfo(sellerId: sellerId)
            
            // Create or get existing conversation
            if let conversation = await dataManager.createOrGetConversation(
                with: sellerId,
                itemId: item.id.uuidString
            ) {
                print("✅ Conversation created/found: \(conversation.id)")
                // Send the message
                let success = await dataManager.sendMessage(
                    text: messageText.trimmingCharacters(in: .whitespacesAndNewlines),
                    to: conversation
                )
                
                await MainActor.run {
                    if success {
                        print("✅ Message sent successfully")
                        self.conversation = conversation
                        self.showingChat = true
                    } else {
                        print("❌ Failed to send message")
                    }
                    isSendingMessage = false
                }
            } else {
                print("❌ Failed to create conversation")
                await MainActor.run {
                    isSendingMessage = false
                }
            }
        }
    }
    
    func fetchSellerInfo(sellerId: String) async {
        print("📱 Fetching seller info for ID: \(sellerId)")
        do {
            let db = Firestore.firestore()
            let userDoc = try await db.collection("users").document(sellerId).getDocument()
            
            if userDoc.exists, let data = userDoc.data() {
                await MainActor.run {
                    var user = User(
                        username: data["name"] as? String ?? item.sellerUsername ?? "Unknown User",
                        email: data["email"] as? String ?? ""
                    )
                    user.profileImageURL = data["avatar"] as? String ?? item.sellerProfileImageURL
                    user.profilePicture = data["avatar"] as? String ?? item.sellerProfileImageURL
                    self.sellerInfo = user
                    print("✅ Seller info fetched: \(self.sellerInfo?.username ?? "Unknown")")
                }
            } else {
                // If user document doesn't exist, create from item data
                await MainActor.run {
                    var user = User(
                        username: item.sellerUsername ?? "Unknown User",
                        email: ""
                    )
                    user.profileImageURL = item.sellerProfileImageURL
                    user.profilePicture = item.sellerProfileImageURL
                    self.sellerInfo = user
                    print("⚠️ Using item data for seller info: \(self.sellerInfo?.username ?? "Unknown")")
                }
            }
        } catch {
            print("❌ Error fetching seller info: \(error)")
            // Fallback to item data
            await MainActor.run {
                var user = User(
                    username: item.sellerUsername ?? "Unknown User",
                    email: ""
                )
                user.profileImageURL = item.sellerProfileImageURL
                user.profilePicture = item.sellerProfileImageURL
                self.sellerInfo = user
            }
        }
    }
    
    func timeAgoString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
    
    func categoryColor(for category: Category) -> Color {
        switch category {
        case .electronics: return Color.hopeBlue
        case .booksMoviesMusic: return Color.hopeGreen
        case .toysGames: return Color.hopeOrange
        case .homeKitchen, .homeImprovement, .patioGarden: return Color.hopePurple
        case .sportingGoods: return Color.red
        case .menswear, .womenswear, .kidswearBaby: return Color.hopePink
        case .vehicles, .autoParts: return Color.orange
        case .healthBeauty: return Color.pink
        case .furniture: return Color.brown
        case .petSupplies: return Color.yellow
        case .artsCrafts: return Color.purple
        case .jewelryWatches: return Color.cyan
        case .musicalInstruments: return Color.indigo
        default: return Color.gray
        }
    }
    
    func conditionColor(for condition: Condition) -> Color {
        switch condition {
        case .new: return Color.hopeGreen
        case .likeNew: return Color.hopeBlue
        case .good: return Color.hopeOrange
        case .fair: return Color.yellow
        case .poor: return Color.red
        }
    }
    
    // MARK: - Helper Functions
    func formatDescription(_ description: String) -> String {
        // Replace common patterns with proper line breaks
        var formatted = description
        
        // Handle explicit line breaks
        formatted = formatted.replacingOccurrences(of: "\\n", with: "\n")
        
        // Handle sentence-like breaks
        formatted = formatted.replacingOccurrences(of: ". ", with: ".\n\n")
        formatted = formatted.replacingOccurrences(of: "! ", with: "!\n\n")
        formatted = formatted.replacingOccurrences(of: "? ", with: "?\n\n")
        
        // Handle list-like patterns
        formatted = formatted.replacingOccurrences(of: " - ", with: "\n- ")
        formatted = formatted.replacingOccurrences(of: " • ", with: "\n• ")
        
        // Handle colon patterns (like "What's Included:")
        formatted = formatted.replacingOccurrences(of: ": ", with: ":\n")
        
        // Clean up any multiple newlines
        while formatted.contains("\n\n\n") {
            formatted = formatted.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Analytics Tracking
    func trackClick() {
        Task {
            do {
                print("📊 Tracking click for item: \(item.title) (ID: \(item.id.uuidString))")
                try await FirestoreManager.shared.incrementItemClick(itemId: item.id.uuidString)
                print("✅ Click tracked successfully")
            } catch {
                print("❌ Failed to track click for item \(item.id.uuidString): \(error.localizedDescription)")
            }
        }
    }
    
    func trackSave() {
        Task {
            do {
                let isCurrentlyFavorited = dataManager.favorites.contains(item.id)
                print("📊 Tracking save for item: \(item.title) (ID: \(item.id.uuidString))")
                print("📊 Currently favorited: \(isCurrentlyFavorited)")
                
                // Check if the user is adding or removing from favorites
                if isCurrentlyFavorited {
                    // User is removing from favorites
                    print("📊 Decrementing save count (removing from favorites)")
                    try await FirestoreManager.shared.decrementItemSave(itemId: item.id.uuidString)
                } else {
                    // User is adding to favorites
                    print("📊 Incrementing save count (adding to favorites)")
                    try await FirestoreManager.shared.incrementItemSave(itemId: item.id.uuidString)
                }
                print("✅ Save tracked successfully")
            } catch {
                print("❌ Failed to track save for item \(item.id.uuidString): \(error.localizedDescription)")
            }
        }
    }
    
    func trackShare() {
        Task {
            do {
                print("📊 Tracking share for item: \(item.title) (ID: \(item.id.uuidString))")
                try await FirestoreManager.shared.incrementItemShare(itemId: item.id.uuidString)
                print("✅ Share tracked successfully")
            } catch {
                print("❌ Failed to track share for item \(item.id.uuidString): \(error.localizedDescription)")
            }
        }
    }
    
    func trackVideoPlay() {
        Task {
            do {
                print("📊 Tracking video play for item: \(item.title) (ID: \(item.id.uuidString))")
                try await FirestoreManager.shared.incrementVideoPlay(itemId: item.id.uuidString)
                print("✅ Video play tracked successfully")
            } catch {
                print("❌ Failed to track video play for item \(item.id.uuidString): \(error.localizedDescription)")
            }
        }
    }
}

struct TradePreferenceRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(Color.hopeGreen)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
}

struct AskSuggestionsSheet: View {
    @Binding var showingAskSuggestions: Bool
    @Binding var messageText: String
    @Binding var selectedSuggestion: String
    let onSend: () -> Void
    let isTradeItem: Bool
    @FocusState private var isCustomMessageFocused: Bool
    @State private var customMessage = ""
    
    var suggestions: [String] {
        if isTradeItem {
            // Trade-specific suggestions (excluding purchase-related questions)
            return [
                "Hi, is this still available?",
                "Hi, can I pick it up today?",
                "What's the condition like?",
                "Are you available this weekend?",
                "What items are you looking to trade for?",
                "Would you consider trading for something similar?"
            ]
        } else {
            // Regular sale suggestions
            return [
                "Hi, is this still available?",
                "Hi, I'd like to buy this.",
                "Hi, can I pick it up today?",
                "Is the price negotiable?",
                "What's the condition like?",
                "Can you deliver this?",
                "Are you available this weekend?"
            ]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Ask a question")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    showingAskSuggestions = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 12) {
                    // Suggested messages
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: {
                            messageText = suggestion
                            onSend()
                        }) {
                            Text(suggestion)
                                .font(.body)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.hopeDarkBg)
                                .cornerRadius(12)
                        }
                        .buttonStyle(PressedButtonStyle())
                    }
                    
                    // Custom message input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Or type your own message")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            TextField("Type your message...", text: $customMessage)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.hopeDarkBg)
                                .cornerRadius(8)
                                .focused($isCustomMessageFocused)
                            
                            Button(action: {
                                if !customMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    messageText = customMessage
                                    onSend()
                                }
                            }) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(customMessage.isEmpty ? .gray : Color.hopeGreen)
                                    .padding(12)
                                    .background(Color.hopeDarkBg)
                                    .cornerRadius(8)
                            }
                            .disabled(customMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .onAppear {
            isCustomMessageFocused = true
        }
    }
}

struct MakeOfferSheet: View {
    let item: Item
    @Binding var showingMakeOffer: Bool
    @Binding var offerPrice: String
    let onSubmit: (Int) -> Void
    @FocusState private var isPriceFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Enter Your Offer")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Cancel") {
                    showingMakeOffer = false
                }
                .foregroundColor(Color.hopeGreen)
            }
            .padding()
            
            VStack(spacing: 24) {
                // Price input
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hopeDarkBg)
                            .frame(height: 60)
                        
                        HStack(spacing: 0) {
                            Text("$")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                            
                            TextField("0", text: $offerPrice)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .keyboardType(.numberPad)
                                .focused($isPriceFocused)
                                .onChange(of: offerPrice) { newValue in
                                    // Only allow numbers
                                    offerPrice = newValue.filter { $0.isNumber }
                                }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    if let originalPrice = item.price, originalPrice > 0 {
                        Text("Listed at $\(Int(originalPrice))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Item info
                HStack(spacing: 12) {
                    if let firstImage = item.images.first, let url = URL(string: firstImage) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    VStack(alignment: .leading) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text(item.condition.rawValue)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                
                Spacer()
                
                // Submit button
                Button(action: {
                    if let price = Int(offerPrice), price > 0 {
                        onSubmit(price)
                    }
                }) {
                    Text("Make offer")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            offerPrice.isEmpty || Int(offerPrice) == 0 
                            ? Color.gray 
                            : Color.hopeGreen
                        )
                        .cornerRadius(25)
                }
                .disabled(offerPrice.isEmpty || Int(offerPrice) == 0)
                .padding(.bottom)
            }
            .padding()
        }
        .onAppear {
            isPriceFocused = true
        }
    }
}

struct TradeOfferSheet: View {
    let item: Item
    @Binding var showingTradeOffer: Bool
    @Binding var tradeOfferText: String
    let onSubmit: (String) -> Void
    
    @State private var selectedQuestionIndex = 0
    @State private var customOfferText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    // Generate intelligent questions based on listing details
    var intelligentQuestions: [String] {
        var questions: [String] = []
        
        // Questions based on what they're looking for
        if let lookingFor = item.lookingFor, !lookingFor.isEmpty {
            questions.append("I have \(lookingFor.lowercased()) to trade")
            
            // Parse common items they might be looking for
            let keywords = lookingFor.lowercased()
            if keywords.contains("game") || keywords.contains("console") {
                questions.append("I have a gaming console with games")
                questions.append("I have PS5/Xbox/Nintendo games")
            }
            if keywords.contains("phone") || keywords.contains("electronic") {
                questions.append("I have electronics to trade")
                questions.append("I have a smartphone in good condition")
            }
            if keywords.contains("laptop") || keywords.contains("computer") {
                questions.append("I have computer equipment to trade")
            }
        }
        
        // Questions based on acceptable items
        if let acceptableItems = item.acceptableItems, !acceptableItems.isEmpty {
            let acceptable = acceptableItems.lowercased()
            if acceptable.contains("similar") {
                questions.append("I have a similar \(item.category.rawValue.lowercased()) item")
            }
            if acceptable.contains("any") || acceptable.contains("open") {
                questions.append("I have something interesting to offer")
            }
        }
        
        // Category-specific questions
        switch item.category {
        case .electronics:
            questions.append("I have other electronics to trade")
            questions.append("I have accessories that might interest you")
        case .toysGames:
            questions.append("I have other toys/games to trade")
            questions.append("I have collectibles you might like")
        case .sportingGoods:
            questions.append("I have sports equipment to trade")
            questions.append("I have fitness gear to offer")
        case .musicalInstruments:
            questions.append("I have music equipment to trade")
            questions.append("I have audio gear to offer")
        case .booksMoviesMusic:
            questions.append("I have books/movies/music to trade")
            questions.append("I have a collection you might like")
        default:
            questions.append("I have items in the same category")
        }
        
        // Always add custom option
        questions.append("I'd like to make a custom offer")
        
        // Remove duplicates while preserving order
        var seen = Set<String>()
        return questions.filter { seen.insert($0).inserted }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Make a Trade Offer")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    showingTradeOffer = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Item info
            HStack(spacing: 12) {
                if let firstImage = item.images.first,
                   let url = URL(string: firstImage) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if let lookingFor = item.lookingFor, !lookingFor.isEmpty {
                        Text("Looking for: \(lookingFor)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    } else {
                        Text("Open to offers")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select an offer or write your own:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    ForEach(Array(intelligentQuestions.enumerated()), id: \.offset) { index, question in
                        Button(action: {
                            selectedQuestionIndex = index
                            if question == "I'd like to make a custom offer" {
                                isTextFieldFocused = true
                            }
                        }) {
                            HStack {
                                Image(systemName: selectedQuestionIndex == index ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(selectedQuestionIndex == index ? Color.hopeGreen : .gray)
                                
                                Text(question)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedQuestionIndex == index ? Color.hopeGreen.opacity(0.2) : Color.black.opacity(0.3))
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Custom text field if custom option is selected
                    if selectedQuestionIndex == intelligentQuestions.count - 1 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Describe what you have to offer:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("E.g., I have a Nintendo Switch with games...", text: $customOfferText, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...5)
                                .focused($isTextFieldFocused)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
                .padding(.bottom)
            }
            
            Spacer()
            
            // Submit button
            Button(action: {
                let offerText: String
                if selectedQuestionIndex == intelligentQuestions.count - 1 {
                    // Custom offer
                    offerText = customOfferText.isEmpty ? "I'd like to make a trade offer" : customOfferText
                } else {
                    offerText = intelligentQuestions[selectedQuestionIndex]
                }
                onSubmit(offerText)
            }) {
                Text("Send Offer")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        (selectedQuestionIndex == intelligentQuestions.count - 1 && customOfferText.isEmpty) 
                        ? Color.gray 
                        : Color.hopeGreen
                    )
                    .cornerRadius(25)
            }
            .disabled(selectedQuestionIndex == intelligentQuestions.count - 1 && customOfferText.isEmpty)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

