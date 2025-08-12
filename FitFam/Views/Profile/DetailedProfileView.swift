import SwiftUI

struct DetailedProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: authViewModel.currentUser?.avatarURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .overlay(
                                    Text(String(authViewModel.currentUser?.displayName.first?.uppercased() ?? "U"))
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.blue)
                                )
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        VStack(spacing: 8) {
                            Text(authViewModel.currentUser?.displayName ?? "User")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("@\(authViewModel.currentUser?.username ?? "username")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Edit Profile Button
                        Button("Edit Profile") {
                            showEditProfile = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    // Profile Details Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Profile Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            ProfileDetailRow(title: "First Name", value: authViewModel.currentUser?.firstName ?? "Not set")
                            ProfileDetailRow(title: "Surname", value: authViewModel.currentUser?.surname ?? "Not set")
                            ProfileDetailRow(title: "Username", value: "@\(authViewModel.currentUser?.username ?? "Not set")")
                            ProfileDetailRow(title: "Display Name", value: authViewModel.currentUser?.displayName ?? "Not set")
                            ProfileDetailRow(title: "Email", value: authViewModel.currentUser?.email ?? "Not set")
                            ProfileDetailRow(title: "Member Since", value: authViewModel.currentUser?.createdAt.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
                .environmentObject(authViewModel)
        }
    }
}

struct ProfileDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    DetailedProfileView()
        .environmentObject(AuthViewModel())
}