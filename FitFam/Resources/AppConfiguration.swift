import Foundation
import FirebaseCore

class AppConfiguration {
    static let shared = AppConfiguration()
    
    private init() {}
    
    func configure() {
        configureFirebase()
    }
    
    private func configureFirebase() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            print("⚠️ GoogleService-Info.plist not found. Please add your Firebase configuration file.")
            return
        }
        
        FirebaseApp.configure()
        print("✅ Firebase configured successfully")
    }
}

struct AppEnvironment {
    static let isProduction = Bundle.main.bundleIdentifier?.contains("release") ?? false
    static let isDebug = !isProduction
    
    static let maxImageSize: CGSize = CGSize(width: 1080, height: 1920)
    static let maxVideoLength: TimeInterval = 30.0
    static let compressionQuality: CGFloat = 0.8
    
    static let feedRefreshInterval: TimeInterval = 30.0
    static let streakResetHour = 4 // 4 AM reset time
    
    static let privacyPolicyURL = "https://fitfam.app/privacy"
    static let termsOfServiceURL = "https://fitfam.app/terms"
    static let supportEmail = "support@fitfam.app"
}