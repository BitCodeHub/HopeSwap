import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                if dataManager.getFavoriteItems().isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No favorites yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("Swipe right on items you love!")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(dataManager.getFavoriteItems()) { item in
                            FavoriteItemCard(item: item)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct FavoriteItemCard: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let firstImage = item.images.first {
                AsyncImage(url: URL(string: firstImage)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 150)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 150)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        )
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(item.condition.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "location")
                        .font(.caption2)
                    Text(item.location)
                        .font(.caption)
                }
                .foregroundColor(.gray)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}