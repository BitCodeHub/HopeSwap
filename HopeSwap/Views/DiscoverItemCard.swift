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
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipped()
            .cornerRadius(12)
            
            // Price and title below image
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    Text(priceText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(" - ")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Text(item.title)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Seller info
                HStack(spacing: 4) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(item.sellerUsername ?? "Unknown seller")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
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