// Quick script to fix existing items without firebaseUserId
// Run this in Firebase Console → Firestore → Cloud Shell or locally with Admin SDK

// For Firebase Console (paste in browser console):
// 1. Go to Firestore Database
// 2. Open browser developer tools (F12)
// 3. Paste this code:

// Find your user ID from Authentication tab first
const YOUR_USER_ID = "YOUR_FIREBASE_AUTH_UID_HERE"; // Replace with your actual UID

// Get all items and update ones that match your sellerUsername
db.collection('items').get().then(snapshot => {
  snapshot.forEach(doc => {
    const data = doc.data();
    
    // If item doesn't have firebaseUserId but has your username
    if (!data.firebaseUserId && data.sellerUsername === "Your Name") {
      console.log(`Updating ${doc.id}: ${data.title}`);
      
      // Update the document
      doc.ref.update({
        firebaseUserId: YOUR_USER_ID
      }).then(() => {
        console.log(`✅ Updated ${data.title}`);
      }).catch(err => {
        console.error(`❌ Error updating ${doc.id}:`, err);
      });
    }
  });
});

// Alternative: Update ALL items without firebaseUserId (be careful!)
/*
db.collection('items').where('firebaseUserId', '==', '').get().then(snapshot => {
  console.log(`Found ${snapshot.size} items to fix`);
  // Uncomment to actually update:
  // snapshot.forEach(doc => {
  //   doc.ref.update({ firebaseUserId: YOUR_USER_ID });
  // });
});
*/