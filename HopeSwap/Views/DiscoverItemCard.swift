import SwiftUI

struct DiscoverItemCard: View {
    let item: Item
    let isCompact: Bool
    
    var priceText: String {
        if let price = item.price {
            return price == 0 ? "Free" : "$\(Int(price))"
        } else {
            return "Trade"
        }
    }
    
    var imagePlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: isCompact ? 160 : 200)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with overlay badges
            ZStack(alignment: .topLeading) {
                // Background image
                Group {
                    if let firstImage = item.images.first {
                        if firstImage.starts(with: "data:image") {
                            // Handle base64 images
                            if let data = Data(base64Encoded: String(firstImage.dropFirst("data:image/jpeg;base64,".count))),
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .frame(height: isCompact ? 160 : 200)
                            } else {
                                imagePlaceholder
                            }
                        } else {
                            // Handle URL images
                            AsyncImage(url: URL(string: firstImage)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .frame(height: isCompact ? 160 : 200)
                            } placeholder: {
                                imagePlaceholder
                            }
                        }
                    } else {
                        imagePlaceholder
                    }
                }
                .clipped()
                
                // Badges
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if item.isJustListed {
                            Badge(text: "Just listed", backgroundColor: .white, textColor: .black)
                        }
                        if item.isNearby {
                            Badge(text: "Nearby", backgroundColor: .white, textColor: .black)
                        }
                    }
                    
                    Spacer()
                }
                .padding(8)
            }
            .frame(height: isCompact ? 160 : 200)
            .clipped()
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(priceText)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if item.price == 0 || item.price == nil {
                        Text("•")
                            .foregroundColor(.gray)
                    }
                }
                
                Text(item.title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.hopeDarkSecondary)
        }
        .frame(width: isCompact ? 160 : nil)
        .background(Color.hopeDarkSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct Badge: View {
    let text: String
    let backgroundColor: Color
    let textColor: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(textColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(backgroundColor)
            )
    }
}