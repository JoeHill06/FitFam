import SwiftUI

struct TestView: View {
    @State private var buttonTaps = 0
    @State private var textInput = ""
    @State private var isToggleOn = false
    @State private var sliderValue = 50.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Claude Code Integration Test")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("This page proves Claude Code is working!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 15) {
                    Button("Tap Counter: \(buttonTaps)") {
                        buttonTaps += 1
                    }
                    .buttonStyle(.borderedProminent)
                    
                    TextField("Type something here", text: $textInput)
                        .textFieldStyle(.roundedBorder)
                    
                    if !textInput.isEmpty {
                        Text("You typed: \(textInput)")
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Toggle("Toggle Switch", isOn: $isToggleOn)
                    
                    VStack {
                        Text("Slider Value: \(Int(sliderValue))")
                        Slider(value: $sliderValue, in: 0...100)
                    }
                    
                    if isToggleOn {
                        Text("🎉 Toggle is ON!")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
                
                Text("✅ Claude Code successfully created this page")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding()
            .navigationTitle("Integration Test")
        }
    }
}

#Preview {
    TestView()
}