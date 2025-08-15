import Foundation
import FirebaseFirestore
import FirebaseStorage
import Combine

class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // MARK: - User Operations
    
    func createUser(_ user: User) async throws {
        try db.collection("users").document(user.firebaseUID).setData(from: user)
    }
    
    func getUser(by userID: String) async throws -> User? {
        let document = try await db.collection("users").document(userID).getDocument()
        return try document.data(as: User.self)
    }
    
    func updateUser(_ user: User) async throws {
        guard let userID = user.id else { throw FirebaseError.missingDocumentID }
        try db.collection("users").document(userID).setData(from: user)
    }
    
    func searchUsers(by username: String) async throws -> [User] {
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: username)
            .limit(to: 10)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: User.self) }
    }
    
    // MARK: - Check-in Operations
    
    func createCheckIn(_ checkIn: WorkoutCheckIn) async throws {
        _ = try db.collection("checkIns").addDocument(from: checkIn)
        
        try await db.collection("users").document(checkIn.userID).updateData([
            "totalWorkouts": FieldValue.increment(Int64(1)),
            "lastActiveAt": FieldValue.serverTimestamp()
        ])
    }
    
    func getCheckIns(for userID: String, limit: Int = 20) async throws -> [WorkoutCheckIn] {
        let snapshot = try await db.collection("checkIns")
            .whereField("userID", isEqualTo: userID)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: WorkoutCheckIn.self) }
    }
    
    func getFeedCheckIns(for userIDs: [String], limit: Int = 20) async throws -> [WorkoutCheckIn] {
        guard !userIDs.isEmpty else { return [] }
        
        let snapshot = try await db.collection("checkIns")
            .whereField("userID", in: userIDs)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: WorkoutCheckIn.self) }
    }
    
    func addReaction(to checkInID: String, emoji: String, userID: String) async throws {
        let checkInRef = db.collection("checkIns").document(checkInID)
        
        _ = try await db.runTransaction { transaction, errorPointer in
            let document: DocumentSnapshot
            do {
                document = try transaction.getDocument(checkInRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            guard var checkIn = try? document.data(as: WorkoutCheckIn.self) else {
                errorPointer?.pointee = FirebaseError.documentNotFound as NSError
                return nil
            }
            
            if checkIn.reactions[emoji]?.contains(userID) == true {
                checkIn.reactions[emoji]?.removeAll { $0 == userID }
            } else {
                if checkIn.reactions[emoji] == nil {
                    checkIn.reactions[emoji] = []
                }
                checkIn.reactions[emoji]?.append(userID)
            }
            
            if checkIn.reactions[emoji]?.isEmpty == true {
                checkIn.reactions.removeValue(forKey: emoji)
            }
            
            do {
                try transaction.setData(from: checkIn, forDocument: checkInRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            return nil
        }
    }
    
    // MARK: - Group Operations
    
    func createGroup(_ group: FriendGroup) async throws -> String {
        let ref = try db.collection("groups").addDocument(from: group)
        return ref.documentID
    }
    
    func getGroup(by groupID: String) async throws -> FriendGroup? {
        let document = try await db.collection("groups").document(groupID).getDocument()
        return try document.data(as: FriendGroup.self)
    }
    
    func joinGroup(groupID: String, userID: String) async throws {
        try await db.collection("groups").document(groupID).updateData([
            "memberIDs": FieldValue.arrayUnion([userID])
        ])
        
        try await db.collection("users").document(userID).updateData([
            "friendGroupIDs": FieldValue.arrayUnion([groupID])
        ])
    }
    
    func leaveGroup(groupID: String, userID: String) async throws {
        try await db.collection("groups").document(groupID).updateData([
            "memberIDs": FieldValue.arrayRemove([userID])
        ])
        
        try await db.collection("users").document(userID).updateData([
            "friendGroupIDs": FieldValue.arrayRemove([groupID])
        ])
    }
    
    func getGroupsByInviteCode(_ inviteCode: String) async throws -> [FriendGroup] {
        let snapshot = try await db.collection("groups")
            .whereField("inviteCode", isEqualTo: inviteCode)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: FriendGroup.self) }
    }
    
    // MARK: - Media Upload
    
    func uploadMedia(data: Data, path: String, contentType: String) async throws -> String {
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        
        let _ = try await storageRef.putDataAsync(data, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    func uploadImage(_ imageData: Data, userID: String, checkInID: String, camera: String) async throws -> String {
        let path = "checkIns/\(userID)/\(checkInID)/\(camera)_\(UUID().uuidString).jpg"
        return try await uploadMedia(data: imageData, path: path, contentType: "image/jpeg")
    }
    
    func uploadVideo(_ videoData: Data, userID: String, checkInID: String, camera: String) async throws -> String {
        let path = "checkIns/\(userID)/\(checkInID)/\(camera)_\(UUID().uuidString).mp4"
        return try await uploadMedia(data: videoData, path: path, contentType: "video/mp4")
    }
    
    // MARK: - Streak Operations
    
    func updateStreak(_ streak: Streak) async throws {
        guard let userID = streak.id else { throw FirebaseError.missingDocumentID }
        try db.collection("streaks").document(userID).setData(from: streak)
    }
    
    func getStreak(for userID: String) async throws -> Streak? {
        let document = try await db.collection("streaks").document(userID).getDocument()
        return try document.data(as: Streak.self)
    }
    
    // MARK: - Post Operations
    
    func createPost(_ post: Post, withId postId: String) async throws {
        print("🔥 FirebaseService.createPost() - Saving to posts/\(postId)")
        print("🔥 Post data: userID=\(post.userID), postType=\(post.postType.rawValue)")
        try db.collection("posts").document(postId).setData(from: post)
        print("✅ Successfully saved to posts collection")
    }
    
    // MARK: - Real-time Listeners
    
    func listenToFeedUpdates(for userIDs: [String], completion: @escaping ([WorkoutCheckIn]) -> Void) -> ListenerRegistration? {
        guard !userIDs.isEmpty else { return nil }
        
        return db.collection("posts")
            .whereField("userID", in: userIDs)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let checkIns = documents.compactMap { try? $0.data(as: WorkoutCheckIn.self) }
                completion(checkIns)
            }
    }
}

enum FirebaseError: LocalizedError {
    case missingDocumentID
    case documentNotFound
    case uploadFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .missingDocumentID:
            return "Document ID is missing"
        case .documentNotFound:
            return "Document not found"
        case .uploadFailed:
            return "File upload failed"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}