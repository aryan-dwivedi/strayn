//
//  WeightInputScreen.swift
//  strayn
//
//  Weight input screen with WHOOP-style scroll wheel and BMI preview.
//

import SwiftUI

struct WeightInputScreen: View {
    @Binding var weightKg: Double
    let heightCm: Int
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var displayWeight: Double = 70.0
    @State private var useImperial = false

    private var weightInLbs: Double {
        displayWeight * 2.20462
    }

    private var bmi: Double {
        let heightM = Double(heightCm) / 100
        return displayWeight / (heightM * heightM)
    }

    private var bmiCategory: (name: String, color: Color) {
        switch bmi {
        case ..<18.5:
            return ("Underweight", StraynColors.zoneYellow)
        case 18.5..<25:
            return ("Normal", StraynColors.zoneGreen)
        case 25..<30:
            return ("Overweight", StraynColors.zoneYellow)
        default:
            return ("Obese", StraynColors.zoneRed)
        }
    }

    var body: some View {
        OnboardingScreenContainer(
            title: "Your weight",
            subtitle: "Used for metabolic calculations",
            showBackButton: true,
            onBack: onBack
        ) {
            VStack(spacing: 0) {
                Spacer()

                // Large weight display
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(useImperial ? String(format: "%.0f", weightInLbs) : String(format: "%.1f", displayWeight))
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [StraynColors.accentPrimary, StraynColors.accentPrimary.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: displayWeight)

                        Text(useImperial ? "lbs" : "kg")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(StraynColors.textSecondary)
                    }

                    // BMI preview
                    HStack(spacing: 8) {
                        Text("BMI")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(StraynColors.textTertiary)

                        Text(String(format: "%.1f", bmi))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("·")
                            .foregroundColor(StraynColors.textMuted)

                        Text(bmiCategory.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(bmiCategory.color)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(StraynColors.surfacePrimary)
                    )
                }

                // Unit toggle
                HStack(spacing: 0) {
                    unitButton("kg", selected: !useImperial) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            useImperial = false
                        }
                    }

                    unitButton("lbs", selected: useImperial) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            useImperial = true
                        }
                    }
                }
                .padding(.top, 24)

                Spacer().frame(height: 40)

                // Scroll wheel
                WHOOPScrollWheelDouble(
                    value: $displayWeight,
                    range: 30...200,
                    suffix: "kg",
                    step: 0.5
                )
                .frame(height: 160)
                .padding(.horizontal, 24)

                Spacer()

                // Continue button
                WHOOPContinueButton(
                    isEnabled: displayWeight >= 30 && displayWeight <= 200,
                    action: {
                        weightKg = displayWeight
                        onContinue()
                    }
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            displayWeight = weightKg
        }
    }

    private func unitButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticsManager.shared.playSelection()
            action()
        }) {
            Text(title)
                .font(.system(size: 14, weight: selected ? .bold : .medium))
                .foregroundColor(selected ? .black : StraynColors.textSecondary)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(selected ? Color.white : StraynColors.surfacePrimary)
                )
        }
    }
}

// MARK: - Preview

#Preview {
    WeightInputScreen(
        weightKg: .constant(70.0),
        heightCm: 170,
        onContinue: {},
        onBack: {}
    )
}
