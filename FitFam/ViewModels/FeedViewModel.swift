//
//  FeedViewModel.swift
//  FitFam
//
//  Created by Claude on 10/08/2025.
//  
//  ViewModel managing the home feed display and social interactions.
//  Handles real-time post loading, pagination, and user engagement (cheers, comments).
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Manages the home feed data and social interactions
@MainActor
class FeedViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var posts: [Post] = []           // Current feed posts
    @Published var isLoading = false            // Loading state for UI
    @Published var errorMessage: String?        // Error messages for user feedback
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()     // Firestore database reference
    private var listener: ListenerRegistration? // Real-time listener
    private var lastDocument: DocumentSnapshot? // For pagination
    private let postsPerPage = 10               // Posts loaded per batch
    
    // MARK: - Initializer
    init() {
        // Start with empty posts array - let real data load first
        posts = []
        print("🔄 FeedViewModel initialized - starting with empty posts array")
    }
    
    // MARK: - Public Methods
    
    /// Loads the initial set of posts and sets up real-time listening
    func loadInitialPosts() {
        guard !isLoading else { return }
        isLoading = true
        
        // Set up real-time listener for posts
        print("🔄 FeedViewModel.loadInitialPosts() - Setting up Firestore listener")
        listener = db.collection("posts")
            .order(by: "timestamp", descending: true)
            .limit(to: postsPerPage)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                print("📡 Firestore snapshot received")
                
                if let error = error {
                    print("❌ Firestore error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    // Only use mock data if we have no existing real posts
                    if self.posts.isEmpty {
                        print("⚠️ Firebase error, showing mock data: \(error.localizedDescription)")
                        self.posts = Post.mockPosts
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📝 No snapshot documents found")
                    self.isLoading = false
                    // Only show mock data if truly no documents found
                    if self.posts.isEmpty {
                        print("📝 No documents in posts collection, showing mock data")
                        self.posts = Post.mockPosts
                    }
                    return
                }
                
                print("📄 Found \(documents.count) documents in posts collection")
                
                // Log each document for debugging
                for (index, document) in documents.enumerated() {
                    let data = document.data()
                    print("📄 Document \(index): ID=\(document.documentID)")
                    print("   - userID: \(data["userID"] ?? "nil")")
                    print("   - username: \(data["username"] ?? "nil")")
                    print("   - postType: \(data["postType"] ?? "nil")")
                    print("   - timestamp: \(data["timestamp"] ?? "nil")")
                    print("   - backImageUrl: \(data["backImageUrl"] ?? "nil")")
                    print("   - frontImageUrl: \(data["frontImageUrl"] ?? "nil")")
                }
                
                let decodedPosts = documents.compactMap { document -> Post? in
                    do {
                        let post = try document.data(as: Post.self)
                        print("✅ Successfully decoded post: \(post.username) - \(post.postType.rawValue)")
                        return post
                    } catch {
                        print("❌ Failed to decode post \(document.documentID): \(error)")
                        return nil
                    }
                }.filter { post in
                    let hasId = post.id != nil
                    if !hasId {
                        print("⚠️ Post missing ID: \(post.username)")
                    }
                    return hasId
                }
                
                print("🔄 Decoded \(decodedPosts.count) valid posts")
                self.posts = decodedPosts
                self.lastDocument = documents.last
                self.isLoading = false
                
                // Smart fallback: Only use mock data if no real posts AND no errors
                if self.posts.isEmpty && self.errorMessage == nil {
                    print("📝 No real posts found after processing, showing mock data for development")
                    self.posts = Post.mockPosts
                } else if !self.posts.isEmpty {
                    print("✅ Loaded \(self.posts.count) real posts from Firebase")
                    // Log first post for verification
                    if let firstPost = self.posts.first {
                        let timeStr = firstPost.timestamp.description
                        print("🎯 First post: \(firstPost.username) posted \(firstPost.postType.rawValue) at \(timeStr)")
                    }
                }
            }
    }
    
    func loadMorePosts() {
        guard !isLoading, let lastDocument = lastDocument else { return }
        isLoading = true
        
        db.collection("posts")
            .order(by: "timestamp", descending: true)
            .start(afterDocument: lastDocument)
            .limit(to: postsPerPage)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        return
                    }
                    
                    let newPosts = documents.compactMap { document in
                        try? document.data(as: Post.self)
                    }.filter { $0.id != nil }
                    
                    self.posts.append(contentsOf: newPosts)
                    self.lastDocument = documents.last
                }
            }
    }
    
    func refreshFeed() async {
        // Remove existing listener
        listener?.remove()
        lastDocument = nil
        posts = []
        
        loadInitialPosts()
    }
    
    func cheerPost(_ post: Post) {
        guard let currentUser = Auth.auth().currentUser,
              let postId = post.id else { return }
        
        let cheerData: [String: Any] = [
            "postID": postId,
            "userID": currentUser.uid,
            "username": currentUser.displayName ?? "Anonymous",
            "timestamp": Timestamp()
        ]
        
        // Add cheer to Firestore
        db.collection("cheers").addDocument(data: cheerData) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                // Update local post
                DispatchQueue.main.async {
                    if let index = self?.posts.firstIndex(where: { $0.id == postId }) {
                        self?.posts[index].cheerCount += 1
                        self?.posts[index].isCheerByCurrentUser = true
                    }
                }
            }
        }
    }
    
    func createPost(content: String, postType: PostType, workoutData: WorkoutData? = nil, mediaURL: String? = nil, location: Location? = nil) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let post = Post(
            userID: currentUser.uid,
            username: currentUser.displayName ?? "Anonymous",
            userAvatarURL: currentUser.photoURL?.absoluteString,
            postType: postType,
            content: content,
            workoutData: workoutData,
            mediaURL: mediaURL,
            location: location
        )
        
        do {
            try db.collection("posts").addDocument(from: post) { [weak self] error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
                // The real-time listener will automatically update the UI
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func cleanup() {
        listener?.remove()
        listener = nil
        lastDocument = nil
        posts = []
        isLoading = false
        errorMessage = nil
    }
    
    deinit {
        listener?.remove()
    }
}