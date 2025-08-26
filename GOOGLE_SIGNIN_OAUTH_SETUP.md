# Google Sign-In OAuth Configuration Guide

## Problem
Your `GoogleService-Info.plist` is missing the `REVERSED_CLIENT_ID` which is required for Google Sign-In to work properly.

## Current Configuration Status
- **Bundle ID**: `jimmylam.HopeSwap`
- **Project ID**: `hopeswap-62c55`
- **Google App ID**: `1:205596436080:ios:7b58865162884f9f87f6b5`
- **REVERSED_CLIENT_ID**: ❌ Missing (needs to be generated)

## Steps to Generate OAuth2 Client

### 1. Access Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **hopeswap-62c55**

### 2. Enable Google Sign-In Provider
1. Navigate to **Authentication** → **Sign-in method** tab
2. Click on **Google** provider
3. Toggle **Enable** switch
4. Configure:
   - **Project support email**: Select or enter your email
   - Click **Save**

### 3. Generate iOS OAuth Client
1. In Firebase Console, click the gear icon ⚙️ → **Project settings**
2. Scroll down to **Your apps** section
3. Find your iOS app (Bundle ID: `jimmylam.HopeSwap`)
4. If you don't see OAuth client configuration:
   - Click on the app configuration
   - Look for **OAuth 2.0 Client IDs** section
   - If empty, continue to step 4

### 4. Create OAuth Client in Google Cloud Console
1. Click the link to **Google Cloud Console** from Firebase settings
2. Or go directly to: https://console.cloud.google.com
3. Ensure your project **hopeswap-62c55** is selected
4. Navigate to **APIs & Services** → **Credentials**
5. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
6. Select:
   - **Application type**: iOS
   - **Name**: HopeSwap iOS Client
   - **Bundle ID**: `jimmylam.HopeSwap`
7. Click **Create**
8. Note down the **Client ID** (format: `XXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com`)

### 5. Download Updated GoogleService-Info.plist
1. Go back to Firebase Console
2. Project settings → Your iOS app
3. Click **Download GoogleService-Info.plist**
4. The new file should now contain:
   ```xml
   <key>CLIENT_ID</key>
   <string>[Your OAuth Client ID]</string>
   <key>REVERSED_CLIENT_ID</key>
   <string>com.googleusercontent.apps.[Your Client ID prefix]</string>
   ```

### 6. Replace the File in Xcode
1. Delete the old `GoogleService-Info.plist` from your Xcode project
2. Drag the new `GoogleService-Info.plist` into Xcode
3. Ensure:
   - ✅ Copy items if needed
   - ✅ Add to target: HopeSwap
   
### 7. Configure URL Scheme in Xcode
1. Select your project in Xcode navigator
2. Select the **HopeSwap** target
3. Go to **Info** tab
4. Expand **URL Types** section
5. Click **+** to add a new URL Type
6. Set:
   - **Identifier**: (leave blank or use `google-signin`)
   - **URL Schemes**: paste your `REVERSED_CLIENT_ID` value
   - **Role**: Editor

Example URL Scheme: `com.googleusercontent.apps.205596436080-[rest_of_client_id]`

## Verification Steps

After completing the setup:

1. **Check GoogleService-Info.plist contains**:
   ```xml
   <key>CLIENT_ID</key>
   <string>205596436080-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com</string>
   <key>REVERSED_CLIENT_ID</key>
   <string>com.googleusercontent.apps.205596436080-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX</string>
   ```

2. **Verify URL Scheme in Info.plist**:
   Build the project and check that Info.plist contains:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.googleusercontent.apps.205596436080-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX</string>
           </array>
       </dict>
   </array>
   ```

3. **Test Sign-In Flow**:
   - Run the app
   - Tap "Continue with Google"
   - Complete authentication
   - Verify user is signed in

## Alternative: Manual Configuration

If the Firebase Console doesn't generate the OAuth client automatically, you can manually add the keys to your existing plist:

1. After creating the OAuth client in Google Cloud Console
2. Edit your `GoogleService-Info.plist` and add:
   ```xml
   <key>CLIENT_ID</key>
   <string>[Your full OAuth Client ID]</string>
   <key>REVERSED_CLIENT_ID</key>
   <string>com.googleusercontent.apps.[Your Client ID prefix]</string>
   ```

## Common Issues

1. **"No OAuth client found" error**
   - Ensure Google provider is enabled in Firebase Authentication
   - Wait 5-10 minutes for changes to propagate

2. **"Invalid client ID" error**
   - Verify Bundle ID matches exactly: `jimmylam.HopeSwap`
   - Check for typos in the OAuth client configuration

3. **Sign-in popup doesn't appear**
   - Verify URL scheme is correctly added in Xcode
   - Clean build folder and rebuild

## Need Help?
If you encounter issues:
1. Check Firebase Authentication logs
2. Enable debug logging in your app
3. Verify all IDs match between Firebase, Google Cloud, and your app