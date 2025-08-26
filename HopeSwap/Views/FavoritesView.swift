import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedItem: Item? = nil
    @Environment(\.presentationMode) var presentationMode
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                VStack {
                    // Custom header
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        Text("Favorites")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Spacer to balance the header
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if dataManager.getFavoriteItems().isEmpty {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 80))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No favorites yet")
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            Text("Tap the heart icon on items you love!")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(dataManager.getFavoriteItems()) { item in
                                    DiscoverItemCard(item: item, isCompact: false)
                                        .onTapGesture {
                                            selectedItem = item
                                        }
                                }
                            }
                            .padding()
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(item: $selectedItem) { item in
            ListingDetailView(item: item)
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
                    .foregroundColor(.white)
                
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
        .background(Color.hopeDarkSecondary)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}