# FitFam iOS App - Project Structure

## 🏗️ Overview
FitFam is a social fitness iOS app built with SwiftUI and Firebase. Users can track workouts, share achievements, and connect with a fitness community through posts, comments, and encouragement.

## 📁 Directory Structure

```
FitFam/
├── FitFam/                          # Main app target
│   ├── FitFamApp.swift             # App entry point
│   ├── ContentView.swift           # Root navigation coordinator
│   ├── Info.plist                  # App configuration
│   │
│   ├── Models/                     # Data models
│   │   ├── User.swift              # User profile & fitness data
│   │   ├── Post.swift              # Social posts & workout data
│   │   ├── Comment.swift           # Post comments
│   │   ├── Cheer.swift             # Post reactions/likes
│   │   ├── FriendGroup.swift       # Group functionality
│   │   ├── Streak.swift            # Workout streaks
│   │   └── WorkoutCheckIn.swift    # Location check-ins
│   │
│   ├── ViewModels/                 # Business logic & state management
│   │   ├── AuthViewModel.swift     # Authentication & user session
│   │   └── FeedViewModel.swift     # Social feed management
│   │
│   ├── Views/                      # SwiftUI views organized by feature
│   │   ├── Authentication/         # Login & registration
│   │   │   ├── AuthenticationView.swift
│   │   │   └── OnboardingView.swift
│   │   │
│   │   ├── Feed/                   # Social feed & discovery
│   │   │   ├── HomeFeedView.swift  # Main social feed
│   │   │   └── ActivityMapView.swift # Location-based workouts
│   │   │
│   │   ├── Workout/                # Fitness tracking
│   │   │   ├── PostWorkoutView.swift # Create workout posts
│   │   │   └── StatsView.swift     # Personal analytics
│   │   │
│   │   ├── Profile/                # User management
│   │   │   ├── ProfileView.swift   # User profile display
│   │   │   ├── DetailedProfileView.swift # Full profile editor
│   │   │   └── SettingsView.swift  # App settings
│   │   │
│   │   ├── Social/                 # Community features
│   │   │   └── ContactsView.swift  # Friend management
│   │   │
│   │   ├── Components/             # Reusable UI components
│   │   │   ├── PostCardView.swift  # Individual post display
│   │   │   ├── CommentsView.swift  # Post comments interface
│   │   │   └── LocationMapView.swift # Location details
│   │   │
│   │   └── Core/                   # Core app views
│   │       └── WorkoutStatusView.swift # Initial workout prompt
│   │
│   ├── Services/                   # External integrations
│   │   ├── AuthService.swift       # Firebase Authentication
│   │   └── FirebaseService.swift   # Firestore operations
│   │
│   ├── Resources/                  # Configuration & assets
│   │   └── AppConfiguration.swift  # App constants
│   │
│   └── Assets.xcassets/            # Images, colors, icons
│
├── FitFamTests/                    # Unit tests
├── FitFamUITests/                  # UI automation tests
└── README.md                       # Project documentation
```

## 🎯 Key Features

### 🏠 Home Feed (`Views/Feed/`)
- **HomeFeedView**: Main social feed with real-time updates
- **ActivityMapView**: Map showing workout locations
- Real-time Firebase synchronization
- Pull-to-refresh and infinite scrolling
- Social engagement (cheers, comments, shares)

### 💪 Workout Tracking (`Views/Workout/`)
- **PostWorkoutView**: Create and share workout posts
- **StatsView**: Personal analytics and achievement tracking
- Activity type selection and workout metrics
- Progress visualization and streak tracking

### 👤 Profile Management (`Views/Profile/`)
- **ProfileView**: User profile with fitness stats
- **DetailedProfileView**: Full profile editing
- **SettingsView**: Privacy controls and app preferences
- Achievement showcases and workout history

### 🤝 Social Features (`Views/Social/`)
- **ContactsView**: Find and add fitness friends
- Friend management and connection system
- Community engagement and motivation

### 🧩 Reusable Components (`Views/Components/`)
- **PostCardView**: Beautiful post cards with workout details
- **CommentsView**: Interactive comment system
- **LocationMapView**: Workout location details with maps

## 🔥 Firebase Integration

### Firestore Collections
```
users/              # User profiles and settings
├── {userID}
    ├── firebaseUID: String
    ├── username: String
    ├── displayName: String
    ├── currentStreak: Int
    └── totalWorkouts: Int

posts/              # Social workout posts
├── {postID}
    ├── userID: String
    ├── postType: enum
    ├── workoutData: Object
    ├── location: Object
    ├── timestamp: Date
    └── cheerCount: Int

comments/           # Post comments
├── {commentID}
    ├── postID: String
    ├── userID: String
    ├── content: String
    └── timestamp: Date

cheers/            # Post reactions
├── {cheerID}
    ├── postID: String
    ├── userID: String
    └── timestamp: Date
```

## 🛠️ Architecture Patterns

### MVVM (Model-View-ViewModel)
- **Models**: Data structures matching Firebase documents
- **Views**: SwiftUI declarative UI components
- **ViewModels**: Business logic and state management with `@ObservableObject`

### Key Design Decisions
- **Real-time Updates**: Firebase listeners for live social feed
- **Offline Support**: Mock data fallbacks for development
- **Performance**: LazyVStack for efficient scrolling
- **State Management**: Combine framework with SwiftUI
- **Security**: Firebase Security Rules (not in this repo)

## 🎨 UI/UX Features

### Design System
- **Cards**: Elevated cards with shadows for content
- **Colors**: Dynamic color system with dark mode support
- **Typography**: Clear hierarchy with SF Symbols
- **Animations**: Smooth transitions and micro-interactions

### Accessibility
- VoiceOver support with semantic labels
- Dynamic Type for text scaling
- High contrast mode compatibility
- Reduced motion preferences

## 🚀 Getting Started

### Prerequisites
1. Xcode 15.0+
2. iOS 15.0+ target
3. Firebase project setup
4. CocoaPods or Swift Package Manager

### Setup Steps
1. Clone the repository
2. Open `FitFam.xcodeproj` in Xcode
3. Add your `GoogleService-Info.plist` to the project
4. Build and run on simulator or device

### Development Tips
- Use mock data for offline development
- Firebase Emulator Suite for local testing
- SwiftUI Previews for rapid UI iteration
- Instruments for performance profiling

## 🔐 Security Considerations

### Data Protection
- Firebase Authentication for secure user sessions
- Firestore Security Rules restrict data access
- No sensitive data stored locally
- Privacy controls for location sharing

### Best Practices
- Input validation on all user data
- Image upload size limits
- Rate limiting for API calls
- Secure token handling

## 📱 Platform Support

- **iOS**: 15.0+
- **Devices**: iPhone (optimized), iPad (compatible)
- **Features**: Location services, camera access, push notifications
- **Accessibility**: Full VoiceOver support

---

*Last updated: August 10, 2025*
*Project maintained by: FitFam Development Team*