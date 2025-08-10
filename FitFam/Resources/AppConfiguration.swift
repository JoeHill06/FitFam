import Foundation
import FirebaseCore
import GoogleSignIn

class AppConfiguration {
    static let shared = AppConfiguration()
    
    private init() {}
    
    func configure() {
        configureFirebase()
    }
    
    private func configureFirebase() {
        // Try Google Sign-In specific config first, then fall back to regular config
        var plistPath: String?
        
        if let googleSignInPath = Bundle.main.path(forResource: "GoogleService-Info-Goggle-Sign-In", ofType: "plist") {
            plistPath = googleSignInPath
            print("🔍 Using GoogleService-Info-Google-Sign-In.plist")
        } else if let regularPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            plistPath = regularPath
            print("🔍 Using GoogleService-Info.plist")
        }
        
        guard let configPath = plistPath else {
            print("⚠️ No Firebase configuration file found. Running in demo mode.")
            print("📱 UI will work, but authentication will be disabled.")
            print("🔧 Add GoogleService-Info.plist or GoogleService-Info-Google-Sign-In.plist from Firebase Console to enable auth.")
            return
        }
        
        guard let options = FirebaseOptions(contentsOfFile: configPath) else {
            print("⚠️ Failed to load Firebase configuration from: \(configPath)")
            return
        }
        
        FirebaseApp.configure(options: options)
        print("✅ Firebase configured successfully with: \(URL(fileURLWithPath: configPath).lastPathComponent)")
        
        // Configure Google Sign In
        configureGoogleSignIn()
    }
    
    private func configureGoogleSignIn() {
        print("🔍 Looking for GoogleService-Info-Goggle-Sign-In.plist...")
        
        guard let path = Bundle.main.path(forResource: "GoogleService-Info-Goggle-Sign-In", ofType: "plist") else {
            print("❌ GoogleService-Info-Goggle-Sign-In.plist file not found in bundle")
            return
        }
        
        print("✅ Found plist file at: \(path)")
        
        guard let plist = NSDictionary(contentsOfFile: path) else {
            print("❌ Could not read plist file")
            return
        }
        
        print("✅ Plist loaded with keys: \(plist.allKeys)")
        
        guard let clientId = plist["CLIENT_ID"] as? String else {
            print("❌ CLIENT_ID not found in plist. Available keys: \(plist.allKeys)")
            return
        }
        
        print("✅ Found CLIENT_ID: \(clientId)")
        
        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = config
        print("✅ Google Sign-In configured successfully!")
        
        // Check if we have the URL scheme
        if let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") {
            print("✅ URL types found: \(urlTypes)")
        } else {
            print("⚠️ No URL types found - this might cause issues")
        }
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
