import Foundation
import FirebaseAuth
import Combine
import AuthenticationServices
import CryptoKit
import GoogleSignIn

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var user: FirebaseAuth.User?  // Explicitly use Firebase's User type
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    static let shared = AuthenticationManager()
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            Task { @MainActor in
                self?.user = user
                self?.isSignedIn = user != nil
            }
        }
    }
    
    func signUp(email: String, password: String, name: String = "") async throws {
        isLoading = true
        errorMessage = ""
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Update display name if provided
            if !name.isEmpty {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = name
                try await changeRequest.commitChanges()
            }
            
            // Create user profile in Firestore
            try await FirestoreManager.shared.createUserProfile(
                userId: result.user.uid, 
                email: email, 
                name: name
            )
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = ""
        
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        errorMessage = ""
    }
    
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    // MARK: - Helper Properties
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    var currentUserEmail: String? {
        return Auth.auth().currentUser?.email
    }
    
    var currentUserDisplayName: String? {
        return Auth.auth().currentUser?.displayName
    }
    
    // MARK: - Apple Sign In
    private var currentNonce: String?
    
    func handleAppleSignIn(completion: @escaping (Bool) -> Void) -> SignInWithAppleCoordinator {
        let coordinator = SignInWithAppleCoordinator()
        coordinator.signInCompletion = { [weak self] result, nonce in
            Task { @MainActor in
                switch result {
                case .success(let authorization):
                    await self?.handleAppleAuthorization(authorization, nonce: nonce)
                    completion(true)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
        return coordinator
    }
    
    private func handleAppleAuthorization(_ authorization: ASAuthorization, nonce: String) async {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            errorMessage = "Unable to process Apple Sign In"
            return
        }
        
        // Get full name from Apple credential
        var fullNameString: String? = nil
        if let fullName = appleIDCredential.fullName {
            let nameComponents = [fullName.givenName, fullName.familyName].compactMap { $0 }
            if !nameComponents.isEmpty {
                fullNameString = nameComponents.joined(separator: " ")
            }
        }
        
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        
        do {
            let result = try await Auth.auth().signIn(with: credential)
            
            let email = appleIDCredential.email ?? result.user.email ?? ""
            let displayName = fullNameString ?? result.user.displayName ?? "Apple User"
            
            // Create user profile
            try await FirestoreManager.shared.createUserProfile(
                userId: result.user.uid,
                email: email,
                name: displayName
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        isLoading = true
        errorMessage = ""
        
        do {
            // Create Firebase credential with Google tokens
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            // Sign in to Firebase
            let result = try await Auth.auth().signIn(with: credential)
            
            // Extract user info
            let email = result.user.email ?? ""
            let displayName = result.user.displayName ?? "Google User"
            let photoURL = result.user.photoURL
            
            // Create or update user profile in Firestore
            try await FirestoreManager.shared.createUserProfile(
                userId: result.user.uid,
                email: email,
                name: displayName
            )
            
            // Update profile with photo URL if available
            if let photoURL = photoURL {
                try await FirestoreManager.shared.updateUserProfile(
                    userId: result.user.uid,
                    data: ["avatar": photoURL.absoluteString]
                )
            }
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // Helper method to handle Google Sign-In completion
    func completeGoogleSignIn(with user: GIDGoogleUser) async throws {
        guard let idToken = user.idToken?.tokenString else {
            throw AuthError.missingGoogleTokens
        }
        
        let accessToken = user.accessToken.tokenString
        
        try await signInWithGoogle(idToken: idToken, accessToken: accessToken)
    }
    
    // Custom error for Google Sign-In
    enum AuthError: LocalizedError {
        case missingGoogleTokens
        
        var errorDescription: String? {
            switch self {
            case .missingGoogleTokens:
                return "Failed to retrieve Google authentication tokens"
            }
        }
    }
}