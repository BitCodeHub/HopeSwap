import SwiftUI
import AuthenticationServices
import GoogleSignIn
import FirebaseCore

struct SignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var hasCompletedOnboarding: Bool
    @State private var showingError = false
    @State private var appleSignInCoordinator: SignInWithAppleCoordinator?
    @State private var isGoogleSignInLoading = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.hopeDarkBg, Color.hopeDarkBg.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Floating shapes for visual interest
            GeometryReader { geometry in
                Circle()
                    .fill(Color.hopePurple.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 40)
                    .offset(x: -100, y: -100)
                
                Circle()
                    .fill(Color.hopeOrange.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                    .offset(x: geometry.size.width - 50, y: geometry.size.height - 150)
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 20) {
                        // Animated logo
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.hopePurple, Color.hopeOrange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .blur(radius: 20)
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.hopePurple, Color.hopeOrange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(spacing: 8) {
                            Text("Welcome to HopeSwap")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Every exchange creates hope")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 60)
                    
                    // Social login buttons
                    VStack(spacing: 12) {
                        Button(action: handleGoogleSignIn) {
                            HStack(spacing: 12) {
                                if isGoogleSignInLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "globe")
                                        .font(.title3)
                                    Text("Continue with Google")
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .disabled(isGoogleSignInLoading || authManager.isLoading)
                        
                        Button(action: handleAppleSignIn) {
                            HStack(spacing: 12) {
                                Image(systemName: "apple.logo")
                                    .font(.title3)
                                Text("Continue with Apple")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Security notice
                    VStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.hopePurple, Color.hopeOrange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Sign in securely with your Google or Apple account")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Text("By signing in, you agree to support Hyundai Hope On Wheels' mission to end childhood cancer")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 30)
                    .padding(.horizontal, 24)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(authManager.errorMessage)
        }
        .onChange(of: authManager.errorMessage) { oldValue, newValue in
            showingError = !newValue.isEmpty
        }
    }
    
    private func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            authManager.errorMessage = "Could not find root view controller"
            return
        }
        
        Task { @MainActor in
            isGoogleSignInLoading = true
            
            do {
                // Configure Google Sign-In if needed
                guard let clientID = FirebaseApp.app()?.options.clientID else {
                    authManager.errorMessage = "Failed to get Google Sign-In client ID"
                    isGoogleSignInLoading = false
                    return
                }
                
                let config = GIDConfiguration(clientID: clientID)
                GIDSignIn.sharedInstance.configuration = config
                
                // Perform Google Sign-In
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
                
                // Get the user
                let user = result.user
                
                // Complete sign-in with Firebase
                try await authManager.completeGoogleSignIn(with: user)
                hasCompletedOnboarding = true
                
            } catch {
                // Handle cancellation separately
                if (error as NSError).code == -5 { // User cancelled
                    // Don't show error for cancellation
                    authManager.errorMessage = ""
                } else {
                    authManager.errorMessage = error.localizedDescription
                }
            }
            
            isGoogleSignInLoading = false
        }
    }
    
    private func handleAppleSignIn() {
        appleSignInCoordinator = authManager.handleAppleSignIn { success in
            if success {
                hasCompletedOnboarding = true
            }
        }
        appleSignInCoordinator?.signIn()
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .words
    var isSecure: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(isFocused ? Color.hopePurple : .gray)
                .frame(width: 20)
            
            if isSecure {
                SecureField("", text: $text)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .focused($isFocused)
            } else {
                TextField("", text: $text)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .keyboardType(keyboardType)
                    .autocapitalization(autocapitalization)
                    .focused($isFocused)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.hopeDarkSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? Color.hopePurple : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    SignInView(hasCompletedOnboarding: .constant(false))
        .environmentObject(AuthenticationManager.shared)
}