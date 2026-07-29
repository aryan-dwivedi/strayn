//
//  OnboardingView.swift
//  strayn
//
//  Premium multi-step onboarding with particle animations, typing effects, and gamification.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isFirstRun: Bool
    @State private var currentStep = 0
    @State private var selectedGoal: GoalType?
    @State private var notificationsEnabled = true
    @State private var showParticles = true
    @State private var animateItems = false
    @State private var typingText = ""
    @State private var countdownValue = 3
    @State private var showCountdown = false

    private let totalSteps = 5

    var body: some View {
        ZStack {
            // Animated background with particles
            backgroundLayer

            // Particle overlay
            if showParticles {
                ParticleEmitterView()
                    .opacity(0.6)
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // Progress bar
                progressBar
                    .padding(.top, StraynSpacing.lg)

                Spacer()

                // Step content
                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                Spacer()

                // Navigation button
                navigationButton
                    .padding(.bottom, StraynSpacing.xxl)
            }

            // Countdown overlay
            if showCountdown {
                countdownOverlay
            }
        }
        .onAppear {
            startWelcomeAnimation()
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            StraynColors.premiumBackgroundGradient
                .ignoresSafeArea()

            // Animated gradient orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [StraynColors.accentPrimary.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -100, y: -300)
                .blur(radius: 60)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [StraynColors.sleep.opacity(0.2), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: 150, y: 400)
                .blur(radius: 50)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ?
                          LinearGradient(colors: [StraynColors.accentPrimary, StraynColors.zoneGreen],
                                         startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [StraynColors.surfaceSecondary, StraynColors.surfaceSecondary],
                                           startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 4)
                    .animation(.spring(response: 0.4), value: currentStep)
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0: welcomeStep
        case 1: goalSelectionStep
        case 2: baselineExplanationStep
        case 3: healthKitStep
        case 4: completionStep
        default: EmptyView()
        }
    }

    // MARK: - Navigation Button

    private var navigationButton: some View {
        Button(action: nextStep) {
            HStack(spacing: 12) {
                Text(buttonTitle)
                    .font(StraynTypography.labelLarge(.bold))

                Image(systemName: currentStep == totalSteps - 1 ? "sparkles" : "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: StraynColors.accentPrimary.opacity(0.4), radius: 20, x: 0, y: 10)
            )
        }
        .padding(.horizontal, 40)
        .disabled(currentStep == 1 && selectedGoal == nil)
        .opacity(currentStep == 1 && selectedGoal == nil ? 0.5 : 1.0)
        .scaleEffect(animateItems ? 1.0 : 0.9)
        .animation(.spring(response: 0.5).delay(0.3), value: animateItems)
    }

    private var buttonTitle: String {
        switch currentStep {
        case 0: return "GET STARTED"
        case 1: return "CONTINUE"
        case 2: return "UNDERSTOOD"
        case 3: return "GRANT ACCESS"
        case 4: return "BEGIN JOURNEY"
        default: return "CONTINUE"
        }
    }

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        VStack(spacing: StraynSpacing.xl) {
            // Animated logo
            ZStack {
                // Pulsing rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(StraynColors.accentPrimary.opacity(0.2 - Double(i) * 0.05), lineWidth: 2)
                        .frame(width: CGFloat(140 + i * 40), height: CGFloat(140 + i * 40))
                        .scaleEffect(animateItems ? 1.0 : 0.8)
                        .opacity(animateItems ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 1.0).delay(Double(i) * 0.15), value: animateItems)
                }

                // Main logo circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [StraynColors.accentPrimary, StraynColors.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: StraynColors.accentPrimary.opacity(0.5), radius: 30)
                    .scaleEffect(animateItems ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateItems)

                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(animateItems ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateItems)
            }

            VStack(spacing: StraynSpacing.md) {
                // Brand name with letter animation
                Text("STRAYN")
                    .font(.system(size: 16, weight: .black))
                    .tracking(12)
                    .foregroundColor(StraynColors.accentPrimary)
                    .opacity(animateItems ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: animateItems)

                // Typing effect tagline
                Text(typingText)
                    .font(StraynTypography.displaySmall())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(height: 80)

                Text("Unlock the secrets of your autonomic nervous system through deep physiological modeling.")
                    .font(StraynTypography.bodyMedium)
                    .foregroundColor(StraynColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(animateItems ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(1.5), value: animateItems)
            }

            // Feature previews
            featurePreviewGrid
                .opacity(animateItems ? 1.0 : 0.0)
                .offset(y: animateItems ? 0 : 30)
                .animation(.spring(response: 0.6).delay(1.8), value: animateItems)
        }
    }

    private var featurePreviewGrid: some View {
        HStack(spacing: StraynSpacing.md) {
            featureChip(icon: "heart.fill", label: "Recovery")
            featureChip(icon: "flame.fill", label: "Strain")
            featureChip(icon: "moon.fill", label: "Sleep")
            featureChip(icon: "sparkles", label: "Bio Age")
        }
        .padding(.top, StraynSpacing.lg)
    }

    private func featureChip(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(StraynColors.accentPrimary)

            Text(label)
                .font(StraynTypography.labelSmall())
                .foregroundColor(StraynColors.textSecondary)
        }
        .frame(width: 70)
    }

    // MARK: - Goal Selection Step

    private var goalSelectionStep: some View {
        VStack(spacing: StraynSpacing.xl) {
            VStack(spacing: StraynSpacing.sm) {
                Text("What's Your Focus?")
                    .font(StraynTypography.displaySmall())
                    .foregroundColor(.white)

                Text("We'll personalize your experience and insights")
                    .font(StraynTypography.bodyMedium)
                    .foregroundColor(StraynColors.textSecondary)
            }

            VStack(spacing: StraynSpacing.md) {
                ForEach(Array(GoalType.allCases.enumerated()), id: \.element.id) { index, goal in
                    goalCard(goal: goal, index: index)
                }
            }
            .padding(.horizontal)
        }
    }

    private func goalCard(goal: GoalType, index: Int) -> some View {
        Button(action: {
            HapticsManager.shared.playSelection()
            withAnimation(.spring(response: 0.3)) {
                selectedGoal = goal
                GoalEngine.shared.selectedGoal = goal
            }
        }) {
            HStack(spacing: StraynSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(selectedGoal == goal ?
                              LinearGradient(colors: [StraynColors.accentPrimary, StraynColors.accentSecondary],
                                             startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [StraynColors.surfaceSecondary, StraynColors.surfaceSecondary],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: goal.icon)
                        .font(.system(size: 24))
                        .foregroundColor(selectedGoal == goal ? .white : StraynColors.textSecondary)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(StraynTypography.headlineSmall())
                        .foregroundColor(.white)

                    Text(goal.description)
                        .font(StraynTypography.labelSmall())
                        .foregroundColor(StraynColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(selectedGoal == goal ? StraynColors.accentPrimary : StraynColors.borderSubtle, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if selectedGoal == goal {
                        Circle()
                            .fill(StraynColors.accentPrimary)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(StraynSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.xl)
                    .fill(selectedGoal == goal ? StraynColors.accentPrimary.opacity(0.1) : StraynColors.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StraynRadius.xl)
                    .stroke(selectedGoal == goal ? StraynColors.accentPrimary : StraynColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(selectedGoal == goal ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: selectedGoal)
    }

    // MARK: - Baseline Explanation Step

    private var baselineExplanationStep: some View {
        VStack(spacing: StraynSpacing.xl) {
            // Animated chart icon
            ZStack {
                Circle()
                    .fill(StraynColors.biologicalAge.opacity(0.15))
                    .frame(width: 160, height: 160)

                Circle()
                    .stroke(StraynColors.biologicalAge.opacity(0.3), lineWidth: 3)
                    .frame(width: 160, height: 160)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 70))
                    .foregroundColor(StraynColors.biologicalAge)
                    .symbolEffect(.pulse)
            }

            VStack(spacing: StraynSpacing.md) {
                Text("30-Day Baseline")
                    .font(StraynTypography.displaySmall())
                    .foregroundColor(.white)

                Text("For the first 30 days, we'll calibrate your unique physiological baseline. This allows us to detect meaningful changes in your health.")
                    .font(StraynTypography.bodyMedium)
                    .foregroundColor(StraynColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Baseline metrics
            VStack(spacing: StraynSpacing.sm) {
                baselineMetricRow(icon: "waveform.path.ecg", title: "HRV Baseline", description: "Your heart rate variability patterns")
                baselineMetricRow(icon: "heart.fill", title: "Resting HR", description: "Your average resting heart rate")
                baselineMetricRow(icon: "moon.fill", title: "Sleep Patterns", description: "Your sleep architecture and efficiency")
                baselineMetricRow(icon: "lungs.fill", title: "Respiratory Rate", description: "Your breathing during sleep")
            }
            .padding(.horizontal)
        }
    }

    private func baselineMetricRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: StraynSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(StraynColors.accentPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(StraynTypography.labelMedium(.semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(StraynTypography.labelSmall())
                    .foregroundColor(StraynColors.textMuted)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(StraynColors.zoneGreen)
        }
        .padding(StraynSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: StraynRadius.lg)
                .fill(StraynColors.surfacePrimary)
        )
    }

    // MARK: - HealthKit Step

    private var healthKitStep: some View {
        VStack(spacing: StraynSpacing.xl) {
            // Animated heart
            ZStack {
                // Pulse rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.red.opacity(0.2 - Double(i) * 0.05), lineWidth: 2)
                        .frame(width: CGFloat(140 + i * 30), height: CGFloat(140 + i * 30))
                        .scaleEffect(animateItems ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                            value: animateItems
                        )
                }

                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: StraynSpacing.md) {
                Text("Connect Health Data")
                    .font(StraynTypography.displaySmall())
                    .foregroundColor(.white)

                Text("Strayn syncs with Apple Health to analyze your HRV, Sleep, Heart Rate, and VO2 Max to calculate your Biological Age.")
                    .font(StraynTypography.bodyMedium)
                    .foregroundColor(StraynColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Privacy badges
            VStack(spacing: StraynSpacing.sm) {
                privacyBadge(icon: "lock.fill", text: "End-to-end encrypted")
                privacyBadge(icon: "eye.slash.fill", text: "Never sold or shared")
                privacyBadge(icon: "iphone", text: "Processed on-device")
            }
        }
    }

    private func privacyBadge(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(StraynColors.zoneGreen)

            Text(text)
                .font(StraynTypography.labelMedium())
                .foregroundColor(StraynColors.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(StraynColors.zoneGreen.opacity(0.1))
        )
    }

    // MARK: - Completion Step

    private var completionStep: some View {
        VStack(spacing: StraynSpacing.xl) {
            // Celebration animation
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [StraynColors.accentPrimary.opacity(0.3), StraynColors.zoneGreen.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: CGFloat(100 + i * 30), height: CGFloat(100 + i * 30))
                        .rotationEffect(.degrees(Double(i) * 15))
                        .scaleEffect(animateItems ? 1.0 : 0.8)
                        .opacity(animateItems ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6).delay(Double(i) * 0.1), value: animateItems)
                }

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [StraynColors.accentPrimary, StraynColors.zoneGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: StraynColors.zoneGreen.opacity(0.5), radius: 30)

                Image(systemName: "checkmark")
                    .font(.system(size: 45, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: StraynSpacing.md) {
                Text("You're All Set!")
                    .font(StraynTypography.displaySmall())
                    .foregroundColor(.white)

                if let goal = selectedGoal {
                    Text("Your journey to \(goal.title.lowercased()) begins now.")
                        .font(StraynTypography.bodyMedium)
                        .foregroundColor(StraynColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            // First insights preview
            VStack(spacing: StraynSpacing.sm) {
                Text("COMING UP")
                    .font(StraynTypography.metricLabel)
                    .tracking(StraynTypography.metricLabelTracking)
                    .foregroundColor(StraynColors.textTertiary)

                VStack(spacing: 8) {
                    insightPreviewRow(icon: "sunrise.fill", text: "Morning recovery score", color: StraynColors.recovery)
                    insightPreviewRow(icon: "flame.fill", text: "Daily strain tracking", color: StraynColors.strain)
                    insightPreviewRow(icon: "brain.head.profile", text: "AI-powered insights", color: StraynColors.accentPrimary)
                }
            }
            .padding(StraynSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.xl)
                    .fill(StraynColors.surfacePrimary)
            )
            .padding(.horizontal)
        }
    }

    private func insightPreviewRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(StraynTypography.bodyMedium)
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(StraynColors.textMuted)
        }
    }

    // MARK: - Countdown Overlay

    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: StraynSpacing.xl) {
                Text("\(countdownValue)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(countdownValue > 0 ? 1.0 : 0.5)
                    .animation(.spring(response: 0.3), value: countdownValue)

                Text("Initializing your Biological OS...")
                    .font(StraynTypography.bodyMedium)
                    .foregroundColor(StraynColors.textSecondary)
            }
        }
    }

    // MARK: - Actions

    private func startWelcomeAnimation() {
        animateItems = true

        // Start typing effect
        let fullText = "The Biological OS"
        typingText = ""

        for (index, character) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 + Double(index) * 0.05) {
                typingText += String(character)

                if index == fullText.count - 1 {
                    HapticsManager.shared.playSuccess()
                }
            }
        }
    }

    private func nextStep() {
        HapticsManager.shared.playImpact(.medium)

        if currentStep < totalSteps - 1 {
            withAnimation(.spring(response: 0.5)) {
                currentStep += 1
            }
        } else {
            // Final step - show countdown then complete
            startCountdown()
        }
    }

    private func startCountdown() {
        showCountdown = true
        countdownValue = 3

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            HapticsManager.shared.playImpact(.light)

            if countdownValue > 1 {
                countdownValue -= 1
            } else {
                timer.invalidate()
                HapticsManager.shared.playSuccess()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFirstRun = false
                }
            }
        }
    }
}

// MARK: - Particle Emitter View

struct ParticleEmitterView: View {
    @State private var particles: [Particle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .blur(radius: particle.size / 4)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles()
            }
        }
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<30).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                color: [StraynColors.accentPrimary, StraynColors.sleep, StraynColors.recovery].randomElement()!,
                size: CGFloat.random(in: 4...12),
                opacity: Double.random(in: 0.2...0.6),
                velocity: CGPoint(
                    x: CGFloat.random(in: -0.3...0.3),
                    y: CGFloat.random(in: -0.5...0)
                )
            )
        }
    }

    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x
                particles[i].position.y += particles[i].velocity.y

                // Wrap around edges
                if particles[i].position.y < -20 {
                    particles[i].position.y = UIScreen.main.bounds.height + 20
                    particles[i].position.x = CGFloat.random(in: 0...UIScreen.main.bounds.width)
                }
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
    var velocity: CGPoint
}

// MARK: - Preview

#Preview {
    OnboardingView(isFirstRun: .constant(true))
}
