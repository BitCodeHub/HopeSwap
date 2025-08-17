import SwiftUI

struct PostOptionsSheet: View {
    @Binding var selectedPostType: ContentView.PostType?
    @Binding var showingPostOptions: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("Create a new post")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 30)
                .padding(.bottom, 25)
            
            // Options
            VStack(spacing: 0) {
                PostOptionRow(
                    icon: "tag.fill",
                    title: "Item for sale",
                    action: {
                        showingPostOptions = false
                        // Small delay to ensure sheet dismisses before presenting fullScreenCover
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedPostType = .itemForSale
                        }
                    }
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                PostOptionRow(
                    icon: "arrow.left.arrow.right",
                    title: "Item for trade",
                    action: {
                        showingPostOptions = false
                        // Small delay to ensure sheet dismisses before presenting fullScreenCover
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedPostType = .itemForTrade
                        }
                    }
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                PostOptionRow(
                    icon: "gift.fill",
                    title: "Freebies",
                    action: {
                        showingPostOptions = false
                        // TODO: Implement freebies flow
                    }
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                PostOptionRow(
                    icon: "hand.raised.fill",
                    title: "I need help",
                    action: {
                        showingPostOptions = false
                        // TODO: Implement help flow
                    }
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                PostOptionRow(
                    icon: "calendar",
                    title: "Events",
                    action: {
                        showingPostOptions = false
                        // TODO: Implement events flow
                    }
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "1C2B3B"))
            )
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.9))
    }
}

struct PostOptionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

