import SwiftUI

struct ContactsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add Friends")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Find and connect with friends! 👥")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                SearchBar(text: $searchText)
                    .padding()
                
                VStack(spacing: 16) {
                    ContactOption(icon: "person.badge.plus", title: "Find by Username", description: "Search for friends by their username") {
                        // TODO: Implement username search
                    }
                    
                    ContactOption(icon: "envelope", title: "Find by Email", description: "Invite friends using their email address") {
                        // TODO: Implement email search
                    }
                    
                    ContactOption(icon: "phone", title: "Phone Contacts", description: "Find friends from your contacts") {
                        // TODO: Implement phone contacts
                    }
                    
                    ContactOption(icon: "qrcode", title: "QR Code", description: "Share your QR code for easy adding") {
                        // TODO: Show QR code
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Add Contacts")
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

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search users...", text: $text)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ContactOption: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContactsView()
}