import SwiftUI
import MapKit

struct LocationMapView: View {
    let location: Location
    @Environment(\.dismiss) private var dismiss
    
    @State private var region: MKCoordinateRegion
    
    init(location: Location) {
        self.location = location
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Map(coordinateRegion: $region, annotationItems: [location]) { location in
                    MapPin(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude), tint: .red)
                }
                .ignoresSafeArea(.container, edges: .bottom)
                
                VStack(alignment: .leading, spacing: 8) {
                    if let name = location.name {
                        Text(name)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    
                    if let address = location.address {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Lat: \(location.latitude, specifier: "%.6f"), Lng: \(location.longitude, specifier: "%.6f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospaced()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Workout Location")
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

extension Location: Identifiable {
    var id: String {
        "\(latitude),\(longitude)"
    }
}

#Preview {
    LocationMapView(location: Location(
        latitude: 37.7749,
        longitude: -122.4194,
        name: "Golden Gate Park",
        address: "San Francisco, CA"
    ))
}