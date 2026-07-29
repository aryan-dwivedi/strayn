//
//  HeightInputScreen.swift
//  strayn
//
//  Height input screen with WHOOP-style scroll wheel and unit toggle.
//

import SwiftUI

struct HeightInputScreen: View {
    @Binding var heightCm: Int
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var displayHeight: Int = 170
    @State private var useImperial = false

    private var heightInFeet: (feet: Int, inches: Int) {
        let totalInches = Double(displayHeight) / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return (feet, inches)
    }

    private var displayString: String {
        if useImperial {
            return "\(heightInFeet.feet)'\(heightInFeet.inches)\""
        } else {
            return "\(displayHeight)"
        }
    }

    var body: some View {
        OnboardingScreenContainer(
            title: "Your height",
            subtitle: "Used for body composition analysis",
            showBackButton: true,
            onBack: onBack
        ) {
            VStack(spacing: 0) {
                Spacer()

                // Large height display
                VStack(spacing: 8) {
                    Text(displayString)
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [StraynColors.accentPrimary, StraynColors.accentPrimary.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: displayHeight)

                    if !useImperial {
                        Text("cm")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(StraynColors.textSecondary)
                    }
                }

                // Unit toggle
                HStack(spacing: 0) {
                    unitButton("cm", selected: !useImperial) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            useImperial = false
                        }
                    }

                    unitButton("ft/in", selected: useImperial) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            useImperial = true
                        }
                    }
                }
                .padding(.top, 24)

                Spacer().frame(height: 40)

                // Scroll wheel
                WHOOPScrollWheel(
                    value: $displayHeight,
                    range: 120...230,
                    suffix: "cm"
                )
                .frame(height: 160)
                .padding(.horizontal, 24)

                Spacer()

                // Continue button
                WHOOPContinueButton(
                    isEnabled: displayHeight >= 120 && displayHeight <= 230,
                    action: {
                        heightCm = displayHeight
                        onContinue()
                    }
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            displayHeight = heightCm
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
    HeightInputScreen(
        heightCm: .constant(170),
        onContinue: {},
        onBack: {}
    )
}
