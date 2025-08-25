# Firebase Package Setup Guide

## Current Status
✅ **Already Added:**
- FirebaseAnalytics
- FirebaseAnalyticsCore
- FirebaseAnalyticsIdentitySupport
- FirebaseAuth
- FirebaseFirestore
- FirebaseMessaging

❌ **Missing (Need to Add):**
- **FirebaseStorage** (Required for image uploads)

## How to Add FirebaseStorage

### Method 1: Through Xcode UI
1. Open `HopeSwap.xcodeproj` in Xcode
2. Click on the project name in the navigator
3. Select the "HopeSwap" project (not target)
4. Go to "Package Dependencies" tab
5. Find "firebase-ios-sdk" in the list
6. Click the disclosure arrow to see all products
7. Click the "+" button
8. Select "FirebaseStorage"
9. Click "Add Package"

### Method 2: Through Package.swift (if using SPM)
Add to your package dependencies:
```swift
.product(name: "FirebaseStorage", package: "firebase-ios-sdk")
```

## After Adding FirebaseStorage

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Resolve Packages**: File → Packages → Resolve Package Versions
3. **Build Project**: ⌘B

## Uncomment Code
After successfully adding FirebaseStorage, uncomment the Firebase code in:
- `/ViewModels/StorageManager.swift`

Replace the TODO comments with the actual Firebase code.

## Verify Installation
Build the project. If successful, you should see no "No such module" errors.

## Troubleshooting

### If FirebaseStorage doesn't appear:
1. Remove the Firebase package completely
2. Re-add it with all required products
3. Make sure you're using the latest Firebase SDK version (12.0.0+)

### If still having issues:
1. Close Xcode
2. Delete `DerivedData`:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Reopen Xcode and try again