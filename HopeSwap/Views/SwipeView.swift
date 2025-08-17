import SwiftUI

struct SwipeView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var displayedItems: [Item] = []
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.pink.opacity(0.1), Color.blue.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Text("HopeSwap")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "heart.fill")
                            .font(.title2)
                            .foregroundColor(.pink)
                    }
                }
                .padding()
                
                ZStack {
                    ForEach(displayedItems) { item in
                        CardView(
                            item: item,
                            removal: {
                                removeCard(item)
                            },
                            onSwipeLeft: {
                                skipItem(item)
                            },
                            onSwipeRight: {
                                favoriteItem(item)
                            }
                        )
                        .stacked(at: displayedItems.firstIndex(where: { $0.id == item.id }) ?? 0, in: displayedItems.count)
                    }
                }
                .padding()
                
                HStack(spacing: 60) {
                    Button(action: skipCurrentItem) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: favoriteCurrentItem) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            loadItems()
        }
        .onChange(of: dataManager.items) { _ in
            loadItems()
        }
    }
    
    func loadItems() {
        displayedItems = dataManager.items
    }
    
    func removeCard(_ item: Item) {
        displayedItems.removeAll { $0.id == item.id }
    }
    
    func skipItem(_ item: Item) {
        print("Skipped: \(item.title)")
    }
    
    func favoriteItem(_ item: Item) {
        dataManager.toggleFavorite(item.id)
        print("Favorited: \(item.title)")
    }
    
    func skipCurrentItem() {
        if let firstItem = displayedItems.first {
            skipItem(firstItem)
            removeCard(firstItem)
        }
    }
    
    func favoriteCurrentItem() {
        if let firstItem = displayedItems.first {
            favoriteItem(firstItem)
            removeCard(firstItem)
        }
    }
}

extension View {
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = Double(total - position)
        return self.offset(y: offset * 10)
    }
}