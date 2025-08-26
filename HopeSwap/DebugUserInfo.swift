import SwiftUI
import FirebaseAuth

struct DebugUserInfo: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Debug User Info")
                .font(.headline)
            
            Group {
                Text("Firebase User:")
                if let user = Auth.auth().currentUser {
                    Text("UID: \(user.uid)")
                    Text("Email: \(user.email ?? "No email")")
                    Text("Display Name: \(user.displayName ?? "No display name")")
                    Text("Anonymous: \(user.isAnonymous ? "Yes" : "No")")
                } else {
                    Text("Not authenticated")
                }
            }
            .font(.caption)
            .foregroundColor(.gray)
            
            Divider()
            
            Group {
                Text("DataManager User:")
                Text("Username: \(dataManager.currentUser.username)")
                Text("Email: \(dataManager.currentUser.email)")
                Text("Profile Image: \(dataManager.currentUser.profileImageURL ?? "None")")
            }
            .font(.caption)
            .foregroundColor(.gray)
            
            Divider()
            
            Text("Items: \(dataManager.items.count) total")
            Text("User's Items: \(dataManager.getCurrentUserItems().count)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}