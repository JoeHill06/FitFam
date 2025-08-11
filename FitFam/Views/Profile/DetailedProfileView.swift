import SwiftUI

struct DetailedProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Detailed Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Full profile editing coming soon! ⚡")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
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
                    }
                    
                    Spacer()
                }
                .padding()
            }
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
    }
}

#Preview {
    DetailedProfileView()
        .environmentObject(AuthViewModel())
}