# Firestore Security Rules Update Required

## Important: Update Your Firebase Console

To ensure proper functionality of the app, you need to update your Firestore security rules in the Firebase Console.

### Steps to Update:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your HopeSwap project
3. Navigate to **Firestore Database** → **Rules**
4. Replace the existing rules with the content from `/firestore.rules`
5. Click **Publish**

### Why This is Required:

The updated rules allow:
- Any authenticated user to update analytics fields (clickCount, videoPlays, saveCount, shareCount)
- Proper ownership verification for item deletion
- Better security for user profiles and conversations
- **NEW: Messaging functionality between buyers and sellers**

### Key Changes:

1. **Analytics Updates**: Any authenticated user can increment/decrement analytics fields
2. **Document ID Flexibility**: The app now handles both old (auto-generated) and new (UUID-based) document IDs
3. **Deletion Security**: Ensures only item owners can delete their listings
4. **Messaging Support** (NEW):
   - Users can create conversations when they're participants (minimum 2 participants required)
   - Users can send messages in conversations they're part of
   - Messages can only be created by the sender
   - Only receivers can mark messages as read
   - Conversations and messages cannot be deleted for data integrity
   - Fixed permissions to properly allow conversation creation

Without these rules, analytics tracking, item deletion, and **messaging features will not work properly**.

**IMPORTANT**: After updating the rules in Firebase Console, it may take a few moments for the changes to propagate. If you still see permission errors, wait 30 seconds and try again.