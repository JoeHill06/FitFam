//
//  ConfirmationDialog.swift
//  FitFam
//
//  Reusable confirmation dialog with enhanced UX and haptic feedback
//

import SwiftUI

/// Reusable confirmation dialog for destructive or important actions
struct ConfirmationDialog: ViewModifier {
    let isPresented: Binding<Bool>
    let title: String
    let message: String
    let confirmTitle: String
    let confirmAction: () -> Void
    let isDestructive: Bool
    
    init(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String,
        confirmAction: @escaping () -> Void,
        isDestructive: Bool = false
    ) {
        self.isPresented = isPresented
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.confirmAction = confirmAction
        self.isDestructive = isDestructive
    }
    
    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: isPresented) {
                Button("Cancel", role: .cancel) {
                    HapticManager.lightTap()
                }
                
                Button(confirmTitle, role: isDestructive ? .destructive : nil) {
                    if isDestructive {
                        HapticManager.warning()
                    } else {
                        HapticManager.success()
                    }
                    confirmAction()
                }
            } message: {
                Text(message)
            }
    }
}

extension View {
    func confirmationDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String,
        confirmAction: @escaping () -> Void,
        isDestructive: Bool = false
    ) -> some View {
        self.modifier(
            ConfirmationDialog(
                isPresented: isPresented,
                title: title,
                message: message,
                confirmTitle: confirmTitle,
                confirmAction: confirmAction,
                isDestructive: isDestructive
            )
        )
    }
}