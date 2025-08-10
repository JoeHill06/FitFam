import SwiftUI
import MapKit

struct ActivityMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Activity Map")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Map view coming soon! 🗺️")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Activity Map")
        }
    }
}

#Preview {
    ActivityMapView()
}