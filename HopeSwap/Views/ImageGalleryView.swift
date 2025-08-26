import SwiftUI

struct ImageGalleryView: View {
    let images: [String]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) var dismiss
    @GestureState private var dragOffset: CGSize = .zero
    @State private var currentIndex: Int
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var isZoomed: Bool = false
    
    init(images: [String], selectedIndex: Binding<Int>) {
        self.images = images
        self._selectedIndex = selectedIndex
        self._currentIndex = State(initialValue: selectedIndex.wrappedValue)
    }
    
    private var drag: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                if !isZoomed {
                    state = value.translation
                }
            }
            .onEnded { value in
                if isZoomed {
                    // If zoomed, handle pan
                    withAnimation(.spring()) {
                        imageOffset = CGSize(
                            width: imageOffset.width + value.translation.width,
                            height: imageOffset.height + value.translation.height
                        )
                    }
                } else {
                    // Handle swipe between images
                    let threshold: CGFloat = 50
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    
                    // Dismiss if swiped down significantly
                    if verticalAmount > 100 {
                        dismiss()
                        return
                    }
                    
                    // Navigate between images
                    withAnimation(.spring()) {
                        if horizontalAmount < -threshold && currentIndex < images.count - 1 {
                            currentIndex += 1
                        } else if horizontalAmount > threshold && currentIndex > 0 {
                            currentIndex -= 1
                        }
                    }
                    selectedIndex = currentIndex
                }
            }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
                .opacity(isZoomed ? 1 : 0.9)
            
            VStack(spacing: 0) {
                // Header
                ZStack {
                    // Title
                    Text("\(currentIndex + 1) of \(images.count)")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                    
                    // Close button
                    HStack {
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 50)
                .padding(.bottom, 20)
                
                // Image viewer
                GeometryReader { geometry in
                    TabView(selection: $currentIndex) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, imageUrl in
                            ZStack {
                                Color.clear
                                
                                Group {
                                    if imageUrl.starts(with: "data:image") {
                                        // Handle base64 images
                                        if let data = Data(base64Encoded: String(imageUrl.dropFirst("data:image/jpeg;base64,".count))),
                                           let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .scaleEffect(index == currentIndex ? imageScale : 1)
                                                .offset(index == currentIndex ? imageOffset : .zero)
                                        } else {
                                            imagePlaceholder
                                        }
                                    } else {
                                        // Handle URL images
                                        AsyncImage(url: URL(string: imageUrl)) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(1.5)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .scaleEffect(index == currentIndex ? imageScale : 1)
                                                    .offset(index == currentIndex ? imageOffset : .zero)
                                            case .failure(_):
                                                imagePlaceholder
                                            @unknown default:
                                                imagePlaceholder
                                            }
                                        }
                                    }
                                }
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .onTapGesture(count: 2) {
                                    if index == currentIndex {
                                        withAnimation(.spring()) {
                                            if imageScale > 1 {
                                                imageScale = 1
                                                imageOffset = .zero
                                                isZoomed = false
                                            } else {
                                                imageScale = 2
                                                isZoomed = true
                                            }
                                        }
                                    }
                                }
                                .simultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            if index == currentIndex {
                                                imageScale = value
                                                isZoomed = value > 1
                                            }
                                        }
                                        .onEnded { value in
                                            if index == currentIndex {
                                                withAnimation(.spring()) {
                                                    if value < 1 {
                                                        imageScale = 1
                                                        imageOffset = .zero
                                                        isZoomed = false
                                                    } else if value > 3 {
                                                        imageScale = 3
                                                    }
                                                }
                                            }
                                        }
                                )
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .offset(x: isZoomed ? 0 : dragOffset.width, y: isZoomed ? 0 : dragOffset.height)
                    .gesture(drag)
                }
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<images.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentIndex ? 1.2 : 1)
                            .animation(.spring(response: 0.3), value: currentIndex)
                    }
                }
                .padding(.vertical, 30)
            }
        }
        .statusBarHidden()
    }
    
    var imagePlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                VStack(spacing: 16) {
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Image unavailable")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            )
    }
}