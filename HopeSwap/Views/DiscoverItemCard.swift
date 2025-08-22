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
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image with overlays
            GeometryReader { geometry in
                ZStack {
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
                                        .frame(width: geometry.size.width, height: geometry.size.width)
                                } else {
                                    imagePlaceholder
                                        .frame(width: geometry.size.width, height: geometry.size.width)
                                }
                            } else {
                                // Handle URL images
                                AsyncImage(url: URL(string: firstImage)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width, height: geometry.size.width)
                                } placeholder: {
                                    imagePlaceholder
                                        .frame(width: geometry.size.width, height: geometry.size.width)
                                }
                            }
                        } else {
                            imagePlaceholder
                                .frame(width: geometry.size.width, height: geometry.size.width)
                        }
                    }
                    .clipped()
                    
                    // Price overlay at bottom left
                    VStack {
                        Spacer()
                        HStack {
                            Text(priceText)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.7))
                                )
                            Spacer()
                        }
                        .padding(12)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipped()
            .cornerRadius(12)
            
            // Title below image
            Text(item.title)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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