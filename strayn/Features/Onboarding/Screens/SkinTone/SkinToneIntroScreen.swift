//
//  SkinToneIntroScreen.swift
//  strayn
//
//  Skin tone analysis intro screen with Fitzpatrick scale reveal.
//

import SwiftUI

struct SkinToneIntroScreen: View {
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var showScale = false

    var body: some View {
        OnboardingInfoScreen(
            icon: "paintpalette.fill",
            title: "Skin Tone Analysis",
            description: "We'll capture three photos to accurately determine your Fitzpatrick skin type for UV sensitivity insights.",
            accentColor: StraynColors.biologicalAge,
            showSkipButton: true,
            onSkip: onSkip
        ) {
            VStack(spacing: 24) {
                // Fitzpatrick scale preview
                HStack(spacing: 8) {
                    ForEach(FitzpatrickSkinType.allCases) { type in
                        Circle()
                            .fill(type.color)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .scaleEffect(showScale ? 1 : 0.5)
                            .opacity(showScale ? 1 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(type.rawValue) * 0.1),
                                value: showScale
                            )
                    }
                }
                .padding(.top, 8)

                // Capture regions
                VStack(spacing: 12) {
                    captureStep(1, region: "Inner forearm", icon: "hand.raised.fill")
                    captureStep(2, region: "Lower leg", icon: "figure.stand")
                    captureStep(3, region: "Abdomen", icon: "figure.arms.open")
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)

                Spacer().frame(height: 20)

                // Continue button
                WHOOPContinueButton(
                    title: "Start Capture",
                    accentColor: StraynColors.biologicalAge,
                    action: onContinue
                )
                .padding(.horizontal, 32)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3).delay(0.3)) {
                showScale = true
            }
        }
    }

    private func captureStep(_ number: Int, region: String, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(StraynColors.surfacePrimary)
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(StraynColors.biologicalAge)
                .frame(width: 24)

            Text(region)
                .font(.system(size: 15))
                .foregroundColor(StraynColors.textSecondary)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    SkinToneIntroScreen(onContinue: {}, onSkip: {})
}
