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
                    // Profile icon button
                    Button(action: {
                        HapticManager.selection()
                        showDetailedProfile = true
                    }) {
                        AsyncImage(url: URL(string: authViewModel.currentUser?.avatarURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle")
                                .font(.title2)
                                .foregroundColor(DesignTokens.BrandColors.primary)
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    }
                    .frame(minWidth: DesignTokens.Accessibility.recommendedTapTarget, minHeight: DesignTokens.Accessibility.recommendedTapTarget)
                    .contentShape(Rectangle())
                    
                    Spacer()
                    
                    // App title
                    Text("Fit Fam")
                        .font(DesignTokens.Typography.Styles.title2)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    
                    Spacer()
                    
                    // Add contacts button
                    Button(action: {
                        HapticManager.selection()
                        showContactsView = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .font(.title2)
                            .foregroundColor(DesignTokens.BrandColors.primary)
                    }
                    .frame(minWidth: DesignTokens.Accessibility.recommendedTapTarget, minHeight: DesignTokens.Accessibility.recommendedTapTarget)
                    .contentShape(Rectangle())
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(DesignTokens.BackgroundColors.primary)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(DesignTokens.BorderColors.primary),
                    alignment: .bottom
                )
                
                // Feed content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(feedViewModel.posts) { post in
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
                                    .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.BrandColors.primary))
                                    .scaleEffect(0.8)
                                Text("Loading more posts...")
                                    .font(DesignTokens.Typography.Styles.caption1)
                                    .foregroundColor(DesignTokens.TextColors.secondary)
                            }
                            .padding(DesignTokens.Spacing.md)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.top, DesignTokens.Spacing.xs)
                }
                .refreshable {
                    await feedViewModel.refreshFeed()
                }
            }
            .tokenBackground(DesignTokens.BackgroundColors.secondary)
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