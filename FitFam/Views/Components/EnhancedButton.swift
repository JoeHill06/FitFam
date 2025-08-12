import SwiftUI

/// Enhanced button with psychological micro-interactions
/// Provides haptic feedback, sound effects, and satisfying animations
struct EnhancedButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    let feedbackType: UserAction
    
    @State private var isPressed = false
    
    init(_ title: String, style: ButtonStyle = .primary, feedbackType: UserAction = .buttonPress, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.feedbackType = feedbackType
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Immediate feedback for psychological satisfaction
            HapticManager.shared.buttonPress()
            SoundManager.shared.buttonTap()
            
            // Execute the actual action
            action()
        }) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(style.foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(style.backgroundColor)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style.borderColor, lineWidth: style.borderWidth)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Button Styles

extension EnhancedButton {
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case success
        case social
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .blue
            case .secondary: return Color(.systemGray5)
            case .destructive: return .red
            case .success: return .green
            case .social: return Color(.systemBlue)
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .destructive, .success, .social: return .white
            case .secondary: return .primary
            }
        }
        
        var borderColor: Color {
            switch self {
            case .primary: return .blue.opacity(0.3)
            case .secondary: return Color(.systemGray4)
            case .destructive: return .red.opacity(0.3)
            case .success: return .green.opacity(0.3)
            case .social: return Color(.systemBlue).opacity(0.3)
            }
        }
        
        var borderWidth: CGFloat {
            return 0.5
        }
    }
}

/// Enhanced icon button with micro-interactions
struct EnhancedIconButton: View {
    let systemName: String
    let action: () -> Void
    let feedbackType: UserAction
    let color: Color
    
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
    init(systemName: String, color: Color = .blue, feedbackType: UserAction = .buttonPress, action: @escaping () -> Void) {
        self.systemName = systemName
        self.color = color
        self.feedbackType = feedbackType
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Rich feedback for icon interactions
            switch feedbackType {
            case .socialLike:
                HapticManager.shared.socialInteraction()
                SoundManager.shared.socialInteraction()
                // Add satisfying "bounce" animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.2
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
                    scale = 1.0
                }
            case .photoCapture:
                HapticManager.shared.photoCapture()
                SoundManager.shared.cameraCapture()
            default:
                HapticManager.shared.lightTap()
                SoundManager.shared.buttonTap()
            }
            
            action()
        }) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundColor(color)
                .scaleEffect(scale)
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

/// Floating action button with psychological appeal
struct FloatingActionButton: View {
    let systemName: String
    let action: () -> Void
    let color: Color
    
    @State private var isPressed = false
    @State private var shadowRadius: CGFloat = 8
    
    init(systemName: String, color: Color = .blue, action: @escaping () -> Void) {
        self.systemName = systemName
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.mediumImpact()
            SoundManager.shared.buttonTap()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                shadowRadius = 4
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.1)) {
                shadowRadius = 8
            }
            
            action()
        }) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: color.opacity(0.3), radius: shadowRadius, x: 0, y: 4)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        EnhancedButton("Primary Button", style: .primary) {
            print("Primary tapped")
        }
        
        EnhancedButton("Secondary Button", style: .secondary) {
            print("Secondary tapped")
        }
        
        HStack {
            EnhancedIconButton(systemName: "heart", color: .red, feedbackType: .socialLike) {
                print("Like tapped")
            }
            
            EnhancedIconButton(systemName: "camera.fill", color: .blue, feedbackType: .photoCapture) {
                print("Camera tapped")
            }
        }
        
        FloatingActionButton(systemName: "plus", color: .blue) {
            print("FAB tapped")
        }
    }
    .padding()
}