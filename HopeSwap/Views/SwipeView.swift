import SwiftUI

struct SwipeView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var displayedItems: [Item] = []
    @State private var skipButtonPressed = false
    @State private var likeButtonPressed = false
    
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
                
                HStack(spacing: 80) {
                    Button(action: {
                        skipButtonPressed = true
                        skipCurrentItem()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            skipButtonPressed = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                            .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .scaleEffect((displayedItems.isEmpty ? 0.8 : 1.0) * (skipButtonPressed ? 0.9 : 1.0))
                    .disabled(displayedItems.isEmpty)
                    .opacity(displayedItems.isEmpty ? 0.5 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: skipButtonPressed)
                    
                    Button(action: {
                        likeButtonPressed = true
                        favoriteCurrentItem()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            likeButtonPressed = false
                        }
                    }) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .scaleEffect((displayedItems.isEmpty ? 0.8 : 1.0) * (likeButtonPressed ? 0.9 : 1.0))
                    .disabled(displayedItems.isEmpty)
                    .opacity(displayedItems.isEmpty ? 0.5 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: likeButtonPressed)
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