import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var showingSignIn = false
    
    var body: some View {
        ZStack {
            Color.hopeDarkBg
                .ignoresSafeArea()
            
            VStack {
                if currentPage < onboardingPages.count {
                    TabView(selection: $currentPage) {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            OnboardingPageView(page: onboardingPages[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentPage)
                    
                    // Custom page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.hopePurple : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Navigation buttons
                    HStack {
                        if currentPage > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }
                            .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if currentPage < onboardingPages.count - 1 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                showingSignIn = true
                            }
                        }) {
                            Text(currentPage == onboardingPages.count - 1 ? "Get Started" : "Next")
                                .font(.headline)
                                .foregroundColor(Color.hopeDarkBg)
                                .frame(width: 120, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(currentPage == onboardingPages.count - 1 ? Color.hopePurple : Color.hopeOrange)
                                )
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
        }
        .fullScreenCover(isPresented: $showingSignIn) {
            SignInView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environmentObject(AuthenticationManager.shared)
        }
    }
}

struct OnboardingPage {
    let imageName: String
    let title: String
    let subtitle: String
    let description: String
    let isSystemImage: Bool
    let imageColor: Color
    let highlightedText: String?
}

let onboardingPages = [
    OnboardingPage(
        imageName: "heart.hands.fill",
        title: "Welcome to HopeSwap",
        subtitle: "Share Hope, Build Community",
        description: "A marketplace where every transaction creates positive change. Buy, sell, trade, and donate within your community while supporting a great cause.",
        isSystemImage: true,
        imageColor: Color.hopePurple,
        highlightedText: nil
    ),
    OnboardingPage(
        imageName: "star.fill",
        title: "Powered by Hope",
        subtitle: "In Partnership with Hyundai Hope On Wheels",
        description: "We're proud to partner with Hyundai Hope On Wheels in their mission to end childhood cancer. Together, we're turning everyday exchanges into hope for children.",
        isSystemImage: true,
        imageColor: Color.yellow,
        highlightedText: "Hyundai Hope On Wheels"
    ),
    OnboardingPage(
        imageName: "gift.fill",
        title: "100% Goes to Research",
        subtitle: "Every Listing Fee Makes a Difference",
        description: "100% of all listing fees are donated directly to Pediatric Cancer Research. Your small contribution helps fund breakthrough treatments and give hope to families.",
        isSystemImage: true,
        imageColor: Color.hopeOrange,
        highlightedText: "100% of all listing fees"
    ),
    OnboardingPage(
        imageName: "person.3.fill",
        title: "More Than a Marketplace",
        subtitle: "Connect, Share, and Care",
        description: "Find workout buddies, carpool partners, organize community events, or simply give away items to neighbors in need. Every interaction builds stronger communities.",
        isSystemImage: true,
        imageColor: Color.mint,
        highlightedText: nil
    )
]

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon with animation
            ZStack {
                Circle()
                    .fill(page.imageColor.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                
                Circle()
                    .fill(page.imageColor.opacity(0.05))
                    .frame(width: 250, height: 250)
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
                
                Image(systemName: page.imageName)
                    .font(.system(size: 80))
                    .foregroundColor(page.imageColor)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
            }
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundColor(page.imageColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let highlightedText = page.highlightedText {
                    Text(page.description)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                        .highlightedText(highlightedText, color: page.imageColor)
                } else {
                    Text(page.description)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
            }
            
            Spacer()
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// Extension to highlight specific text
extension View {
    func highlightedText(_ text: String, color: Color) -> some View {
        self.modifier(HighlightedTextModifier(highlightedText: text, color: color))
    }
}

struct HighlightedTextModifier: ViewModifier {
    let highlightedText: String
    let color: Color
    
    func body(content: Content) -> some View {
        if let textView = content as? Text {
            return AnyView(textView)
        } else {
            return AnyView(content)
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}