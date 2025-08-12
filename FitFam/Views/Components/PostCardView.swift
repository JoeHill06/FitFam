//
//  PostCardView.swift
//  FitFam
//
//  Created by Claude on 10/08/2025.
//  
//  Individual post card component for the social feed.
//  Displays workout information, user details, media, stats, and social engagement options.
//

import SwiftUI
import MapKit

/// Individual workout post card with social features
struct PostCardView: View {
    // MARK: - Properties
    let post: Post
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isCheerAnimating = false        // Animation for cheer button
    @State private var showComments = false            // Present comments modal
    @State private var showLocationOnMap = false       // Present location map
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User header
            HStack(spacing: 12) {
                // User avatar
                AsyncImage(url: URL(string: post.userAvatarURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(DesignTokens.BrandColors.primary.opacity(0.2))
                        .overlay(
                            Text(String(post.username.first?.uppercased() ?? "U"))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignTokens.BrandColors.primary)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    // Username and workout type badge
                    HStack(spacing: 8) {
                        Text(post.username)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // Workout type badge
                        if post.postType == .workout, let workoutData = post.workoutData {
                            HStack(spacing: 4) {
                                Text(workoutData.activityType.icon)
                                    .font(.caption)
                                Text(workoutData.activityType.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(DesignTokens.BrandColors.primary.opacity(0.15))
                            .foregroundColor(DesignTokens.BrandColors.primary)
                            .cornerRadius(12)
                        } else {
                            HStack(spacing: 4) {
                                Text(post.postType.icon)
                                    .font(.caption)
                                Text(post.postType.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(colorForPostType(post.postType).opacity(0.15))
                            .foregroundColor(colorForPostType(post.postType))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Timestamp
                    Text(post.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Post content
            if let content = post.content, !content.isEmpty {
                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            
            // Workout image (if available)
            if let mediaURL = post.mediaURL, !mediaURL.isEmpty {
                AsyncImage(url: URL(string: mediaURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxHeight: 300)
                        .clipped()
                        .cornerRadius(12)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay(
                            ProgressView()
                        )
                }
            }
            
            // Workout stats (compact format)
            if let workoutData = post.workoutData {
                WorkoutStatsView(workoutData: workoutData)
            }
            
            // Location check-in
            if let location = post.location {
                LocationView(location: location) {
                    showLocationOnMap = true
                }
            }
            
            // Engagement buttons
            HStack(spacing: 24) {
                // Cheer button
                Button(action: {
                    HapticManager.cheerGiven()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isCheerAnimating = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isCheerAnimating = false
                    }
                    
                    // TODO: Implement cheer functionality
                }) {
                    HStack(spacing: 4) {
                        Text("👏")
                            .font(.body)
                            .scaleEffect(isCheerAnimating ? 1.2 : 1.0)
                        Text("\(post.cheerCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(post.isCheerByCurrentUser ? DesignTokens.BrandColors.primary : DesignTokens.TextColors.secondary)
                }
                .frame(minHeight: DesignTokens.Accessibility.recommendedTapTarget)
                .contentShape(Rectangle())
                
                // Comment button
                Button(action: {
                    HapticManager.lightTap()
                    showComments = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "message")
                            .font(.caption)
                        Text("\(post.commentCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(DesignTokens.TextColors.secondary)
                }
                .frame(minHeight: DesignTokens.Accessibility.recommendedTapTarget)
                .contentShape(Rectangle())
                
                // Share button
                Button(action: {
                    HapticManager.lightTap()
                    // TODO: Implement share functionality
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundColor(DesignTokens.TextColors.secondary)
                }
                .frame(minHeight: DesignTokens.Accessibility.recommendedTapTarget)
                .contentShape(Rectangle())
                
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showComments) {
            CommentsView(post: post)
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showLocationOnMap) {
            if let location = post.location {
                LocationMapView(location: location)
            }
        }
    }
    
    private func colorForPostType(_ postType: PostType) -> Color {
        switch postType.color {
        case "blue": return .blue
        case "yellow": return .yellow
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        default: return .blue
        }
    }
}

struct WorkoutStatsView: View {
    let workoutData: WorkoutData
    
    var body: some View {
        HStack(spacing: 16) {
            if let duration = workoutData.duration, duration > 0 {
                StatItem(icon: "clock", value: workoutData.formattedDuration, label: "Duration")
            }
            
            if let distance = workoutData.distance, distance > 0 {
                StatItem(icon: "location", value: workoutData.formattedDistance, label: "Distance")
            }
            
            if let calories = workoutData.calories, calories > 0 {
                StatItem(icon: "flame", value: workoutData.formattedCalories, label: "Calories")
            }
            
            if let intensity = workoutData.intensity, intensity > 0 {
                StatItem(icon: "bolt", value: "\(intensity)/10", label: "Intensity")
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.blue)
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct LocationView: View {
    let location: Location
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                    .font(.subheadline)
                
                VStack(alignment: .leading, spacing: 1) {
                    if let name = location.name {
                        Text(name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    if let address = location.address {
                        Text(address)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        PostCardView(post: Post.mockPosts[0])
            .environmentObject(AuthViewModel())
        
        PostCardView(post: Post.mockPosts[1])
            .environmentObject(AuthViewModel())
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}