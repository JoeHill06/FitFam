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
        // Start with mock data for development and offline functionality
        posts = Post.mockPosts
    }
    
    // MARK: - Public Methods
    
    /// Loads the initial set of posts and sets up real-time listening
    func loadInitialPosts() {
        guard !isLoading else { return }
        isLoading = true
        
        // Set up real-time listener for posts
        listener = db.collection("posts")
            .order(by: "timestamp", descending: true)
            .limit(to: postsPerPage)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    // Fallback to mock data if Firebase fails
                    if self.posts.isEmpty {
                        self.posts = Post.mockPosts
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.isLoading = false
                    // Fallback to mock data if no documents
                    if self.posts.isEmpty {
                        self.posts = Post.mockPosts
                    }
                    return
                }
                
                self.posts = documents.compactMap { document in
                    try? document.data(as: Post.self)
                }
                
                self.lastDocument = documents.last
                self.isLoading = false
                
                // If no posts from Firebase, use mock data for development
                if self.posts.isEmpty {
                    self.posts = Post.mockPosts
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
                    }
                    
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
        
        // Immediate haptic and sound feedback for social interaction
        HapticManager.shared.socialInteraction()
        SoundManager.shared.socialInteraction()
        
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
    
    deinit {
        listener?.remove()
    }
}