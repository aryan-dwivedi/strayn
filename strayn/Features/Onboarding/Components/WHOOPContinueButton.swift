//
//  WHOOPContinueButton.swift
//  strayn
//
//  WHOOP-style continue button with glow effects.
//

import SwiftUI

struct WHOOPContinueButton: View {
    let title: String
    let isEnabled: Bool
    let accentColor: Color
    let action: () -> Void

    @State private var isPressed = false

    init(
        title: String = "Continue",
        isEnabled: Bool = true,
        accentColor: Color = StraynColors.accentPrimary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.accentColor = accentColor
        self.action = action
    }

    var body: some View {
        Button(action: performAction) {
            ZStack {
                // Glow effect
                if isEnabled {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(accentColor.opacity(0.4))
                        .blur(radius: 15)
                        .offset(y: 5)
                }

                // Button
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(isEnabled ? .black : StraynColors.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isEnabled ? Color.white : StraynColors.surfaceSecondary)
                    )
            }
        }
        .disabled(!isEnabled)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private func performAction() {
        guard isEnabled else { return }
        HapticsManager.shared.playImpact(.medium)
        action()
    }
}

// MARK: - Secondary Button

struct WHOOPSecondaryButton: View {
    let title: String
    let icon: String?
    let accentColor: Color
    let action: () -> Void

    init(
        title: String,
        icon: String? = nil,
        accentColor: Color = StraynColors.accentPrimary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticsManager.shared.playImpact(.light)
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(accentColor)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Skip Button

struct WHOOPSkipButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticsManager.shared.playImpact(.light)
            action()
        }) {
            Text("Skip")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(StraynColors.textSecondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
        }
    }
}

// MARK: - Capture Button (For Camera Screens)

struct WHOOPCaptureButton: View {
    let isEnabled: Bool
    let onCapture: () -> Void

    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: performCapture) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 80, height: 80)

                // Pulse effect when enabled
                if isEnabled {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseScale)
                }

                // Inner circle
                Circle()
                    .fill(isEnabled ? Color.white : Color.white.opacity(0.5))
                    .frame(width: 68, height: 68)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
        }
        .disabled(!isEnabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            if isEnabled {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.15
                }
            }
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    }

    private func performCapture() {
        guard isEnabled else { return }
        HapticsManager.shared.playImpact(.medium)
        onCapture()
    }
}

// MARK: - Back Button

struct WHOOPBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticsManager.shared.playImpact(.light)
            action()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(StraynColors.surfacePrimary)
                        .overlay(
                            Circle()
                                .stroke(StraynColors.borderSubtle, lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 30) {
            WHOOPBackButton(action: {})

            Spacer()

            WHOOPCaptureButton(isEnabled: true, onCapture: {})

            Spacer()

            WHOOPSkipButton(action: {})

            WHOOPSecondaryButton(
                title: "Learn More",
                icon: "info.circle",
                action: {}
            )

            WHOOPContinueButton(action: {})
                .padding(.horizontal, 32)

            WHOOPContinueButton(
                title: "Continue",
                isEnabled: false,
                action: {}
            )
            .padding(.horizontal, 32)
        }
        .padding()
    }
}
