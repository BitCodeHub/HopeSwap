# HopeSwap Backend Setup Guide

## Option 1: Firebase (Recommended)

### 1. Setup Firebase Project
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and initialize
firebase login
firebase init
```

### 2. Required Firebase Services
- **Authentication**: Email/password, Google, Apple Sign-In
- **Firestore Database**: Store items, users, messages
- **Cloud Storage**: Item images, user avatars
- **Cloud Functions**: Business logic, notifications
- **Hosting**: Optional web admin panel

### 3. iOS Integration
Add to your Xcode project:
```swift
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
```

### 4. Database Structure
```
users/
  {userId}/
    - name, email, location, avatar
    - createdAt, lastActive

items/
  {itemId}/
    - title, description, price
    - category, condition, images[]
    - location, userId, createdAt
    - listingType (sell/trade/giveaway)

messages/
  {conversationId}/
    messages/
      {messageId}/
        - text, userId, timestamp, read

notifications/
  {userId}/
    {notificationId}/
      - type, title, body, read, timestamp
```

### 5. Deployment Commands
```bash
# Deploy functions
firebase deploy --only functions

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy storage rules  
firebase deploy --only storage

# Deploy everything
firebase deploy
```

## Option 2: AWS Amplify

### 1. Setup
```bash
npm install -g @aws-amplify/cli
amplify configure
amplify init
```

### 2. Add Services
```bash
amplify add auth      # Cognito authentication
amplify add api       # AppSync GraphQL API
amplify add storage   # S3 file storage
amplify add function  # Lambda functions
```

### 3. Deploy
```bash
amplify push
```

## Option 3: Supabase

### 1. Create Project
- Go to supabase.com
- Create new project
- Get API URL and anon key

### 2. iOS Integration
```swift
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
    supabaseKey: "YOUR_SUPABASE_ANON_KEY"
)
```

## Recommended Choice: Firebase

**Pros**:
- Easiest iOS integration
- Real-time updates perfect for marketplace
- Excellent documentation
- Built-in authentication with Apple/Google
- Automatic scaling
- Great for MVP and production

**Setup Steps**:
1. Create Firebase project at console.firebase.google.com
2. Add iOS app with your bundle identifier
3. Download GoogleService-Info.plist to Xcode
4. Install Firebase SDK via CocoaPods or Swift Package Manager
5. Configure services (Auth, Firestore, Storage)
6. Deploy security rules and cloud functions

**Monthly Cost Estimate**:
- Under 1K users: $0-25/month
- 1K-10K users: $25-100/month
- 10K+ users: $100+/month

Firebase is the best choice for HopeSwap due to its real-time capabilities, iOS integration, and marketplace-friendly features.