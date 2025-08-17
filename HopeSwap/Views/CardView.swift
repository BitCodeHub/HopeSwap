import SwiftUI

struct CardView: View {
    let item: Item
    @State private var offset = CGSize.zero
    @State private var color: Color = .black
    var removal: (() -> Void)? = nil
    var onSwipeLeft: (() -> Void)? = nil
    var onSwipeRight: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
            
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
                    .scaleEffect(offset.width > 100 ? 1.2 : 0.8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: offset.width)
                
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.red)
                    .opacity(Double(max(0, -offset.width - 50) / 100))
                    .scaleEffect(offset.width < -100 ? 1.2 : 0.8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: offset.width)
            }
        }
        .frame(width: 350, height: 600)
        .offset(x: offset.width, y: offset.height)
        .opacity(2 - Double(abs(offset.width / 150)))
        .rotationEffect(.degrees(Double(offset.width / 40)), anchor: .bottom)
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.25), value: offset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    withAnimation {
                        if offset.width > 100 {
                            color = .green
                        } else if offset.width < -100 {
                            color = .red
                        } else {
                            color = .black
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.25)) {
                        if abs(offset.width) > 100 {
                            let direction = offset.width > 0 ? 1 : -1
                            offset = CGSize(width: CGFloat(500 * direction), height: offset.height + 50)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if offset.width > 0 {
                                    onSwipeRight?()
                                } else {
                                    onSwipeLeft?()
                                }
                                removal?()
                            }
                        } else {
                            offset = .zero
                            color = .black
                        }
                    }
                }
        )
    }
}