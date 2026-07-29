//
//  AgeInputScreen.swift
//  strayn
//
//  Age input screen with WHOOP-style scroll wheel.
//

import SwiftUI

struct AgeInputScreen: View {
    @Binding var age: Int
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var displayAge: Int = 25

    var body: some View {
        OnboardingScreenContainer(
            title: "How old are you?",
            subtitle: "This helps personalize your recovery insights",
            showBackButton: true,
            onBack: onBack
        ) {
            VStack(spacing: 0) {
                Spacer()

                // Large age display
                Text("\(displayAge)")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [StraynColors.accentPrimary, StraynColors.accentPrimary.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: displayAge)

                Text("years old")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(StraynColors.textSecondary)
                    .padding(.top, 4)

                Spacer().frame(height: 48)

                // Scroll wheel
                WHOOPScrollWheel(
                    value: $displayAge,
                    range: 13...100,
                    suffix: "years"
                )
                .frame(height: 160)
                .padding(.horizontal, 24)

                Spacer()

                // Continue button
                WHOOPContinueButton(
                    isEnabled: displayAge >= 13,
                    action: {
                        age = displayAge
                        onContinue()
                    }
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            displayAge = age
        }
    }
}

// MARK: - Preview

#Preview {
    AgeInputScreen(
        age: .constant(25),
        onContinue: {},
        onBack: {}
    )
}
