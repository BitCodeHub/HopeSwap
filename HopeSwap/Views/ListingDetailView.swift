import SwiftUI
import FirebaseAuth

struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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
    
    var isOwnItem: Bool {
        guard let currentUserId = AuthenticationManager.shared.currentUserId else { return false }
        return item.firebaseUserId == currentUserId || item.userId.uuidString == currentUserId
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
            let originalPrice = price * 1.2 // Assuming 20% discount for demo
            return "$\(Int(originalPrice))"
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
    
    var body: some View {
        ZStack {
            Color.hopeDarkBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        if isOwnItem {
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                            .disabled(isDeleting)
                        } else {
                            Button(action: {}) {
                                Image(systemName: "magnifyingglass")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "ellipsis")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Full-width image carousel
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
                                            .contentShape(Rectangle()) // Make entire area tappable
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
                                
                                // Zoom icon indicator (top right)
                                VStack {
                                    HStack {
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
                        
                        VStack(alignment: .leading, spacing: 0) {
                            // Title and price section
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
                            
                            // Seller information section
                            HStack(spacing: 12) {
                                // Seller profile image
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
                            
                            // Message seller section (hide for own items)
                            if !isOwnItem {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "message.fill")
                                            .font(.body)
                                            .foregroundColor(Color.hopeBlue)
                                        
                                        Text("Send seller a message")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        TextField("", text: $messageText)
                                            .placeholder(when: messageText.isEmpty) {
                                                Text("Type a message...")
                                                    .foregroundColor(.gray)
                                            }
                                            .foregroundColor(.white)
                                            .padding(12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(Color.white.opacity(0.1))
                                            )
                                        
                                        Button(action: {}) {
                                            Text("Send")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 24)
                                                .padding(.vertical, 12)
                                                .background(Color.hopeBlue)
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.2))
                                .padding(.top, 12)
                            }
                            
                            // Action buttons - Redesigned with HopeSwap theme (hide for own items)
                            if !isOwnItem {
                                VStack(spacing: 16) {
                                    // Primary action buttons
                                    HStack(spacing: 12) {
                                    // Send offer - Primary button
                                    Button(action: {}) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "person.2.fill")
                                                .font(.title3)
                                                .foregroundColor(.white)
                                            Text("Send offer")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.hopeBlue)
                                        .cornerRadius(12)
                                        .shadow(color: Color.hopeBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                                    }
                                    .buttonStyle(PressedButtonStyle())
                                    
                                    // Alerts - Secondary accent button
                                    Button(action: {}) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "bell.fill")
                                                .font(.title3)
                                                .foregroundColor(.hopeBlue)
                                            Text("Alerts")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.hopeBlue)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.hopeBlue.opacity(0.15))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.hopeBlue.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PressedButtonStyle())
                                }
                                
                                // Secondary action buttons
                                HStack(spacing: 12) {
                                    Button(action: {}) {
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
                                    
                                    Button(action: {}) {
                                        VStack(spacing: 6) {
                                            Image(systemName: "bookmark")
                                                .font(.title2)
                                                .foregroundColor(.hopeTextPrimary)
                                            Text("Save")
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
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .background(Color.hopeDarkBg)
                            }
                            
                            // Description section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Description")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(item.description.isEmpty ? "No description provided." : item.description)
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                if !item.description.isEmpty && item.description.count > 200 {
                                    Button(action: {}) {
                                        Text("See more")
                                            .font(.body)
                                            .foregroundColor(Color.hopeBlue)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Additional details
                            VStack(alignment: .leading, spacing: 16) {
                                // Location and time
                                HStack(spacing: 24) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "location")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(item.location)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    HStack(spacing: 6) {
                                        Image(systemName: "clock")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(timeAgoString(from: item.postedDate))
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                
                                // Category and Condition
                                HStack(spacing: 24) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Category")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(item.category.rawValue)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Condition")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(item.condition.rawValue)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
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
                        .padding(.bottom, 100) // Space for tab bar
                    }
                }
            }
        }
        .navigationBarHidden(true)
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
    }
    
    func deleteItem() {
        isDeleting = true
        Task {
            await dataManager.deleteItem(item)
            await MainActor.run {
                dismiss()
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

