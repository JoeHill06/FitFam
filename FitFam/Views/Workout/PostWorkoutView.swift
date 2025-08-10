import SwiftUI

struct PostWorkoutView: View {
    @State private var selectedActivity: ActivityType = .running
    @State private var workoutContent = ""
    @State private var duration: TimeInterval = 1800
    @State private var distance: Double = 5.0
    @State private var calories: Int = 300
    @State private var intensity: Int = 5
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Post Workout")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Share your workout with the community! 💪")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Activity Type")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(ActivityType.allCases, id: \.self) { activity in
                                Button(action: {
                                    selectedActivity = activity
                                }) {
                                    VStack(spacing: 4) {
                                        Text(activity.icon)
                                            .font(.title2)
                                        Text(activity.displayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .frame(height: 60)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedActivity == activity ? Color.blue.opacity(0.2) : Color(.systemGray6))
                                    .foregroundColor(selectedActivity == activity ? .blue : .primary)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Workout Details")
                            .font(.headline)
                        
                        TextField("How was your workout?", text: $workoutContent, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Duration:")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(duration/60)) min")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Slider(value: $duration, in: 300...7200, step: 300)
                                .accentColor(.blue)
                        }
                        
                        if selectedActivity == .running || selectedActivity == .cycling || selectedActivity == .walking {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Distance:")
                                        .font(.subheadline)
                                    Spacer()
                                    Text(String(format: "%.1f km", distance))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Slider(value: $distance, in: 0.5...50.0, step: 0.5)
                                    .accentColor(.blue)
                            }
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Intensity:")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(intensity)/10")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Slider(value: .init(get: { Double(intensity) }, set: { intensity = Int($0) }), in: 1...10, step: 1)
                                .accentColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    Button(action: {
                        // TODO: Implement post creation
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Share Workout")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    PostWorkoutView()
}