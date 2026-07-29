//
//  WHOOPToggle.swift
//  strayn
//
//  WHOOP-style toggle switch for consent screens.
//

import SwiftUI

struct WHOOPToggle: View {
    @Binding var isOn: Bool
    let title: String
    let description: String?
    let isRequired: Bool
    let accentColor: Color

    init(
        isOn: Binding<Bool>,
        title: String,
        description: String? = nil,
        isRequired: Bool = false,
        accentColor: Color = StraynColors.accentPrimary
    ) {
        self._isOn = isOn
        self.title = title
        self.description = description
        self.isRequired = isRequired
        self.accentColor = accentColor
    }

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 16) {
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)

                        if isRequired {
                            Text("Required")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(accentColor.opacity(0.2))
                                )
                        }
                    }

                    if let description = description {
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundColor(StraynColors.textSecondary)
                            .lineLimit(3)
                    }
                }

                Spacer()

                // Toggle switch
                toggleSwitch
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(StraynColors.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isOn ? accentColor.opacity(0.3) : StraynColors.borderSubtle, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var toggleSwitch: some View {
        ZStack {
            // Track
            Capsule()
                .fill(isOn ? accentColor : StraynColors.surfaceSecondary)
                .frame(width: 52, height: 32)

            // Thumb
            Circle()
                .fill(Color.white)
                .frame(width: 26, height: 26)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                .offset(x: isOn ? 10 : -10)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
    }

    private func toggle() {
        isOn.toggle()
        HapticsManager.shared.playToggle()
    }
}

// MARK: - Consent Toggle Group

struct WHOOPConsentGroup: View {
    @Binding var cameraConsent: Bool
    @Binding var healthDataConsent: Bool
    @Binding var aiInsightsConsent: Bool
    @Binding var secureProcessingAck: Bool
    @Binding var termsAccepted: Bool
    @Binding var privacyAccepted: Bool

    var allAccepted: Bool {
        cameraConsent && healthDataConsent && aiInsightsConsent &&
        secureProcessingAck && termsAccepted && privacyAccepted
    }

    var body: some View {
        VStack(spacing: 12) {
            WHOOPToggle(
                isOn: $cameraConsent,
                title: "Camera Analysis",
                description: "Allow Strayn to use camera for biometric captures and real-time analysis.",
                isRequired: true
            )

            WHOOPToggle(
                isOn: $healthDataConsent,
                title: "Health Data Processing",
                description: "Process HealthKit data for personalized recovery insights.",
                isRequired: true
            )

            WHOOPToggle(
                isOn: $aiInsightsConsent,
                title: "AI-Powered Insights",
                description: "Enable AI analysis for coaching recommendations and biological age.",
                isRequired: true
            )

            WHOOPToggle(
                isOn: $secureProcessingAck,
                title: "Secure On-Device Processing",
                description: "Acknowledge that biometric data is processed locally and never uploaded.",
                isRequired: true
            )

            WHOOPToggle(
                isOn: $termsAccepted,
                title: "Terms of Service",
                description: "I agree to the Strayn Terms of Service.",
                isRequired: true
            )

            WHOOPToggle(
                isOn: $privacyAccepted,
                title: "Privacy Policy",
                description: "I have read and accept the Privacy Policy.",
                isRequired: true
            )
        }
    }
}

// MARK: - Grant All Button

struct WHOOPGrantAllButton: View {
    let onGrantAll: () -> Void

    var body: some View {
        Button(action: {
            HapticsManager.shared.playSuccess()
            onGrantAll()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 18, weight: .semibold))

                Text("Accept All")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(StraynColors.accentPrimary)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(StraynColors.accentPrimary.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(StraynColors.accentPrimary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 20) {
                WHOOPToggle(
                    isOn: .constant(true),
                    title: "Camera Access",
                    description: "Allow camera access for biometric captures.",
                    isRequired: true
                )

                WHOOPToggle(
                    isOn: .constant(false),
                    title: "Marketing Emails",
                    description: "Receive updates about new features.",
                    isRequired: false
                )

                WHOOPGrantAllButton(onGrantAll: {})
            }
            .padding()
        }
    }
}
