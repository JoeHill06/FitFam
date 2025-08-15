//
//  ActivityPickerView.swift
//  FitFam
//
//  Created by Claude on 14/08/2025.
//  
//  Activity picker modal for selecting workout type during post creation.
//  Displays all 11 activity types with emojis in a clean grid layout.
//

import SwiftUI

struct ActivityPickerView: View {
    @Binding var selectedActivity: ActivityType?
    @Binding var isPresented: Bool
    let onActivitySelected: (ActivityType) -> Void
    
    @State private var isVisible = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    // Header
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Text("Select Activity")
                            .font(DesignTokens.Typography.Styles.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignTokens.TextColors.primary)
                        
                        Text("Choose the type of workout you did")
                            .font(DesignTokens.Typography.Styles.body)
                            .foregroundColor(DesignTokens.TextColors.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .offset(y: isVisible ? 0 : -20)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4), value: isVisible)
                    
                    // Activity Grid
                    LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.md) {
                        ForEach(ActivityType.allCases, id: \.self) { activity in
                            ActivityCard(
                                activity: activity,
                                isSelected: selectedActivity == activity,
                                onTap: {
                                    HapticManager.selection()
                                    selectedActivity = activity
                                    onActivitySelected(activity)
                                    
                                    // Dismiss after selection
                                    withAnimation(.easeIn(duration: 0.25)) {
                                        isVisible = false
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        isPresented = false
                                    }
                                }
                            )
                        }
                    }
                    .offset(y: isVisible ? 0 : 30)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: isVisible)
                    
                    Spacer(minLength: DesignTokens.Spacing.xl4)
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, DesignTokens.Spacing.lg)
            }
            .tokenBackground(DesignTokens.BackgroundColors.primary)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        HapticManager.lightTap()
                        withAnimation(.easeIn(duration: 0.25)) {
                            isVisible = false
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            isPresented = false
                        }
                    }
                    .foregroundColor(DesignTokens.TextColors.secondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = true
            }
        }
    }
}


// MARK: - Preview

#Preview {
    ActivityPickerView(
        selectedActivity: .constant(.gym),
        isPresented: .constant(true),
        onActivitySelected: { _ in }
    )
}