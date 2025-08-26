import SwiftUI

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// Extension for attributed text with highlighting
extension Text {
    func highlightText(_ searchText: String, highlightColor: Color) -> Text {
        guard !searchText.isEmpty else { return self }
        
        // This is a simplified version - in production, 
        // you'd want to handle the full attributed string conversion
        return self
    }
}

// Extension for animated appearance
extension View {
    func animateOnAppear(delay: Double = 0) -> some View {
        self.modifier(AppearanceAnimationModifier(delay: delay))
    }
}

struct AppearanceAnimationModifier: ViewModifier {
    @State private var isVisible = false
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.95)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3).delay(delay)) {
                    isVisible = true
                }
            }
    }
}