import Foundation
import FirebaseAuth
import Combine

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
}