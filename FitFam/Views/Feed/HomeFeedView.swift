//
//  HomeFeedView.swift
//  FitFam
//
//  Created by Claude on 10/08/2025.
//  
//  Main social feed screen showing workout posts from friends and community.
//  Features: Real-time updates, pull-to-refresh, infinite scrolling, social interactions.
//

import SwiftUI

/// Main home feed displaying social fitness content
struct HomeFeedView: View {
    // MARK: - Properties
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var feedViewModel = FeedViewModel()
    @State private var showDetailedProfile = false     // Shows detailed profile modal
    @State private var showContactsView = false        // Shows add friends modal
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom top navigation bar
                HStack {
                    // Enhanced profile button with email
                    Button(action: {
                        showDetailedProfile = true
                    }) {
                        HStack(spacing: 8) {
                            AsyncImage(url: URL(string: authViewModel.currentUser?.avatarURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(authViewModel.currentUser?.displayName ?? "User")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Text(authViewModel.currentUser?.email ?? "No email")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // App title
                    Text("Fit Fam")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Simple sign out button (less clicky)
                        Button(action: {
                            authViewModel.signOut()
                        }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.title3)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Enhanced add contacts button with priority animation
                        EnhancedIconButton(
                            systemName: "person.badge.plus",
                            color: .red,
                            feedbackType: .socialLike
                        ) {
                            showContactsView = true
                        }
                        .overlay(
                            // Subtle pulse animation for CTA priority
                            Circle()
                                .stroke(Color.red.opacity(0.3), lineWidth: 2)
                                .frame(width: 40, height: 40)
                                .scaleEffect(1.5)
                                .opacity(0)
                                .animation(
                                    .easeOut(duration: 2.0)
                                    .repeatForever(autoreverses: false),
                                    value: true
                                )
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(.separator)),
                    alignment: .bottom
                )
                
                // Feed content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Pull-to-refresh indicator (invisible but functional)
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 1)
                        ForEach(Array(feedViewModel.posts.enumerated()), id: \.offset) { index, post in
                            PostCardView(post: post)
                                .environmentObject(authViewModel)
                                .onAppear {
                                    // Load more posts when reaching near the end
                                    if post.id == feedViewModel.posts.last?.id {
                                        feedViewModel.loadMorePosts()
                                    }
                                }
                        }
                        
                        // Loading indicator
                        if feedViewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading more posts...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .refreshable {
                    // Psychological satisfaction through haptic + sound feedback
                    HapticManager.shared.refreshComplete()
                    SoundManager.shared.refreshComplete()
                    
                    // Refresh the feed
                    await feedViewModel.refreshFeed()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showDetailedProfile) {
            DetailedProfileView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showContactsView) {
            ContactsView()
        }
        .onAppear {
            feedViewModel.loadInitialPosts()
        }
    }
}

#Preview {
    HomeFeedView()
        .environmentObject(AuthViewModel())
}