import SwiftUI

struct SecurityTestView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var firestoreManager = FirestoreManager.shared
    @State private var testResults = ""
    @State private var isRunningTests = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hopeDarkBg
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "shield.checkerboard")
                                .font(.system(size: 60))
                                .foregroundColor(Color.hopeGreen)
                            
                            Text("Security Rules Test")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Test your Firestore security rules")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 40)
                        
                        // Current user status
                        VStack(alignment: .leading, spacing: 8) {
                            Label(authManager.isSignedIn ? "Signed In" : "Not Signed In", 
                                  systemImage: authManager.isSignedIn ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(authManager.isSignedIn ? Color.hopeGreen : Color.red)
                                .font(.headline)
                            
                            if authManager.isSignedIn, let email = authManager.user?.email {
                                Text("Email: \(email)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.hopeDarkSecondary)
                        )
                        
                        // Run tests button
                        Button(action: runTests) {
                            HStack {
                                if isRunningTests {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color.hopeDarkBg))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "play.circle.fill")
                                }
                                Text(isRunningTests ? "Running Tests..." : "Run Security Tests")
                            }
                            .font(.headline)
                            .foregroundColor(Color.hopeDarkBg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeGreen)
                            )
                        }
                        .disabled(isRunningTests)
                        
                        // Test results
                        if !testResults.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Test Results", systemImage: "doc.text")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(testResults)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.black.opacity(0.3))
                                    )
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                        }
                        
                        // Sign in prompt if needed
                        if !authManager.isSignedIn {
                            VStack(spacing: 12) {
                                Text("Sign in to test authenticated operations")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Button(action: { /* Navigate to sign in */ }) {
                                    Text("Sign In")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.hopePurple)
                                        )
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hopeDarkSecondary)
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func runTests() {
        isRunningTests = true
        testResults = ""
        
        Task {
            // Capture console output
            let outputPipe = Pipe()
            let originalStdout = dup(STDOUT_FILENO)
            dup2(outputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
            
            // Run tests
            await firestoreManager.testSecurityRules()
            
            // Restore stdout
            fflush(stdout)
            dup2(originalStdout, STDOUT_FILENO)
            close(originalStdout)
            
            // Read captured output
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                await MainActor.run {
                    testResults = output
                    isRunningTests = false
                }
            } else {
                // If capturing fails, just show a simple message
                await MainActor.run {
                    testResults = "Tests completed. Check Xcode console for details."
                    isRunningTests = false
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    SecurityTestView()
        .environmentObject(AuthenticationManager.shared)
}
#endif