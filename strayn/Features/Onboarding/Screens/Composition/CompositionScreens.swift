//
//  CompositionScreens.swift
//  strayn
//
//  Body composition processing and result screens.
//

import SwiftUI

// MARK: - Composition Processing Screen

struct CompositionProcessingScreen: View {
    let progress: Double

    var body: some View {
        VStack {
            Spacer()

            WHOOPProcessingRing(
                title: "Analyzing Your Data...",
                subtitle: "Combining biometrics with profile data",
                accentColor: StraynColors.strain
            )

            Spacer()

            // Analysis steps
            VStack(alignment: .leading, spacing: 16) {
                analysisStep("Profile data", progress >= 0.2)
                analysisStep("Skin analysis", progress >= 0.4)
                analysisStep("Face metrics", progress >= 0.6)
                analysisStep("Hair density", progress >= 0.8)
                analysisStep("Final composition", progress >= 1.0)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)

            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(StraynColors.surfaceSecondary)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(StraynColors.strain)
                            .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .background(Color.black)
    }

    private func analysisStep(_ title: String, _ completed: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundColor(completed ? StraynColors.zoneGreen : StraynColors.textMuted)

            Text(title)
                .font(.system(size: 14, weight: completed ? .semibold : .regular))
                .foregroundColor(completed ? .white : StraynColors.textSecondary)
        }
    }
}

// MARK: - Composition Result Screen

struct CompositionResultScreen: View {
    let bodyFatCategory: BodyFatCategory
    let muscleSignal: MuscleSignal
    let waterRetention: WaterRetentionLevel
    let confidence: Double
    let onContinue: () -> Void

    @State private var showContent = false

    var body: some View {
        OnboardingResultScreen(
            title: "Body Composition",
            subtitle: "AI-estimated from your biometric data",
            onContinue: onContinue
        ) {
            VStack(spacing: 20) {
                WHOOPCompositionResult(
                    bodyFatCategory: bodyFatCategory,
                    muscleSignal: muscleSignal,
                    waterRetention: waterRetention,
                    confidence: confidence
                )
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)

                // Disclaimer
                Text(BodyCompositionEstimate.disclaimer)
                    .font(.system(size: 11))
                    .foregroundColor(StraynColors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                showContent = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Processing") {
    CompositionProcessingScreen(progress: 0.6)
}

#Preview("Result") {
    CompositionResultScreen(
        bodyFatCategory: .moderate,
        muscleSignal: .medium,
        waterRetention: .moderate,
        confidence: 0.85,
        onContinue: {}
    )
}
