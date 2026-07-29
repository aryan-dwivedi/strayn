//
//  SkinCaptureScreen.swift
//  strayn
//
//  Skin capture screen with camera integration.
//

import SwiftUI

struct SkinCaptureScreen: View {
    let region: SkinCaptureRegion
    let onCapture: (Data) -> Void
    let onBack: () -> Void

    @StateObject private var cameraManager = CameraManager()
    @State private var showCountdown = false
    @State private var countdown: Int = 3

    var body: some View {
        ZStack {
            // Camera preview
            if cameraManager.isAuthorized {
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()
            } else {
                cameraUnauthorizedView
            }

            // WHOOP overlay
            WHOOPCameraOverlay(
                title: region.rawValue,
                instructions: region.instructions,
                isValid: cameraManager.isFrameValid,
                validationIssues: cameraManager.currentIssues,
                captureType: .skin(region)
            )

            // Navigation and controls
            VStack {
                // Back button
                HStack {
                    WHOOPBackButton(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                // Capture button
                WHOOPCaptureButton(
                    isEnabled: cameraManager.isFrameValid,
                    onCapture: performCapture
                )
                .padding(.bottom, 60)
            }

            // Countdown overlay
            if showCountdown {
                countdownOverlay
            }
        }
        .onAppear {
            cameraManager.startSession(for: .skin(region))
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }

    private var cameraUnauthorizedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(StraynColors.textSecondary)

            Text("Camera Access Required")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Text("Please enable camera access in Settings to capture skin tone data.")
                .font(.system(size: 14))
                .foregroundColor(StraynColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            Text("\(countdown)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(countdown == 3 ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: countdown)
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

// MARK: - Preview

#Preview {
    SkinCaptureScreen(
        region: .innerForearm,
        onCapture: { _ in },
        onBack: {}
    )
}
