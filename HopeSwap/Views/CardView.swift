import SwiftUI

struct CardView: View {
    let item: Item
    @State private var offset = CGSize.zero
    @State private var isDragging = false
    var removal: (() -> Void)? = nil
    var onSwipeLeft: (() -> Void)? = nil
    var onSwipeRight: (() -> Void)? = nil
    
    func animateRemoval(direction: Int) {
        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(
                width: CGFloat(500 * direction),
                height: 50
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if direction > 0 {
                onSwipeRight?()
            } else {
                onSwipeLeft?()
            }
            removal?()
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(
                    color: Color.black.opacity(isDragging ? 0.15 : 0.1), 
                    radius: isDragging ? 12 : 8, 
                    x: 0, 
                    y: isDragging ? 8 : 4
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            
            VStack(spacing: 12) {
                if let firstImage = item.images.first {
                    AsyncImage(url: URL(string: firstImage)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 300)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                            )
                    }
                    .cornerRadius(15)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                        .cornerRadius(15)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Label(item.category.rawValue, systemImage: "tag")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Label(item.condition.rawValue, systemImage: "star")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(item.description)
                        .font(.body)
                        .lineLimit(3)
                        .foregroundColor(.black.opacity(0.8))
                    
                    // Price or Trade indicator
                    HStack {
                        if item.isTradeItem {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.caption)
                                Text("For Trade")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(Color(hex: "00D9B1"))
                        } else if let price = item.price {
                            HStack(spacing: 8) {
                                Text("$\(String(format: "%.2f", price))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                if item.priceIsFirm {
                                    Text("FIRM")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color(hex: "00D9B1"))
                                        )
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Label(item.location, systemImage: "location")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Label("\(item.favoriteCount)", systemImage: "heart")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            
            ZStack {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                    .opacity(Double(max(0, offset.width - 50) / 100))
                    .scaleEffect(offset.width > 100 ? 1.1 : 0.8)
                
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.red)
                    .opacity(Double(max(0, -offset.width - 50) / 100))
                    .scaleEffect(offset.width < -100 ? 1.1 : 0.8)
            }
        }
        .frame(maxWidth: 340, maxHeight: 580)
        .offset(x: offset.width, y: offset.height * 0.4)
        .opacity(2 - Double(abs(offset.width / 200)))
        .rotationEffect(.degrees(Double(offset.width / 30)), anchor: .bottom)
        .animation(isDragging ? .none : .interpolatingSpring(stiffness: 180, damping: 20), value: offset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    isDragging = true
                    offset = gesture.translation
                }
                .onEnded { gesture in
                    isDragging = false
                    
                    if abs(offset.width) > 100 || abs(gesture.predictedEndTranslation.width) > 150 {
                        // Card will be removed
                        let direction = offset.width > 0 ? 1 : -1
                        
                        withAnimation(.easeOut(duration: 0.3)) {
                            offset = CGSize(
                                width: CGFloat(500 * direction), 
                                height: offset.height + 100
                            )
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if direction > 0 {
                                onSwipeRight?()
                            } else {
                                onSwipeLeft?()
                            }
                            removal?()
                        }
                    } else {
                        // Card returns to center
                        withAnimation(.interpolatingSpring(stiffness: 200, damping: 25)) {
                            offset = .zero
                        }
                    }
                }
        )
    }
}

