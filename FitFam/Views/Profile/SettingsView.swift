import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var notificationsEnabled = true
    @State private var locationSharingEnabled = true
    @State private var profilePublic = false
    @State private var selectedUnit = "Metric"
    
    let units = ["Metric", "Imperial"]
    
    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section("Account") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authViewModel.currentUser?.email ?? "")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Username")
                        Spacer()
                        Text("@\(authViewModel.currentUser?.username ?? "")")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Change Password") {
                        // TODO: Implement password change
                    }
                    .foregroundColor(.blue)
                }
                
                // Privacy Section
                Section("Privacy") {
                    Toggle("Public Profile", isOn: $profilePublic)
                    
                    Toggle("Location Sharing", isOn: $locationSharingEnabled)
                    
                    Button("Blocked Users") {
                        // TODO: Show blocked users
                    }
                    .foregroundColor(.blue)
                }
                
                // Notifications Section
                Section("Notifications") {
                    Toggle("Push Notifications", isOn: $notificationsEnabled)
                    
                    Button("Notification Settings") {
                        // TODO: Show detailed notification settings
                    }
                    .foregroundColor(.blue)
                }
                
                // App Preferences Section
                Section("Preferences") {
                    HStack {
                        Text("Units")
                        Spacer()
                        Picker("Units", selection: $selectedUnit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Button("Reset App Data") {
                        // TODO: Show confirmation dialog
                    }
                    .foregroundColor(.red)
                }
                
                // Support Section
                Section("Support") {
                    Button("Help & FAQ") {
                        // TODO: Show help
                    }
                    .foregroundColor(.blue)
                    
                    Button("Contact Support") {
                        // TODO: Contact support
                    }
                    .foregroundColor(.blue)
                    
                    Button("Privacy Policy") {
                        // TODO: Show privacy policy
                    }
                    .foregroundColor(.blue)
                    
                    Button("Terms of Service") {
                        // TODO: Show terms
                    }
                    .foregroundColor(.blue)
                }
                
                // App Info Section
                Section("App Info") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
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
    SettingsView()
        .environmentObject(AuthViewModel())
}