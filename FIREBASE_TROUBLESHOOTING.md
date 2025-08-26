# Firebase Troubleshooting Guide

## 🔍 Issue: Items Not Saving to Firebase

### What I've Fixed:
1. ✅ Added `userId` field to Item's `toDictionary()` method
2. ✅ Fixed userId parsing in `fromFirestore()` methods
3. ✅ Updated PostItemFlow to use authenticated user's ID
4. ✅ Added debug logging to track save operations
5. ✅ Set up real-time listener for automatic updates

### 🚨 Required Firebase Console Setup

#### 1. Enable Authentication Methods
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your HopeSwap project
3. Click **Authentication** → **Sign-in method**
4. Enable these providers:
   - ✅ **Email/Password** - Required for user accounts
   - ✅ **Anonymous** - Required for "Continue as Guest"

#### 2. Verify Firestore Security Rules
Go to **Firestore Database** → **Rules** and ensure you have:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /items/{item} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### 3. Check Firebase Storage Rules
Go to **Storage** → **Rules** and ensure you have:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /items/{itemId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## 🧪 Testing Steps

### 1. Run the App and Watch Console
When you post an item, you should see:
```
🔵 Adding new item: [Item Title]
🔵 User ID (UUID): [UUID]
🔵 Firebase Auth UID: [Firebase UID or "nil"]
🔵 Uploading X images...
🔵 Images uploaded successfully: [URLs]
🔵 Creating item in Firestore...
✅ Item created successfully with ID: [Document ID]
📥 Received X items from Firestore listener
✅ Local items array updated with X items
```

### 2. Check Firebase Console
1. Go to **Firestore Database** → **Data**
2. Look for the `items` collection
3. You should see your posted items with fields:
   - id (UUID string)
   - userId (Firebase Auth UID)
   - title, description, etc.
   - createdAt (timestamp)
   - images (array of URLs)

### 3. Common Issues & Solutions

#### ❌ "Firebase Auth UID: nil" in console
**Problem**: User not authenticated
**Solution**: 
- Make sure you signed in (email/password or guest)
- Check Authentication tab in Firebase Console for active users

#### ❌ "Error adding item: Missing or insufficient permissions"
**Problem**: Security rules blocking writes
**Solution**: 
- Verify security rules are correctly set (see above)
- Ensure authentication is enabled in Firebase Console

#### ❌ Items save but don't appear in app
**Problem**: Real-time listener not working
**Solution**: 
- Check console for "📥 Received X items" messages
- Verify Firestore has network connectivity
- Check if items have correct structure in Firebase Console

#### ❌ Images don't upload
**Problem**: Storage permissions or configuration
**Solution**: 
- Verify Storage rules (see above)
- Check Storage bucket is created in Firebase Console
- Ensure images aren't too large (> 10MB)

## 🔧 Debug Mode

To enable detailed Firebase logging, add to your launch arguments:
1. Edit Scheme → Run → Arguments
2. Add: `-FIRAnalyticsDebugEnabled`
3. Add: `-FIRDebugEnabled`

## 📱 Quick Test

1. Launch app
2. Tap "Continue as Guest" 
3. Tap the + button
4. Create a simple listing (no images first)
5. Complete the flow
6. Check:
   - Console output for success messages
   - Firebase Console for new item
   - App's Discover tab for the item

## 🆘 Still Not Working?

1. **Verify GoogleService-Info.plist**:
   - Ensure it's in your project
   - Bundle ID matches Firebase project

2. **Check Network**:
   - Firestore needs internet connection
   - Try on WiFi instead of cellular

3. **Clean Build**:
   - Delete app from device/simulator
   - Clean build folder (Shift+Cmd+K)
   - Rebuild and run

4. **Firebase Status**:
   - Check [Firebase Status](https://status.firebase.google.com)
   - Try a different region if issues persist