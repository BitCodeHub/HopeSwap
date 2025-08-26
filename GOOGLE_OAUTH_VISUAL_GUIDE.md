# Google Cloud Console OAuth Client Setup - Visual Guide

## Step-by-Step Instructions

### 1. Access Google Cloud Console
- Go to: https://console.cloud.google.com
- Make sure your project **hopeswap-62c55** is selected in the top dropdown

### 2. Navigate to APIs & Services → Credentials

From the left sidebar menu:
```
☰ Navigation menu
  └─ APIs & Services
      └─ Credentials
```

Or use direct link: https://console.cloud.google.com/apis/credentials

### 3. Create OAuth Client ID

Once on the Credentials page:

1. **Click the "+ CREATE CREDENTIALS" button** (usually blue, at the top)
   
2. **Select "OAuth client ID"** from the dropdown menu

3. **Configure the OAuth client:**
   ```
   Application type: iOS
   
   Name: HopeSwap iOS Client
   
   Bundle ID: jimmylam.HopeSwap
   ```

4. **Click "CREATE" button**

### 4. Copy Your Client ID

After creation, you'll see:
- **Client ID**: `205596436080-41sd4drhac46imv29e0b902g56kltrbk.apps.googleusercontent.com`
- This matches what's in your URL scheme!

### 5. Important Notes

- The Client ID format is: `[PROJECT_NUMBER]-[UNIQUE_ID].apps.googleusercontent.com`
- Your PROJECT_NUMBER is: 205596436080
- The REVERSED_CLIENT_ID flips this: `com.googleusercontent.apps.205596436080-[UNIQUE_ID]`

### 6. Verify in Firebase

After creating in Google Cloud Console:
1. Go back to Firebase Console
2. Project Settings → Your apps → iOS app
3. You should now see the OAuth client listed
4. Download the updated GoogleService-Info.plist

## What Each Screen Looks Like

### APIs & Services Dashboard
- Shows enabled APIs
- Has "Credentials" in left sidebar
- "+ CREATE CREDENTIALS" button at top

### OAuth Client ID Creation Form
- Dropdown for "Application type" → Select "iOS"
- Text field for "Name" → Enter descriptive name
- Text field for "Bundle ID" → Must match exactly: `jimmylam.HopeSwap`
- "CREATE" button at bottom

### After Creation
- Shows your Client ID
- Can download or copy the configuration
- Lists all OAuth clients for your project

## Troubleshooting

If you don't see the option to create OAuth client:
1. Make sure you're in the correct project
2. Check if APIs are enabled (especially Google Sign-In API)
3. Verify you have proper permissions in the project

## Next Steps

Once created:
1. ✅ Your Xcode URL scheme is already configured correctly
2. ✅ Download updated GoogleService-Info.plist from Firebase
3. ✅ Replace the file in your Xcode project
4. ✅ Test Google Sign-In!