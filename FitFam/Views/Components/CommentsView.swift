import SwiftUI

struct CommentsView: View {
    let post: Post
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var newComment = ""
    @State private var comments: [Comment] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Comments list
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(comments) { comment in
                            CommentRow(comment: comment)
                        }
                        
                        if comments.isEmpty {
                            VStack(spacing: 12) {
                                Text("💬")
                                    .font(.system(size: 48))
                                Text("Be the first to comment!")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                Text("Share your thoughts on this workout")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Comment input
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: authViewModel.currentUser?.avatarURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .overlay(
                                Text(String(authViewModel.currentUser?.displayName.first?.uppercased() ?? "U"))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            )
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    
                    TextField("Add a comment...", text: $newComment, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                    
                    Button(action: addComment) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(newComment.isEmpty ? .secondary : .blue)
                    }
                    .disabled(newComment.isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadComments()
        }
    }
    
    private func loadComments() {
        // For now, use mock data
        comments = Comment.mockComments
    }
    
    private func addComment() {
        guard !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let user = authViewModel.currentUser,
              let postId = post.id else { return }
        
        let comment = Comment(
            postID: postId,
            userID: user.firebaseUID,
            username: user.username,
            userAvatarURL: user.avatarURL,
            content: newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        comments.append(comment)
        newComment = ""
        
        // TODO: Save to Firebase
    }
}

struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: comment.userAvatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .overlay(
                        Text(String(comment.username.first?.uppercased() ?? "U"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    )
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(comment.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.content)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    CommentsView(post: Post.mockPosts[0])
        .environmentObject(AuthViewModel())
}