//
//  HairScreens.swift
//  strayn
//
//  Hair analysis screens - intro, captures, processing, result.
//

import SwiftUI

// MARK: - Hair Intro Screen

struct HairIntroScreen: View {
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        OnboardingInfoScreen(
            icon: "scissors",
            title: "Hair Analysis",
            description: "We'll capture your hairline and scalp to establish baseline density metrics.",
            accentColor: StraynColors.hrv,
            showSkipButton: true,
            onSkip: onSkip
        ) {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    infoBullet(icon: "camera.fill", text: "Frontal hairline photo")
                    infoBullet(icon: "camera.fill", text: "Crown/scalp photo")
                    infoBullet(icon: "chart.line.uptrend.xyaxis", text: "Track changes over time")
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 20)

                WHOOPContinueButton(
                    title: "Start Hair Capture",
                    accentColor: StraynColors.hrv,
                    action: onContinue
                )
                .padding(.horizontal, 32)
            }
        }
    }

    private func infoBullet(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(StraynColors.hrv)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(StraynColors.textSecondary)
        }
    }
}

// MARK: - Hair Capture Screen

struct HairCaptureScreen: View {
    let captureType: HairCaptureType
    let onCapture: (Data) -> Void
    let onBack: () -> Void

    @StateObject private var cameraManager = CameraManager()
    @State private var showCountdown = false
    @State private var countdown: Int = 3

    var body: some View {
        ZStack {
            if cameraManager.isAuthorized {
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()
            }

            WHOOPCameraOverlay(
                title: captureType.rawValue,
                instructions: captureType.instructions,
                isValid: cameraManager.isFrameValid,
                validationIssues: cameraManager.currentIssues,
                captureType: .hair(captureType)
            )

            VStack {
                HStack {
                    WHOOPBackButton(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                WHOOPCaptureButton(
                    isEnabled: cameraManager.isFrameValid,
                    onCapture: performCapture
                )
                .padding(.bottom, 60)
            }

            if showCountdown {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    Text("\(countdown)")
                        .font(.system(size: 120, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            cameraManager.startSession(for: .hair(captureType))
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }

    private func performCapture() {
        showCountdown = true
        countdown = 3

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 1 {
                countdown -= 1
                HapticsManager.shared.playImpact(.light)
            } else {
                timer.invalidate()
                showCountdown = false
                cameraManager.capturePhoto { data in
                    if let data = data {
                        HapticsManager.shared.playSuccess()
                        onCapture(data)
                    }
                }
            }
        }
    }
}

// MARK: - Hair Processing Screen

struct HairProcessingScreen: View {
    let progress: Double

    var body: some View {
        VStack {
            Spacer()

            WHOOPProcessingRing(
                title: "Analyzing Hair Density...",
                subtitle: "Establishing baseline metrics",
                accentColor: StraynColors.hrv
            )

            Spacer()

            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(StraynColors.surfaceSecondary)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(StraynColors.hrv)
                            .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                    }
                }
                .frame(height: 8)

                Text("\(Int(progress * 100))% complete")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(StraynColors.textSecondary)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 80)
        }
        .background(Color.black)
    }
}

// MARK: - Hair Result Screen

struct HairResultScreen: View {
    let densityScore: Double?
    let thinningIndicator: ThinningIndicator?
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var animatedDensity: Double = 0

    var body: some View {
        OnboardingResultScreen(
            title: "Hair Analysis Complete",
            subtitle: "Your baseline has been established",
            onContinue: onContinue
        ) {
            VStack(spacing: 32) {
                // Density ring
                ZStack {
                    Circle()
                        .stroke(StraynColors.surfaceSecondary, lineWidth: 12)
                        .frame(width: 140, height: 140)

                    Circle()
                        .trim(from: 0, to: animatedDensity)
                        .stroke(StraynColors.hrv, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 4) {
                        Text("\(Int(animatedDensity * 100))")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())

                        Text("Density")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(StraynColors.textSecondary)
                    }
                }
                .opacity(showContent ? 1 : 0)

                // Thinning status
                if let thinning = thinningIndicator {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(thinning.color)
                            .frame(width: 12, height: 12)

                        Text(thinning.rawValue)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(StraynColors.surfacePrimary)
                    )
                    .opacity(showContent ? 1 : 0)
                }

                Text("We'll track changes over time to provide insights on hair health trends.")
                    .font(.system(size: 14))
                    .foregroundColor(StraynColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                showContent = true
            }

            withAnimation(.easeOut(duration: 1.5).delay(0.5)) {
                animatedDensity = densityScore ?? 0.75
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                HapticsManager.shared.playScoreReveal()
            }
        }
    }
}

// MARK: - Previews

#Preview("Intro") {
    HairIntroScreen(onContinue: {}, onSkip: {})
}

#Preview("Processing") {
    HairProcessingScreen(progress: 0.6)
}

#Preview("Result") {
    HairResultScreen(densityScore: 0.82, thinningIndicator: .none, onContinue: {})
}
