import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSettings = false
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Photo
                        AsyncImage(url: URL(string: authViewModel.currentUser?.avatarURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .overlay(
                                    Text(String(authViewModel.currentUser?.displayName.first?.uppercased() ?? "U"))
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.blue)
                                )
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        VStack(spacing: 4) {
                            Text(authViewModel.currentUser?.displayName ?? "User")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("@\(authViewModel.currentUser?.username ?? "username")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Bio stats
                        HStack(spacing: 24) {
                            StatColumn(number: "\(authViewModel.currentUser?.currentStreak ?? 0)", label: "Streak")
                            StatColumn(number: "\(authViewModel.currentUser?.totalWorkouts ?? 0)", label: "Workouts")
                            StatColumn(number: "12", label: "Friends")
                        }
                        
                        // Edit Profile Button
                        Button(action: {
                            // TODO: Navigate to edit profile
                        }) {
                            Text("Edit Profile")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(18)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // Quick Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Stats")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            ProfileStatRow(icon: "🔥", title: "Current Streak", value: "\(authViewModel.currentUser?.currentStreak ?? 0) days")
                            ProfileStatRow(icon: "🏆", title: "Longest Streak", value: "\(authViewModel.currentUser?.longestStreak ?? 0) days")
                            ProfileStatRow(icon: "📅", title: "Member Since", value: "January 2025")
                            ProfileStatRow(icon: "🎯", title: "Weekly Goal", value: "4 workouts")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Activity")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            RecentActivityRow(icon: "🏃‍♂️", activity: "Morning Run", time: "2h ago", details: "5.2 km • 28 min")
                            RecentActivityRow(icon: "💪", activity: "Gym Workout", time: "Yesterday", details: "45 min • Upper Body")
                            RecentActivityRow(icon: "🧘‍♀️", activity: "Yoga Session", time: "2 days ago", details: "30 min • Flexibility")
                        }
                        
                        Button(action: {
                            // TODO: Show full activity history
                        }) {
                            Text("View All Activity")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // Settings Section
                    VStack(spacing: 12) {
                        SettingsRow(icon: "gearshape.fill", title: "Settings", action: { showSettings = true })
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", action: {})
                        SettingsRow(icon: "info.circle.fill", title: "About", action: {})
                        
                        Divider()
                        
                        // Sign Out Button
                        Button(action: {
                            showSignOutConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                Text("Sign Out")
                                    .foregroundColor(.red)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(authViewModel)
        }
        .alert("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out? You'll need to sign back in to access your account.")
        }
    }
}

struct StatColumn: View {
    let number: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ProfileStatRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title3)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

struct RecentActivityRow: View {
    let icon: String
    let activity: String
    let time: String
    let details: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}