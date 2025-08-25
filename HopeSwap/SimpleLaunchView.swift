import SwiftUI

struct SimpleLaunchView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var isActive = false
    
    var body: some View {
        if isActive {
            ContentView()
                .environmentObject(dataManager)
                .preferredColorScheme(.dark)
        } else {
            ZStack {
                Color(red: 0.039, green: 0.098, blue: 0.161) // hopeDarkBg
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.21)) // hopeOrange
                    
                    Text("HopeSwap")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                // Transition immediately to avoid launch timeout
                withAnimation {
                    isActive = true
                }
                
                // Load data in background after UI is shown
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