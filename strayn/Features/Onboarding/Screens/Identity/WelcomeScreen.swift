//
//  WelcomeScreen.swift
//  strayn
//
//  Welcome screen with app logo animation and auto-advance.
//

import SwiftUI

struct WelcomeScreen: View {
    let onContinue: () -> Void

    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo with glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(StraynColors.accentPrimary.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .opacity(glowOpacity)
                    .scaleEffect(pulseScale)

                // Logo container
                ZStack {
                    // Background circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    StraynColors.accentPrimary.opacity(0.2),
                                    StraynColors.accentPrimary.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)

                    // Logo icon
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 70, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [StraynColors.accentPrimary, StraynColors.recovery],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
            }

            Spacer().frame(height: 60)

            // Text content
            VStack(spacing: 16) {
                Text("STRAYN")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .tracking(6)
                    .foregroundColor(.white)

                Text("Your Biological Operating System")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(StraynColors.textSecondary)
            }
            .opacity(textOpacity)

            Spacer()

            // Tap to continue hint
            Text("Starting your journey...")
                .font(.system(size: 14))
                .foregroundColor(StraynColors.textMuted)
                .opacity(textOpacity)
                .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            animateEntrance()
        }
        .onTapGesture {
            // Allow tap to skip
            onContinue()
        }
    }

    private func animateEntrance() {
        // Logo scale up
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // Glow fade in
        withAnimation(.easeIn(duration: 0.6).delay(0.3)) {
            glowOpacity = 1.0
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.5)) {
            pulseScale = 1.15
        }

        // Text fade in
        withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
            textOpacity = 1.0
        }

        // Haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            HapticsManager.shared.playScoreReveal()
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeScreen(onContinue: {})
}
