import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.hopeDarkBg
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color.hopeOrange)
                
                Text("HopeSwap")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.hopeOrange))
                    .scaleEffect(1.5)
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}