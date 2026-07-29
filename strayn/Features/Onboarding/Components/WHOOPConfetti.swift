//
//  WHOOPConfetti.swift
//  strayn
//
//  WHOOP-style confetti and celebration effects for completion screens.
//

import SwiftUI

struct WHOOPConfetti: View {
    @State private var isAnimating = false

    let colors: [Color]
    let particleCount: Int

    init(
        colors: [Color] = [
            StraynColors.recovery,
            StraynColors.strain,
            StraynColors.sleep,
            StraynColors.accentPrimary,
            .white
        ],
        particleCount: Int = 50
    ) {
        self.colors = colors
        self.particleCount = particleCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { index in
                    WHOOPConfettiParticle(
                        color: colors[index % colors.count],
                        size: CGFloat.random(in: 6...12),
                        initialX: CGFloat.random(in: 0...geometry.size.width),
                        delay: Double.random(in: 0...0.5)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            HapticsManager.shared.playStreakCelebration()
        }
    }
}

// MARK: - Confetti Particle

private struct WHOOPConfettiParticle: View {
    let color: Color
    let size: CGFloat
    let initialX: CGFloat
    let delay: Double

    @State private var yOffset: CGFloat = -50
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: size, height: size * 1.5)
            .rotationEffect(.degrees(rotation))
            .offset(x: initialX + xOffset, y: yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeOut(duration: Double.random(in: 2.5...4))
                    .delay(delay)
                ) {
                    yOffset = UIScreen.main.bounds.height + 100
                    xOffset = CGFloat.random(in: -100...100)
                    rotation = Double.random(in: 360...720)
                    opacity = 0
                }
            }
    }
}

// MARK: - Celebration View (Complete Wrapper)

struct WHOOPCelebrationView: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showConfetti = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoPulse: CGFloat = 1.0

    init(
        title: String = "You're All Set!",
        subtitle: String = "Your personalized health journey begins now",
        icon: String = "checkmark.circle.fill",
        accentColor: Color = StraynColors.recovery,
        onContinue: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accentColor = accentColor
        self.onContinue = onContinue
    }

    var body: some View {
        ZStack {
            // Confetti
            if showConfetti {
                WHOOPConfetti()
            }

            VStack(spacing: 40) {
                Spacer()

                // Animated icon
                ZStack {
                    // Glow
                    Circle()
                        .fill(accentColor.opacity(0.3))
                        .frame(width: 150, height: 150)
                        .blur(radius: 30)
                        .scaleEffect(logoPulse)

                    // Icon background
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 120, height: 120)

                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(accentColor)
                }
                .scaleEffect(logoScale)

                // Text content
                VStack(spacing: 16) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    Text(subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(StraynColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                .padding(.horizontal, 32)

                Spacer()

                // Continue button
                WHOOPContinueButton(
                    title: "Let's Go",
                    accentColor: accentColor,
                    action: onContinue
                )
                .padding(.horizontal, 32)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            animateEntrance()
        }
    }

    private func animateEntrance() {
        // Logo scale up
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            logoScale = 1.0
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
            logoPulse = 1.15
        }

        // Show confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showConfetti = true
        }

        // Show content
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            showContent = true
        }
    }
}

// MARK: - Success Checkmark Animation

struct WHOOPSuccessCheckmark: View {
    let accentColor: Color

    @State private var showCircle = false
    @State private var showCheck = false
    @State private var pulseScale: CGFloat = 1.0

    init(accentColor: Color = StraynColors.recovery) {
        self.accentColor = accentColor
    }

    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(accentColor.opacity(0.3))
                .frame(width: 100, height: 100)
                .blur(radius: 20)
                .scaleEffect(pulseScale)

            // Circle
            Circle()
                .trim(from: 0, to: showCircle ? 1 : 0)
                .stroke(accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))

            // Checkmark
            if showCheck {
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(accentColor)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            // Draw circle
            withAnimation(.easeOut(duration: 0.5)) {
                showCircle = true
            }

            // Show checkmark
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.4)) {
                showCheck = true
            }

            // Pulse
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.6)) {
                pulseScale = 1.15
            }

            // Haptic
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                HapticsManager.shared.playSuccess()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 60) {
            WHOOPSuccessCheckmark()

            WHOOPCelebrationView(onContinue: {})
        }
    }
}
