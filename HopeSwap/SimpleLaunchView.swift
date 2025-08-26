import SwiftUI

struct SimpleLaunchView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var isActive = false
    
    var body: some View {
        if isActive {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(authManager)
                .preferredColorScheme(.dark)
        } else {
            ZStack {
                Color(red: 0.039, green: 0.098, blue: 0.161) // hopeDarkBg
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Animated logo
                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.42, blue: 0.21).opacity(0.2))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.6, green: 0.4, blue: 1.0), // hopePurple
                                        Color(red: 1.0, green: 0.42, blue: 0.21) // hopeOrange
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Text("HopeSwap")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Share Hope, Build Community")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .onAppear {
                // Slight delay for splash screen
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isActive = true
                    }
                }
                
                // Load data in background
                Task {
                    await dataManager.loadData()
                }
            }
        }
    }
}

#Preview {
    SimpleLaunchView()
}