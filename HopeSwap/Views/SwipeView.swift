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
                    if displayedItems.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "tray.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.gray.opacity(0.3))
                            
                            Text("No more items")
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            Text("Check back later for new listings!")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        .frame(maxWidth: 340, maxHeight: 580)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.gray.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                )
                        )
                    } else {
                        ForEach(Array(displayedItems.enumerated().reversed()), id: \.element.id) { index, item in
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
                            .stacked(at: index, in: displayedItems.count)
                            .allowsHitTesting(index == 0)
                        }
                    }
                }
                .padding(.horizontal)
                
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
                    .scaleEffect((displayedItems.isEmpty ? 0.8 : 1.0) * (skipButtonPressed ? 0.95 : 1.0))
                    .disabled(displayedItems.isEmpty)
                    .opacity(displayedItems.isEmpty ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: skipButtonPressed)
                    
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
                    .scaleEffect((displayedItems.isEmpty ? 0.8 : 1.0) * (likeButtonPressed ? 0.95 : 1.0))
                    .disabled(displayedItems.isEmpty)
                    .opacity(displayedItems.isEmpty ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: likeButtonPressed)
                }
                .padding()
            }
        }
        .onAppear {
            loadItems()
        }
        .onChange(of: dataManager.items) {
            loadItems()
        }
    }
    
    func loadItems() {
        displayedItems = dataManager.items
    }
    
    func removeCard(_ item: Item) {
        withAnimation(.easeInOut(duration: 0.3)) {
            displayedItems.removeAll { $0.id == item.id }
        }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                removeCard(firstItem)
            }
        }
    }
    
    func favoriteCurrentItem() {
        if let firstItem = displayedItems.first {
            favoriteItem(firstItem)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                removeCard(firstItem)
            }
        }
    }
}

extension View {
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = Double(position)
        return self
            .scaleEffect(position == 0 ? 1 : (0.95 - (offset * 0.02)))
            .offset(y: position == 0 ? 0 : (offset * 12))
            .opacity(position < 3 ? 1 : 0)
            .zIndex(Double(total - position))
    }
}