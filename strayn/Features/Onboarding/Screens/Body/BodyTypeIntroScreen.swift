//
//  BodyTypeIntroScreen.swift
//  strayn
//
//  Body type intro screen with morphing icon animation.
//

import SwiftUI

struct BodyTypeIntroScreen: View {
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var currentIconIndex = 0
    private let bodyIcons = ["figure.stand", "figure.walk", "figure.run", "figure.strengthtraining.traditional", "figure.arms.open"]

    var body: some View {
        OnboardingInfoScreen(
            icon: bodyIcons[currentIconIndex],
            title: "Body Type Assessment",
            description: "Understanding your body type helps us provide more accurate composition estimates and personalized insights.",
            accentColor: StraynColors.strain,
            showSkipButton: true,
            onSkip: onSkip
        ) {
            VStack(spacing: 24) {
                // Info bullets
                VStack(alignment: .leading, spacing: 12) {
                    infoBullet(icon: "chart.bar.fill", text: "More accurate body composition")
                    infoBullet(icon: "flame.fill", text: "Better calorie recommendations")
                    infoBullet(icon: "figure.run", text: "Personalized activity insights")
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 20)

                // Continue button
                WHOOPContinueButton(
                    title: "Continue",
                    accentColor: StraynColors.strain,
                    action: onContinue
                )
                .padding(.horizontal, 32)
            }
        }
        .onAppear {
            startIconAnimation()
        }
    }

    private func infoBullet(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(StraynColors.strain)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(StraynColors.textSecondary)
        }
    }

    private func startIconAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIconIndex = (currentIconIndex + 1) % bodyIcons.count
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BodyTypeIntroScreen(onContinue: {}, onSkip: {})
}
