import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var firstName: String = ""
    @State private var surname: String = ""
    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var avatarData: Data?
    @State private var showingImagePicker = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Photo Section
                    VStack(spacing: 16) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                            ZStack {
                                if let avatarImage {
                                    avatarImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    AsyncImage(url: URL(string: authViewModel.currentUser?.avatarURL ?? "")) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
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
                                }
                                
                                Circle()
                                    .strokeBorder(.white, lineWidth: 4)
                                    .background(Circle().fill(.black.opacity(0.1)))
                                    .frame(width: 120, height: 120)
                                
                                // Edit overlay
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .semibold))
                                            .padding(8)
                                            .background(Color.blue)
                                            .clipShape(Circle())
                                            .offset(x: -10, y: -10)
                                    }
                                }
                                .frame(width: 120, height: 120)
                            }
                        }
                        
                        Text("Tap to change profile photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Personal Information
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Personal Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("First Name")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    TextField("First name", text: $firstName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .textContentType(.givenName)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Surname")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    TextField("Surname", text: $surname)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .textContentType(.familyName)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Username")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                TextField("Username", text: $username)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.username)
                                    .autocapitalization(.none)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Display Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                TextField("Display name", text: $displayName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.name)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                Text(authViewModel.currentUser?.email ?? "No email")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(6)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
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
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(isLoading || firstName.isEmpty || surname.isEmpty || username.isEmpty)
                }
            }
        }
        .onAppear {
            loadCurrentUserData()
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    avatarData = data
                    if let uiImage = UIImage(data: data) {
                        avatarImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }
    
    private func loadCurrentUserData() {
        guard let user = authViewModel.currentUser else { return }
        
        firstName = user.firstName
        surname = user.surname
        username = user.username
        displayName = user.displayName
    }
    
    private func saveProfile() async {
        isLoading = true
        
        // Update user profile with new data
        await authViewModel.updateUserProfile(
            firstName: firstName,
            surname: surname,
            username: username,
            displayName: displayName,
            avatarData: avatarData
        )
        
        isLoading = false
        dismiss()
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AuthViewModel())
}