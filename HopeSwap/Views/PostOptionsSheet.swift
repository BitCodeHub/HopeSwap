import SwiftUI

struct PostOptionsSheet: View {
    @Binding var selectedPostType: ContentView.PostType?
    @Binding var showingPostOptions: Bool
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                Text("What would you like to post?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                
                Text("Choose a category to get started")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 24)
            }
            
            // Options Grid
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Main posting options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Post Items")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            PostOptionCard(
                                icon: "tag.fill",
                                title: "Sell",
                                subtitle: "List item for sale",
                                color: Color.hopeBlue,
                                action: {
                                    showingPostOptions = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        selectedPostType = .itemForSale
                                    }
                                }
                            )
                            
                            PostOptionCard(
                                icon: "arrow.left.arrow.right",
                                title: "Trade",
                                subtitle: "Exchange items",
                                color: Color.hopeGreen,
                                action: {
                                    showingPostOptions = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        selectedPostType = .itemForTrade
                                    }
                                }
                            )
                            
                            PostOptionCard(
                                icon: "gift.fill",
                                title: "Give Away",
                                subtitle: "Free to a good home",
                                color: Color.hopePink,
                                action: {
                                    showingPostOptions = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        selectedPostType = .freebies
                                    }
                                }
                            )
                            
                            PostOptionCard(
                                icon: "hand.raised.fill",
                                title: "Need Help",
                                subtitle: "Ask for assistance",
                                color: Color.hopeOrange,
                                action: {
                                    showingPostOptions = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        selectedPostType = .needHelp
                                    }
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Community options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Find Buddies")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            PostOptionCard(
                                icon: "car.fill",
                                title: "Carpool",
                                subtitle: "Share rides",
                                color: Color.purple,
                                action: {
                                    showingPostOptions = false
                                    // TODO: Implement carpool flow
                                }
                            )
                            
                            PostOptionCard(
                                icon: "figure.run",
                                title: "Workout",
                                subtitle: "Find gym partner",
                                color: Color.red,
                                action: {
                                    showingPostOptions = false
                                    // TODO: Implement workout buddy flow
                                }
                            )
                            
                            PostOptionCard(
                                icon: "figure.walk",
                                title: "Walking",
                                subtitle: "Walking companion",
                                color: Color.mint,
                                action: {
                                    showingPostOptions = false
                                    // TODO: Implement walking buddy flow
                                }
                            )
                            
                            PostOptionCard(
                                icon: "fork.knife",
                                title: "Lunch",
                                subtitle: "Meal companion",
                                color: Color.orange,
                                action: {
                                    showingPostOptions = false
                                    // TODO: Implement lunch buddy flow
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Events section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Community")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .padding(.horizontal, 20)
                        
                        HStack {
                            PostOptionCard(
                                icon: "calendar",
                                title: "Events",
                                subtitle: "Host or join events",
                                color: Color.hopePurple,
                                action: {
                                    showingPostOptions = false
                                    // TODO: Implement events flow
                                }
                            )
                            
                            // Empty space to maintain grid alignment
                            Color.clear
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.hopeDarkBg)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct PostOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.hopeDarkSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(color.opacity(isPressed ? 0.5 : 0), lineWidth: 2)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    PostOptionsSheet(
        selectedPostType: .constant(nil),
        showingPostOptions: .constant(true)
    )
}