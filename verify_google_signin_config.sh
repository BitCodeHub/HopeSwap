#!/bin/bash

# Script to verify Google Sign-In configuration

echo "🔍 Verifying Google Sign-In Configuration for HopeSwap"
echo "=================================================="

# Check if GoogleService-Info.plist exists
PLIST_PATH="HopeSwap/GoogleService-Info.plist"

if [ ! -f "$PLIST_PATH" ]; then
    echo "❌ GoogleService-Info.plist not found at $PLIST_PATH"
    exit 1
fi

echo "✅ GoogleService-Info.plist found"

# Function to read plist value
read_plist_value() {
    /usr/libexec/PlistBuddy -c "Print :$1" "$PLIST_PATH" 2>/dev/null
}

# Check required fields
echo ""
echo "📋 Checking configuration values:"
echo "---------------------------------"

BUNDLE_ID=$(read_plist_value "BUNDLE_ID")
echo "Bundle ID: $BUNDLE_ID"

PROJECT_ID=$(read_plist_value "PROJECT_ID")
echo "Project ID: $PROJECT_ID"

CLIENT_ID=$(read_plist_value "CLIENT_ID")
if [ -z "$CLIENT_ID" ]; then
    echo "❌ CLIENT_ID: Missing - OAuth client not configured"
else
    echo "✅ CLIENT_ID: $CLIENT_ID"
fi

REVERSED_CLIENT_ID=$(read_plist_value "REVERSED_CLIENT_ID")
if [ -z "$REVERSED_CLIENT_ID" ]; then
    echo "❌ REVERSED_CLIENT_ID: Missing - Required for Google Sign-In"
else
    echo "✅ REVERSED_CLIENT_ID: $REVERSED_CLIENT_ID"
fi

IS_SIGNIN_ENABLED=$(read_plist_value "IS_SIGNIN_ENABLED")
echo "Sign-In Enabled: $IS_SIGNIN_ENABLED"

# Check if URL scheme is likely configured
echo ""
echo "📱 Next Steps:"
echo "--------------"

if [ -z "$REVERSED_CLIENT_ID" ]; then
    echo "1. Follow the steps in GOOGLE_SIGNIN_OAUTH_SETUP.md to generate OAuth client"
    echo "2. Download the updated GoogleService-Info.plist from Firebase Console"
    echo "3. Replace the current plist file in Xcode"
    echo "4. Add URL scheme to your app: [REVERSED_CLIENT_ID value]"
else
    echo "1. Ensure URL scheme is added in Xcode:"
    echo "   - Target → Info → URL Types"
    echo "   - URL Schemes: $REVERSED_CLIENT_ID"
    echo "2. Test Google Sign-In functionality"
fi

echo ""
echo "🔗 Useful Links:"
echo "- Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID"
echo "- Google Cloud Console: https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"