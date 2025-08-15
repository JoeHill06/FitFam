# Firebase Security Rules Proposal

## Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - users can read public profiles, write only their own
    match /users/{userId} {
      allow read: if true; // Public profiles for social features
      allow write: if request.auth != null 
                   && request.auth.uid == userId
                   && validateUserData(request.resource.data);
    }
    
    // Posts collection - users can create their own posts, read public posts
    match /posts/{postId} {
      allow read: if true; // Public posts for social feed
      allow create: if request.auth != null 
                    && request.auth.uid == request.resource.data.userID
                    && validatePostData(request.resource.data);
      allow update: if request.auth != null 
                    && request.auth.uid == resource.data.userID;
      allow delete: if request.auth != null 
                    && request.auth.uid == resource.data.userID;
    }
    
    // Streaks collection - users can read/write only their own streaks
    match /streaks/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Validation functions
    function validateUserData(data) {
      return data.keys().hasAll(['firebaseUID', 'email', 'username', 'displayName']) &&
             data.firebaseUID is string &&
             data.email is string &&
             data.username is string &&
             data.displayName is string &&
             data.username.size() <= 50 &&
             data.displayName.size() <= 100;
    }
    
    function validatePostData(data) {
      return data.keys().hasAll(['userID', 'username', 'postType', 'timestamp']) &&
             data.userID is string &&
             data.username is string &&
             data.postType in ['workout', 'achievement', 'checkIn', 'progress', 'motivation', 'challenge'] &&
             data.timestamp is timestamp &&
             (data.content == null || (data.content is string && data.content.size() <= 280)) &&
             (data.backImageUrl == null || data.backImageUrl is string) &&
             (data.frontImageUrl == null || data.frontImageUrl is string);
    }
  }
}
```

## Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Post images: posts/{postId}/back.jpg and posts/{postId}/front.jpg
    match /posts/{postId}/{imageFile} {
      allow read: if true; // Public images for social feed
      allow write: if request.auth != null
                   && imageFile in ['back.jpg', 'front.jpg']
                   && request.resource.size < 5 * 1024 * 1024  // 5MB limit
                   && request.resource.contentType.matches('image/jpeg')
                   && postBelongsToUser(postId, request.auth.uid);
    }
    
    // User avatars
    match /users/{userId}/avatar.jpg {
      allow read: if true; // Public avatars
      allow write: if request.auth != null
                   && request.auth.uid == userId
                   && request.resource.size < 2 * 1024 * 1024  // 2MB limit
                   && request.resource.contentType.matches('image/jpeg');
    }
    
    // Helper function to check if post belongs to user
    function postBelongsToUser(postId, userId) {
      return exists(/databases/(default)/documents/posts/$(postId)) &&
             get(/databases/(default)/documents/posts/$(postId)).data.userID == userId;
    }
  }
}
```

## Manual Setup Required

### Step 1: Update Firestore Rules
1. Go to Firebase Console → Firestore Database → Rules
2. Replace the existing rules with the Firestore rules above
3. Click "Publish"

### Step 2: Update Storage Rules  
1. Go to Firebase Console → Storage → Rules
2. Replace the existing rules with the Storage rules above
3. Click "Publish"

### Step 3: Enable Required Features (if not already enabled)
1. Go to Firebase Console → Authentication → Sign-in method
2. Ensure Email/Password provider is enabled
3. Go to Firestore Database → Data
4. Verify collections exist: `users`, `posts`, `streaks`

## Security Features

✅ **Authentication Required**: All writes require authenticated users  
✅ **User Isolation**: Users can only modify their own data  
✅ **Data Validation**: Required fields and size limits enforced  
✅ **File Size Limits**: Images limited to 5MB for posts, 2MB for avatars  
✅ **MIME Type Validation**: Only JPEG images allowed  
✅ **Ownership Verification**: Storage writes require matching Firestore post ownership  

## Feature Flag Recommendation

Consider adding a feature flag to your app to control posting functionality:

```swift
struct FeatureFlags {
    static let enablePosting = true // Set to false to disable posting
}
```

Then in PostComposerView, check the flag before allowing posts.