import SwiftUI

struct TestView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                Text("Test View")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("App is loading")
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    TestView()
}