# Google Sign-In Setup Guide for HopeSwap

This guide will help you set up Google Sign-In functionality in the HopeSwap app.

## Prerequisites

- Firebase project configured with GoogleService-Info.plist
- Xcode 14.0 or later
- iOS 14.0 or later deployment target

## Step 1: Install Google Sign-In SDK

Add the Google Sign-In SDK to your project using Swift Package Manager:

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter the following URL: `https://github.com/google/GoogleSignIn-iOS`
3. Choose the latest version (currently 7.0.0 or later)
4. Select the following packages:
   - GoogleSignIn
   - GoogleSignInSwift (optional, for SwiftUI helpers)
5. Click **Add Package**

## Step 2: Configure Your Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com)
2. Select your HopeSwap project
3. Navigate to **Authentication** → **Sign-in method**
4. Enable **Google** as a sign-in provider
5. Configure the following:
   - **Web client ID**: This will be auto-generated
   - **Web client secret**: This will be auto-generated
   - **Whitelist client IDs from external projects**: Leave empty unless needed

## Step 3: Configure URL Schemes

1. In Xcode, select your project in the navigator
2. Select your app target
3. Go to the **Info** tab
4. Expand **URL Types**
5. Click the **+** button to add a new URL type
6. Configure the URL scheme:
   - **Identifier**: Leave blank or set to `com.googleusercontent.apps`
   - **URL Schemes**: Add your REVERSED_CLIENT_ID from GoogleService-Info.plist
   
   To find your REVERSED_CLIENT_ID:
   - Open GoogleService-Info.plist
   - Look for the `REVERSED_CLIENT_ID` key
   - Copy its value (it should look like: `com.googleusercontent.apps.YOUR_CLIENT_ID`)
   - Paste this value into the URL Schemes field

## Step 4: Update Info.plist (if needed)

Add the following to your Info.plist if you encounter any issues:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

Replace `YOUR_REVERSED_CLIENT_ID` with the actual value from GoogleService-Info.plist.

## Step 5: Test Google Sign-In

1. Build and run the app on a physical device or simulator
2. Navigate to the sign-in screen
3. Tap "Continue with Google"
4. Complete the Google sign-in flow
5. Verify that:
   - The user is successfully authenticated
   - User data is saved to Firestore
   - The app navigates to the home screen

## Implementation Details

The Google Sign-In implementation includes:

### AuthenticationManager.swift
- `signInWithGoogle(idToken:accessToken:)` - Handles Firebase authentication with Google credentials
- `completeGoogleSignIn(with:)` - Helper method to process Google Sign-In user data
- `AuthError` enum - Custom error handling for Google Sign-In

### SignInView.swift
- `handleGoogleSignIn()` - Manages the Google Sign-In flow UI
- Configures GIDSignIn with Firebase client ID
- Handles sign-in presentation and error states

### HopeSwapApp.swift
- `onOpenURL` modifier - Handles Google Sign-In callback URLs

## Troubleshooting

### Common Issues

1. **"Could not find root view controller" error**
   - Ensure your app has a proper window scene setup
   - This typically happens in SwiftUI apps without proper UIKit bridge

2. **"Failed to get Google Sign-In client ID" error**
   - Verify GoogleService-Info.plist is added to your project
   - Ensure Firebase is initialized before attempting sign-in

3. **Sign-in flow doesn't appear**
   - Check that URL schemes are properly configured
   - Verify Google Sign-In is enabled in Firebase Console

4. **User cancellation handling**
   - The app properly handles when users cancel the sign-in flow
   - Error code -5 indicates user cancellation

### Debug Tips

1. Enable verbose logging for Google Sign-In:
   ```swift
   GIDSignIn.sharedInstance.configuration?.showDebugLogs = true
   ```

2. Verify your bundle ID matches Firebase configuration
3. Test on a real device for the most accurate behavior
4. Check Firebase Authentication dashboard for sign-in attempts

## Security Best Practices

1. Never expose your Google OAuth client secret in your app
2. Use Firebase Security Rules to protect user data
3. Implement proper error handling for all authentication states
4. Consider implementing account linking for users with multiple sign-in methods

## Additional Resources

- [Google Sign-In iOS Documentation](https://developers.google.com/identity/sign-in/ios)
- [Firebase Auth Documentation](https://firebase.google.com/docs/auth/ios/google-signin)
- [GoogleSignIn-iOS GitHub Repository](https://github.com/google/GoogleSignIn-iOS)