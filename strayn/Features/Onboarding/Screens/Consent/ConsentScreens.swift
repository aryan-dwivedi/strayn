//
//  ConsentScreens.swift
//  strayn
//
//  Privacy and consent screens - summary, toggles, completion.
//

import SwiftUI

// MARK: - Privacy Summary Screen

struct PrivacySummaryScreen: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var showContent = false

    var body: some View {
        OnboardingScreenContainer(
            title: "Your Privacy",
            subtitle: "How we protect your data",
            showBackButton: true,
            onBack: onBack
        ) {
            VStack(spacing: 0) {
                Spacer().frame(height: 32)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        privacyItem(
                            icon: "iphone",
                            title: "On-Device Processing",
                            description: "All biometric analysis happens locally on your device. Your photos are never uploaded to our servers.",
                            delay: 0
                        )

                        privacyItem(
                            icon: "lock.shield.fill",
                            title: "Encrypted Storage",
                            description: "Health data is stored using iOS Keychain and encrypted with your device's secure enclave.",
                            delay: 0.1
                        )

                        privacyItem(
                            icon: "hand.raised.fill",
                            title: "You're In Control",
                            description: "Delete your data anytime from Settings. We never sell or share your personal information.",
                            delay: 0.2
                        )

                        privacyItem(
                            icon: "checkmark.seal.fill",
                            title: "HIPAA Compliant",
                            description: "Our security practices meet healthcare industry standards for data protection.",
                            delay: 0.3
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                Spacer()

                WHOOPContinueButton(
                    title: "Review Permissions",
                    action: onContinue
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                showContent = true
            }
        }
    }

    private func privacyItem(icon: String, title: String, description: String, delay: Double) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(StraynColors.recovery.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(StraynColors.recovery)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(StraynColors.textSecondary)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(StraynColors.surfacePrimary)
        )
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: showContent)
    }
}

// MARK: - Consent Toggles Screen

struct ConsentTogglesScreen: View {
    @Binding var cameraConsent: Bool
    @Binding var healthDataConsent: Bool
    @Binding var aiInsightsConsent: Bool
    @Binding var secureProcessingAck: Bool
    @Binding var termsAccepted: Bool
    @Binding var privacyAccepted: Bool
    let onContinue: () -> Void
    let onBack: () -> Void
    let onGrantAll: () -> Void

    var allConsentsGranted: Bool {
        cameraConsent && healthDataConsent && aiInsightsConsent &&
        secureProcessingAck && termsAccepted && privacyAccepted
    }

    var body: some View {
        OnboardingScreenContainer(
            title: "Permissions",
            subtitle: "Grant access to enable full functionality",
            showBackButton: true,
            onBack: onBack
        ) {
            VStack(spacing: 0) {
                // Grant all button
                if !allConsentsGranted {
                    WHOOPGrantAllButton(onGrantAll: onGrantAll)
                        .padding(.top, 16)
                }

                Spacer().frame(height: 24)

                ScrollView(showsIndicators: false) {
                    WHOOPConsentGroup(
                        cameraConsent: $cameraConsent,
                        healthDataConsent: $healthDataConsent,
                        aiInsightsConsent: $aiInsightsConsent,
                        secureProcessingAck: $secureProcessingAck,
                        termsAccepted: $termsAccepted,
                        privacyAccepted: $privacyAccepted
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                Spacer()

                WHOOPContinueButton(
                    title: "Complete Setup",
                    isEnabled: allConsentsGranted,
                    action: onContinue
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Completion Screen

struct CompletionScreen: View {
    let onComplete: () -> Void

    var body: some View {
        WHOOPCelebrationView(
            title: "You're All Set!",
            subtitle: "Your personalized Biological OS is ready. Let's optimize your health together.",
            icon: "checkmark.circle.fill",
            accentColor: StraynColors.recovery,
            onContinue: onComplete
        )
    }
}

// MARK: - Previews

#Preview("Privacy Summary") {
    PrivacySummaryScreen(onContinue: {}, onBack: {})
}

#Preview("Consent Toggles") {
    ConsentTogglesScreen(
        cameraConsent: .constant(true),
        healthDataConsent: .constant(true),
        aiInsightsConsent: .constant(false),
        secureProcessingAck: .constant(false),
        termsAccepted: .constant(false),
        privacyAccepted: .constant(false),
        onContinue: {},
        onBack: {},
        onGrantAll: {}
    )
}

#Preview("Completion") {
    CompletionScreen(onComplete: {})
}
