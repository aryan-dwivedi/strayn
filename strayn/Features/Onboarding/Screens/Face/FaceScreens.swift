//
//  FaceScreens.swift
//  strayn
//
//  Face analysis screens - intro, capture, processing, result.
//

import SwiftUI

// MARK: - Face Intro Screen

struct FaceIntroScreen: View {
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        OnboardingInfoScreen(
            icon: "face.smiling",
            title: "Face Analysis",
            description: "We'll capture your face to establish baseline markers for biological age tracking and skin health.",
            accentColor: StraynColors.recovery,
            showSkipButton: true,
            onSkip: onSkip
        ) {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    infoBullet(icon: "sparkles", text: "Skin texture analysis")
                    infoBullet(icon: "eyes", text: "Under-eye assessment")
                    infoBullet(icon: "lock.shield.fill", text: "Processed locally, never uploaded")
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 20)

                WHOOPContinueButton(
                    title: "Start Face Scan",
                    accentColor: StraynColors.recovery,
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
                .foregroundColor(StraynColors.recovery)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(StraynColors.textSecondary)
        }
    }
}

// MARK: - Face Capture Screen

struct FaceCaptureScreen: View {
    let captureType: FaceCaptureType
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
                captureType: .face(captureType)
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
            cameraManager.startSession(for: .face(captureType))
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

// MARK: - Face Processing Screen

struct FaceProcessingScreen: View {
    let progress: Double

    var body: some View {
        VStack {
            Spacer()

            WHOOPProcessingRing(
                title: "Analyzing Face...",
                subtitle: "Establishing baseline markers",
                accentColor: StraynColors.recovery
            )

            Spacer()

            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(StraynColors.surfaceSecondary)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(StraynColors.recovery)
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

// MARK: - Face Result Screen

struct FaceResultScreen: View {
    let onContinue: () -> Void

    @State private var showContent = false

    var body: some View {
        OnboardingResultScreen(
            title: "Face Analysis Complete",
            subtitle: "Baseline established successfully",
            onContinue: onContinue
        ) {
            VStack(spacing: 24) {
                WHOOPSuccessCheckmark(accentColor: StraynColors.recovery)
                    .opacity(showContent ? 1 : 0)

                VStack(spacing: 16) {
                    resultItem(icon: "checkmark.circle.fill", title: "Skin texture captured", color: StraynColors.zoneGreen)
                    resultItem(icon: "checkmark.circle.fill", title: "Under-eye baseline set", color: StraynColors.zoneGreen)
                    resultItem(icon: "checkmark.circle.fill", title: "Face geometry recorded", color: StraynColors.zoneGreen)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                showContent = true
            }
        }
    }

    private func resultItem(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 15))
                .foregroundColor(StraynColors.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Previews

#Preview("Intro") {
    FaceIntroScreen(onContinue: {}, onSkip: {})
}

#Preview("Processing") {
    FaceProcessingScreen(progress: 0.6)
}

#Preview("Result") {
    FaceResultScreen(onContinue: {})
}
